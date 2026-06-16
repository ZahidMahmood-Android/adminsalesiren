import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/brand_payment.dart';
import '../../domain/entities/brand_subscription.dart';
import '../../domain/entities/brand_usage.dart';
import '../../domain/entities/pricing_plan.dart';
import '../../domain/entities/subscription_request.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../pricing_plan_seed_data.dart';

class FirebaseSubscriptionsRepository implements SubscriptionsRepository {
  FirebaseSubscriptionsRepository(
    this._firestore,
    this._userId,
    this._userRole,
    this._brandId,
  );

  final FirebaseFirestore _firestore;
  final String _userId;
  final String _userRole;
  final String _brandId;
  final _log = AppLogger.get('FirebaseSubscriptionsRepository');

  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection('pricing_plans');
  CollectionReference<Map<String, dynamic>> get _subscriptions =>
      _firestore.collection('brand_subscriptions');
  CollectionReference<Map<String, dynamic>> get _usage =>
      _firestore.collection('brand_usage');
  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection('brand_payments');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('subscription_requests');

  bool get _isBrandAdmin => _userRole == 'brand_admin';

  @override
  Stream<List<PricingPlan>> watchPricingPlans({bool publicOnly = false}) {
    return _plans.snapshots().map((snapshot) {
      final plans = snapshot.docs.map(_planFromDoc).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (publicOnly) {
        return plans.where((plan) => plan.isPublic && plan.isActive).toList();
      }
      return plans;
    });
  }

  @override
  Future<PricingPlan?> getPricingPlan(String id) async {
    final doc = await _plans.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _planFromDoc(doc);
  }

  @override
  Future<void> savePricingPlan(PricingPlan plan) async {
    final doc = plan.id.isEmpty ? _plans.doc() : _plans.doc(plan.id);
    _log.info('Saving pricing plan id=${doc.id}');
    await doc.set(_planToMap(plan, doc.id), SetOptions(merge: true));
  }

  @override
  Future<void> deletePricingPlan(String id) async {
    _log.warning('Deleting pricing plan id=$id');
    await _plans.doc(id).delete();
  }

  @override
  Future<int> seedPricingPlans() async {
    var count = 0;

    // Build a slug→docId map from existing documents so we never duplicate.
    final existing = await _plans.get();
    final slugToDocId = <String, String>{
      for (final doc in existing.docs)
        if ((doc.data()['slug'] as String?)?.isNotEmpty == true)
          doc.data()['slug'] as String: doc.id,
    };

    for (final row in PricingPlanSeedData.plans) {
      final slug = row['slug'] as String;
      final existingDocId = slugToDocId[slug];

      // Use the existing document if already seeded, otherwise auto-generate.
      final doc = existingDocId != null
          ? _plans.doc(existingDocId)
          : _plans.doc();

      final exists = existingDocId != null;
      final payload = Map<String, Object?>.from(row)
        ..['updatedAt'] = FieldValue.serverTimestamp();
      if (!exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }
      // Do NOT store a redundant 'id' field — the Firestore doc ID is
      // the canonical identifier. The 'slug' field is the human-readable key.
      payload.remove('id');

      await doc.set(payload, SetOptions(merge: true));
      count++;
    }
    _log.info('Seeded pricing plans count=$count');
    return count;
  }

