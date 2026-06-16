import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_subscriptions_repository.dart';
import '../../domain/entities/brand_payment.dart';
import '../../domain/entities/brand_subscription.dart';
import '../../domain/entities/brand_usage.dart';
import '../../domain/entities/pricing_plan.dart';
import '../../domain/entities/subscription_request.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../../domain/services/subscription_limit_checker.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  return FirebaseSubscriptionsRepository(
    ref.watch(firestoreProvider),
    user?.id ?? ref.watch(firebaseAuthProvider).currentUser?.uid ?? '',
    user?.role ?? 'super_admin',
    user?.brandId ?? '',
  );
});

final pricingPlansProvider = StreamProvider.autoDispose<List<PricingPlan>>((
  ref,
) async* {
  yield const <PricingPlan>[];
  yield* ref.watch(subscriptionsRepositoryProvider).watchPricingPlans();
});

final publicPricingPlansProvider =
    StreamProvider.autoDispose<List<PricingPlan>>((ref) async* {
      yield const <PricingPlan>[];
      yield* ref
          .watch(subscriptionsRepositoryProvider)
          .watchPricingPlans(publicOnly: true);
    });

final pricingPlanProvider = FutureProvider.autoDispose
    .family<PricingPlan?, String>(
      (ref, id) =>
          ref.watch(subscriptionsRepositoryProvider).getPricingPlan(id),
    );

final brandSubscriptionsProvider =
    StreamProvider.autoDispose<List<BrandSubscription>>((ref) async* {
      yield const <BrandSubscription>[];
      yield* ref
          .watch(subscriptionsRepositoryProvider)
          .watchBrandSubscriptions();
    });

final brandPaymentsProvider = StreamProvider.autoDispose<List<BrandPayment>>((
  ref,
) async* {
  yield const <BrandPayment>[];
  yield* ref.watch(subscriptionsRepositoryProvider).watchBrandPayments();
});

final subscriptionRequestsProvider =
    StreamProvider.autoDispose<List<SubscriptionRequest>>((ref) async* {
      yield const <SubscriptionRequest>[];
      yield* ref
          .watch(subscriptionsRepositoryProvider)
          .watchSubscriptionRequests();
    });

final brandUsageProvider = StreamProvider.autoDispose<List<BrandUsage>>((
  ref,
) async* {
  yield const <BrandUsage>[];
  yield* ref.watch(subscriptionsRepositoryProvider).watchBrandUsage();
});

final activeBrandSubscriptionProvider =
    FutureProvider.autoDispose<BrandSubscription?>((ref) async {
      // Wait for the profile future so brandId is available before querying.
      final user = await ref.watch(currentUserProfileProvider.future);
      if (user == null || user.brandId.isEmpty) {
        return null;
      }
      return ref
          .read(subscriptionsRepositoryProvider)
          .getActiveSubscriptionForBrand(user.brandId);
    });

final brandPaymentProvider = FutureProvider.autoDispose
    .family<BrandPayment?, String>(
      (ref, id) =>
          ref.watch(subscriptionsRepositoryProvider).getBrandPayment(id),
    );

final subscriptionActionsProvider =
    AsyncNotifierProvider.autoDispose<SubscriptionActionsController, void>(
      SubscriptionActionsController.new,
    );

class SubscriptionActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('SubscriptionActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> savePricingPlan(PricingPlan plan) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionsRepositoryProvider).savePricingPlan(plan),
    );
    _logResult('Save pricing plan');
  }

  Future<void> deletePricingPlan(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionsRepositoryProvider).deletePricingPlan(id),
    );
    _logResult('Delete pricing plan');
  }

  Future<int> seedPricingPlans() async {
    state = const AsyncLoading();
    int count = 0;
    state = await AsyncValue.guard(() async {
      count = await ref
          .read(subscriptionsRepositoryProvider)
          .seedPricingPlans();
    });
    _logResult('Seed pricing plans');
    return count;
  }

  Future<String?> assignSubscription({
    required String brandId,
    required String planId,
    String status = 'active',
    String paymentStatus = 'paid',
    bool autoRenew = false,
    num discountPercent = 0,
    String discountNotes = '',
  }) async {
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(subscriptionsRepositoryProvider);
      final plan = await repo.getPricingPlan(planId);
      if (plan == null) {
        throw StateError('Pricing plan not found.');
      }
      final user = ref.read(currentUserProvider);
      final subscription = repo.subscriptionFromPlan(
        plan: plan,
        brandId: brandId,
        adminId: user?.id ?? '',
        status: status,
        paymentStatus: paymentStatus,
        autoRenew: autoRenew,
        discountPercent: discountPercent,
        discountNotes: discountNotes,
      );
      id = await repo.saveBrandSubscription(subscription);
    });
    _logResult('Assign subscription');
    return id;
  }

  Future<void> verifyPayment(String id, {String notes = ''}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      await ref
          .read(subscriptionsRepositoryProvider)
          .verifyBrandPayment(id, user?.id ?? '', notes: notes);
    });
    _logResult('Verify payment');
  }

  Future<void> savePayment(BrandPayment payment) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subscriptionsRepositoryProvider).saveBrandPayment(payment),
    );
    _logResult('Save payment');
  }

  Future<void> createSubscriptionRequest(SubscriptionRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(subscriptionsRepositoryProvider)
          .saveSubscriptionRequest(request),
    );
    _logResult('Create subscription request');
  }

  Future<void> updateSubscriptionRequest(
    String id, {
    required String status,
    String adminNotes = '',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(subscriptionsRepositoryProvider)
          .updateSubscriptionRequest(
            id,
            status: status,
            adminNotes: adminNotes,
          ),
    );
    _logResult('Update subscription request');
  }

  /// Approves a subscription request AND immediately assigns the new plan to the
  /// brand. This ensures the brand admin sees their updated subscription in real
  /// time (via the StreamProvider for brand_subscriptions).
  Future<void> approveSubscriptionRequest(SubscriptionRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(subscriptionsRepositoryProvider);
      // 1. Mark request as approved.
      await repo.updateSubscriptionRequest(request.id, status: 'approved');
      // 2. Resolve the requested plan.
      final plan = await repo.getPricingPlan(request.requestedPlanId);
      if (plan == null) return;
      final user = ref.read(currentUserProvider);
      // 3. Build the new subscription; reuse existing doc ID to update in place.
      final existing = await repo.getActiveSubscriptionForBrand(
        request.brandId,
      );
      final newSub = repo.subscriptionFromPlan(
        plan: plan,
        brandId: request.brandId,
        adminId: user?.id ?? '',
        status: 'active',
        paymentStatus: 'pending',
        autoRenew: false,
      );
      final subToSave = existing != null
          ? newSub.copyWith(id: existing.id)
          : newSub;
      await repo.saveBrandSubscription(subToSave);
    });
    _logResult('Approve subscription request');
  }

  Future<void> cancelPayment(String paymentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(subscriptionsRepositoryProvider)
          .cancelBrandPayment(paymentId),
    );
    _logResult('Cancel payment');
  }

  Future<String?> checkOfferCreationLimits(String brandId) async {
    final repo = ref.read(subscriptionsRepositoryProvider);
    final subscription = await repo.getActiveSubscriptionForBrand(brandId);
    final usage = await repo.getOrCreateCurrentUsage(brandId);
    final activeCount = await repo.countActiveOffersForBrand(brandId);
    return SubscriptionLimitChecker.offerCreationBlockReason(
      subscription: subscription,
      usage: usage,
      activeOfferCount: activeCount,
    );
  }

  Future<String?> checkPushNotificationLimits(String brandId) async {
    final repo = ref.read(subscriptionsRepositoryProvider);
    final subscription = await repo.getActiveSubscriptionForBrand(brandId);
    final usage = await repo.getOrCreateCurrentUsage(brandId);
    return SubscriptionLimitChecker.pushNotificationBlockReason(
      subscription: subscription,
      usage: usage,
    );
  }

  Future<String?> checkFeaturedOfferLimits(String brandId) async {
    final repo = ref.read(subscriptionsRepositoryProvider);
    final subscription = await repo.getActiveSubscriptionForBrand(brandId);
    final usage = await repo.getOrCreateCurrentUsage(brandId);
    return SubscriptionLimitChecker.featuredOfferBlockReason(
      subscription: subscription,
      usage: usage,
    );
  }

  Future<void> recordOfferCreated(String brandId) async {
    await ref
        .read(subscriptionsRepositoryProvider)
        .incrementUsage(brandId, offersCreated: 1);
  }

  Future<void> recordPushRequested(String brandId) async {
    await ref
        .read(subscriptionsRepositoryProvider)
        .incrementUsage(brandId, pushNotificationsRequested: 1);
  }

  Future<void> recordFeaturedUsed(String brandId) async {
    await ref
        .read(subscriptionsRepositoryProvider)
        .incrementUsage(brandId, featuredOffersUsed: 1);
  }

  void _logResult(String label) {
    if (state.hasError) {
      _log.severe('$label failed', state.error, state.stackTrace);
    } else {
      _log.info('$label completed');
    }
  }
}