  @override
  Stream<List<BrandSubscription>> watchBrandSubscriptions({String? brandId}) {
    Query<Map<String, dynamic>> query = _subscriptions;
    if (_isBrandAdmin) {
      query = query.where('brandId', isEqualTo: _brandId);
    } else if (brandId != null && brandId.isNotEmpty) {
      query = query.where('brandId', isEqualTo: brandId);
    }
    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(_subscriptionFromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  @override
  Future<BrandSubscription?> getBrandSubscription(String id) async {
    final doc = await _subscriptions.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _subscriptionFromDoc(doc);
  }

  @override
  Future<BrandSubscription?> getActiveSubscriptionForBrand(
    String brandId,
  ) async {
    final snapshot = await _subscriptions
        .where('brandId', isEqualTo: brandId)
        .get();
    for (final doc in snapshot.docs) {
      final sub = _subscriptionFromDoc(doc);
      if (sub.isUsable) {
        return sub;
      }
    }
    return null;
  }

  @override
  Future<String> saveBrandSubscription(BrandSubscription subscription) async {
    final doc = subscription.id.isEmpty
        ? _subscriptions.doc()
        : _subscriptions.doc(subscription.id);
    _log.info(
      'Saving brand subscription id=${doc.id} brand=${subscription.brandId}',
    );
    await doc.set(
      _subscriptionToMap(subscription, doc.id),
      SetOptions(merge: true),
    );
    return doc.id;
  }

  @override
  BrandSubscription subscriptionFromPlan({
    required PricingPlan plan,
    required String brandId,
    required String adminId,
    String status = 'active',
    String paymentStatus = 'paid',
    String paymentMethod = 'manual',
    DateTime? startDate,
    DateTime? endDate,
    bool autoRenew = false,
    num discountPercent = 0,
    String discountNotes = '',
  }) {
    final now = DateTime.now();
    final start = startDate ?? now;
    final resolvedStatus =
        (plan.slug == 'free_trial' || plan.id == 'free_trial')
        ? 'trial'
        : status;
    final resolvedEnd =
        endDate ??
        (plan.trialDays > 0 ? start.add(Duration(days: plan.trialDays)) : null);
    final clampedDiscount = discountPercent.clamp(0, 100);
    final discountedPrice = clampedDiscount > 0
        ? (plan.monthlyPrice * (1 - clampedDiscount / 100))
        : null;
    return BrandSubscription(
      id: '',
      brandId: brandId,
      planId: plan.id,
      planName: plan.name,
      status: resolvedStatus,
      currency: plan.currency,
      monthlyPrice: plan.monthlyPrice,
      discountPercent: clampedDiscount,
      discountedPrice: discountedPrice,
      discountNotes: discountNotes,
      billingCycle: plan.billingCycle,
      startDate: start,
      endDate: resolvedEnd,
      autoRenew: autoRenew,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      offerLimitPerMonth: plan.offerLimitPerMonth,
      activeOfferLimit: plan.activeOfferLimit,
      pushNotificationLimitPerMonth: plan.pushNotificationLimitPerMonth,
      featuredOfferLimitPerMonth: plan.featuredOfferLimitPerMonth,
      cityLimit: plan.cityLimit,
      userLimit: plan.userLimit,
      analyticsLevel: plan.analyticsLevel,
      requiresOfferApproval: plan.requiresOfferApproval,
      canRequestPushNotifications: plan.canRequestPushNotifications,
      canUseFeaturedOffers: plan.canUseFeaturedOffers,
      canExportAnalytics: plan.canExportAnalytics,
      trialDays: plan.trialDays,
      createdByAdminId: adminId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Stream<List<BrandUsage>> watchBrandUsage({String? brandId}) {
    Query<Map<String, dynamic>> query = _usage;
    if (_isBrandAdmin) {
      query = query.where('brandId', isEqualTo: _brandId);
    } else if (brandId != null && brandId.isNotEmpty) {
      query = query.where('brandId', isEqualTo: brandId);
    }
    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(_usageFromDoc).toList()
        ..sort((a, b) {
          final yearCompare = b.year.compareTo(a.year);
          if (yearCompare != 0) {
            return yearCompare;
          }
          return b.month.compareTo(a.month);
        });
      return items;
    });
  }

  @override
  Future<BrandUsage> getOrCreateCurrentUsage(String brandId) async {
    final now = DateTime.now();
    final docId = '${brandId}_${now.year}_${now.month}';
    final doc = _usage.doc(docId);
    final snapshot = await doc.get();
    if (snapshot.exists) {
      return _usageFromDoc(snapshot);
    }
    final usage = BrandUsage(
      id: docId,
      brandId: brandId,
      year: now.year,
      month: now.month,
      offersCreated: 0,
      activeOffers: 0,
      pushNotificationsRequested: 0,
      pushNotificationsSent: 0,
      featuredOffersUsed: 0,
      viewCount: 0,
      saveCount: 0,
      shareCount: 0,
      clickCount: 0,
      reportCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(_usageToMap(usage));
    return usage;
  }

  @override
  Future<void> incrementUsage(
    String brandId, {
    int offersCreated = 0,
    int pushNotificationsRequested = 0,
    int featuredOffersUsed = 0,
  }) async {
    final usage = await getOrCreateCurrentUsage(brandId);
    await _usage.doc(usage.id).update({
      'offersCreated': (usage.offersCreated + offersCreated).clamp(0, 999999),
      'pushNotificationsRequested':
          (usage.pushNotificationsRequested + pushNotificationsRequested).clamp(
            0,
            999999,
          ),
      'featuredOffersUsed': (usage.featuredOffersUsed + featuredOffersUsed)
          .clamp(0, 999999),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<BrandPayment>> watchBrandPayments({String? brandId}) {
    Query<Map<String, dynamic>> query = _payments;
    if (_isBrandAdmin) {
      query = query.where('brandId', isEqualTo: _brandId);
    } else if (brandId != null && brandId.isNotEmpty) {
      query = query.where('brandId', isEqualTo: brandId);
    }
    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(_paymentFromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  @override
  Future<BrandPayment?> getBrandPayment(String id) async {
    final doc = await _payments.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _paymentFromDoc(doc);
  }

  @override
  Future<String> saveBrandPayment(BrandPayment payment) async {
    final doc = payment.id.isEmpty
        ? _payments.doc()
        : _payments.doc(payment.id);
    _log.info('Saving brand payment id=${doc.id} brand=${payment.brandId}');
    await doc.set(_paymentToMap(payment, doc.id), SetOptions(merge: true));
    return doc.id;
  }

  @override
  Future<void> verifyBrandPayment(
    String id,
    String adminId, {
    String notes = '',
  }) async {
    _log.info('Verifying brand payment id=$id');
    await _payments.doc(id).update({
      'paymentStatus': 'verified',
      'verifiedByAdminId': adminId,
      'verifiedAt': FieldValue.serverTimestamp(),
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> cancelBrandPayment(String id) async {
    _log.info('Cancelling brand payment id=$id');
    await _payments.doc(id).update({
      'paymentStatus': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<SubscriptionRequest>> watchSubscriptionRequests({
    String? brandId,
  }) {
    Query<Map<String, dynamic>> query = _requests;
    if (_isBrandAdmin) {
      query = query.where('brandId', isEqualTo: _brandId);
    } else if (brandId != null && brandId.isNotEmpty) {
      query = query.where('brandId', isEqualTo: brandId);
    }
    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(_requestFromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  @override
  Future<String> saveSubscriptionRequest(SubscriptionRequest request) async {
    final doc = request.id.isEmpty
        ? _requests.doc()
        : _requests.doc(request.id);
    _log.info(
      'Saving subscription request id=${doc.id} brand=${request.brandId}',
    );
    await doc.set(_requestToMap(request, doc.id), SetOptions(merge: true));
    return doc.id;
  }

  @override
  Future<void> updateSubscriptionRequest(
    String id, {
    required String status,
    String adminNotes = '',
  }) async {
    await _requests.doc(id).update({
      'status': status,
      'adminNotes': adminNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<int> countActiveOffersForBrand(String brandId) async {
    final snapshot = await _firestore
        .collection('offers')
        .where('brandId', isEqualTo: brandId)
        .get();
    final now = DateTime.now();
    var count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['isPublished'] != true) {
        continue;
      }
      final endDate = _readOptionalDate(data['endDate']);
      if (endDate != null && endDate.isAfter(now)) {
        count++;
      }
    }
    return count;
  }

  PricingPlan _planFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PricingPlan(
      id: doc.id,
      // 'slug' is the human-readable key (e.g. 'free_trial').
      // Fall back to the legacy 'id' field for documents seeded before this change.
      slug: data['slug'] as String? ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      monthlyPrice: data['monthlyPrice'] as num? ?? 0,
      currency: data['currency'] as String? ?? 'PKR',
      billingCycle: data['billingCycle'] as String? ?? 'monthly',
      trialDays: data['trialDays'] as int? ?? 0,
      offerLimitPerMonth: data['offerLimitPerMonth'] as int? ?? 0,
      activeOfferLimit: data['activeOfferLimit'] as int? ?? 0,
      pushNotificationLimitPerMonth:
          data['pushNotificationLimitPerMonth'] as int? ?? 0,
      featuredOfferLimitPerMonth:
          data['featuredOfferLimitPerMonth'] as int? ?? 0,
      cityLimit: data['cityLimit'] as int? ?? 1,
      userLimit: data['userLimit'] as int? ?? 1,
      analyticsLevel: data['analyticsLevel'] as String? ?? 'basic',
      requiresOfferApproval: data['requiresOfferApproval'] as bool? ?? true,
      canRequestPushNotifications:
          data['canRequestPushNotifications'] as bool? ?? false,
      canUseFeaturedOffers: data['canUseFeaturedOffers'] as bool? ?? false,
      canExportAnalytics: data['canExportAnalytics'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      isPublic: data['isPublic'] as bool? ?? true,
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> _planToMap(PricingPlan plan, String docId) {
    return {
      if (plan.slug.isNotEmpty) 'slug': plan.slug,
      'name': plan.name,
      'description': plan.description,
      'monthlyPrice': plan.monthlyPrice,
      'currency': plan.currency,
      'billingCycle': plan.billingCycle,
      'trialDays': plan.trialDays,
      'offerLimitPerMonth': plan.offerLimitPerMonth,
      'activeOfferLimit': plan.activeOfferLimit,
      'pushNotificationLimitPerMonth': plan.pushNotificationLimitPerMonth,
      'featuredOfferLimitPerMonth': plan.featuredOfferLimitPerMonth,
      'cityLimit': plan.cityLimit,
      'userLimit': plan.userLimit,
      'analyticsLevel': plan.analyticsLevel,
      'requiresOfferApproval': plan.requiresOfferApproval,
      'canRequestPushNotifications': plan.canRequestPushNotifications,
      'canUseFeaturedOffers': plan.canUseFeaturedOffers,
      'canExportAnalytics': plan.canExportAnalytics,
      'isActive': plan.isActive,
      'isPublic': plan.isPublic,
      'sortOrder': plan.sortOrder,
      'createdAt': Timestamp.fromDate(plan.createdAt),
      'updatedAt': Timestamp.fromDate(plan.updatedAt),
    };
  }

  BrandSubscription _subscriptionFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return BrandSubscription(
      id: data['id'] as String? ?? doc.id,
      brandId: data['brandId'] as String? ?? '',
      planId: data['planId'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      currency: data['currency'] as String? ?? 'PKR',
      monthlyPrice: data['monthlyPrice'] as num? ?? 0,
      discountPercent: data['discountPercent'] as num? ?? 0,
      discountedPrice: data['discountedPrice'] as num?,
      discountNotes: data['discountNotes'] as String? ?? '',
      billingCycle: data['billingCycle'] as String? ?? 'monthly',
      startDate: _readDate(data['startDate']),
      endDate: _readOptionalDate(data['endDate']),
      autoRenew: data['autoRenew'] as bool? ?? false,
      paymentStatus: data['paymentStatus'] as String? ?? 'pending',
      paymentMethod: data['paymentMethod'] as String? ?? 'manual',
      offerLimitPerMonth: data['offerLimitPerMonth'] as int? ?? 0,
      activeOfferLimit: data['activeOfferLimit'] as int? ?? 0,
      pushNotificationLimitPerMonth:
          data['pushNotificationLimitPerMonth'] as int? ?? 0,
      featuredOfferLimitPerMonth:
          data['featuredOfferLimitPerMonth'] as int? ?? 0,
      cityLimit: data['cityLimit'] as int? ?? 1,
      userLimit: data['userLimit'] as int? ?? 1,
      analyticsLevel: data['analyticsLevel'] as String? ?? 'basic',
      requiresOfferApproval: data['requiresOfferApproval'] as bool? ?? true,
      canRequestPushNotifications:
          data['canRequestPushNotifications'] as bool? ?? false,
      canUseFeaturedOffers: data['canUseFeaturedOffers'] as bool? ?? false,
      canExportAnalytics: data['canExportAnalytics'] as bool? ?? false,
      trialDays: data['trialDays'] as int? ?? 0,
      createdByAdminId: data['createdByAdminId'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> _subscriptionToMap(
    BrandSubscription subscription,
    String docId,
  ) {
    return {
      'id': docId,
      'brandId': subscription.brandId,
      'planId': subscription.planId,
      'planName': subscription.planName,
      'status': subscription.status,
      'currency': subscription.currency,
      'monthlyPrice': subscription.monthlyPrice,
      'discountPercent': subscription.discountPercent,
      'discountedPrice': subscription.discountedPrice,
      'discountNotes': subscription.discountNotes,
      'billingCycle': subscription.billingCycle,
      'startDate': Timestamp.fromDate(subscription.startDate),
      'endDate': subscription.endDate == null
          ? null
          : Timestamp.fromDate(subscription.endDate!),
      'autoRenew': subscription.autoRenew,
      'paymentStatus': subscription.paymentStatus,
      'paymentMethod': subscription.paymentMethod,
      'offerLimitPerMonth': subscription.offerLimitPerMonth,
      'activeOfferLimit': subscription.activeOfferLimit,
      'pushNotificationLimitPerMonth':
          subscription.pushNotificationLimitPerMonth,
      'featuredOfferLimitPerMonth': subscription.featuredOfferLimitPerMonth,
      'cityLimit': subscription.cityLimit,
      'userLimit': subscription.userLimit,
      'analyticsLevel': subscription.analyticsLevel,
      'requiresOfferApproval': subscription.requiresOfferApproval,
      'canRequestPushNotifications': subscription.canRequestPushNotifications,
      'canUseFeaturedOffers': subscription.canUseFeaturedOffers,
      'canExportAnalytics': subscription.canExportAnalytics,
      'trialDays': subscription.trialDays,
      'createdByAdminId': subscription.createdByAdminId,
      'createdAt': Timestamp.fromDate(subscription.createdAt),
      'updatedAt': Timestamp.fromDate(subscription.updatedAt),
    };
  }

  BrandUsage _usageFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BrandUsage(
      id: data['id'] as String? ?? doc.id,
      brandId: data['brandId'] as String? ?? '',
      year: data['year'] as int? ?? 0,
      month: data['month'] as int? ?? 0,
      offersCreated: data['offersCreated'] as int? ?? 0,
      activeOffers: data['activeOffers'] as int? ?? 0,
      pushNotificationsRequested:
          data['pushNotificationsRequested'] as int? ?? 0,
      pushNotificationsSent: data['pushNotificationsSent'] as int? ?? 0,
      featuredOffersUsed: data['featuredOffersUsed'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      saveCount: data['saveCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      clickCount: data['clickCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> _usageToMap(BrandUsage usage) {
    return {
      'id': usage.id,
      'brandId': usage.brandId,
      'year': usage.year,
      'month': usage.month,
      'offersCreated': usage.offersCreated,
      'activeOffers': usage.activeOffers,
      'pushNotificationsRequested': usage.pushNotificationsRequested,
      'pushNotificationsSent': usage.pushNotificationsSent,
      'featuredOffersUsed': usage.featuredOffersUsed,
      'viewCount': usage.viewCount,
      'saveCount': usage.saveCount,
      'shareCount': usage.shareCount,
      'clickCount': usage.clickCount,
      'reportCount': usage.reportCount,
      'createdAt': Timestamp.fromDate(usage.createdAt),
      'updatedAt': Timestamp.fromDate(usage.updatedAt),
    };
  }

  BrandPayment _paymentFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BrandPayment(
      id: data['id'] as String? ?? doc.id,
      brandId: data['brandId'] as String? ?? '',
      subscriptionId: data['subscriptionId'] as String? ?? '',
      amount: data['amount'] as num? ?? 0,
      currency: data['currency'] as String? ?? 'PKR',
      paymentMethod: data['paymentMethod'] as String? ?? 'manual',
      paymentStatus: data['paymentStatus'] as String? ?? 'pending',
      transactionReference: data['transactionReference'] as String? ?? '',
      proofImageUrl: data['proofImageUrl'] as String? ?? '',
      paidAt: _readOptionalDate(data['paidAt']),
      verifiedByAdminId: data['verifiedByAdminId'] as String? ?? '',
      verifiedAt: _readOptionalDate(data['verifiedAt']),
      notes: data['notes'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> _paymentToMap(BrandPayment payment, String docId) {
    return {
      'id': docId,
      'brandId': payment.brandId,
      'subscriptionId': payment.subscriptionId,
      'amount': payment.amount,
      'currency': payment.currency,
      'paymentMethod': payment.paymentMethod,
      'paymentStatus': payment.paymentStatus,
      'transactionReference': payment.transactionReference,
      'proofImageUrl': payment.proofImageUrl,
      'paidAt': payment.paidAt == null
          ? null
          : Timestamp.fromDate(payment.paidAt!),
      'verifiedByAdminId': payment.verifiedByAdminId,
      'verifiedAt': payment.verifiedAt == null
          ? null
          : Timestamp.fromDate(payment.verifiedAt!),
      'notes': payment.notes,
      'createdAt': Timestamp.fromDate(payment.createdAt),
      'updatedAt': Timestamp.fromDate(payment.updatedAt),
    };
  }

  SubscriptionRequest _requestFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return SubscriptionRequest(
      id: data['id'] as String? ?? doc.id,
      brandId: data['brandId'] as String? ?? '',
      currentPlanId: data['currentPlanId'] as String? ?? '',
      requestedPlanId: data['requestedPlanId'] as String? ?? '',
      type: data['type'] as String? ?? 'upgrade',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      adminNotes: data['adminNotes'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> _requestToMap(
    SubscriptionRequest request,
    String docId,
  ) {
    return {
      'id': docId,
      'brandId': request.brandId,
      'currentPlanId': request.currentPlanId,
      'requestedPlanId': request.requestedPlanId,
      'type': request.type,
      'message': request.message,
      'status': request.status,
      'adminNotes': request.adminNotes,
      'createdAt': Timestamp.fromDate(request.createdAt),
      'updatedAt': Timestamp.fromDate(request.updatedAt),
    };
  }

  DateTime _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _readOptionalDate(Object? value) {
    if (value == null) {
      return null;
    }
    return _readDate(value);
  }
}
