class BrandSubscription {
  const BrandSubscription({
    required this.id,
    required this.brandId,
    required this.planId,
    required this.planName,
    required this.status,
    required this.currency,
    required this.monthlyPrice,
    this.discountPercent = 0,
    this.discountedPrice,
    this.discountNotes = '',
    required this.billingCycle,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.offerLimitPerMonth,
    required this.activeOfferLimit,
    required this.pushNotificationLimitPerMonth,
    required this.featuredOfferLimitPerMonth,
    required this.cityLimit,
    required this.userLimit,
    required this.analyticsLevel,
    required this.requiresOfferApproval,
    required this.canRequestPushNotifications,
    required this.canUseFeaturedOffers,
    required this.canExportAnalytics,
    required this.trialDays,
    required this.createdByAdminId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String brandId;
  final String planId;
  final String planName;
  final String status;
  final String currency;

  /// Original plan price (before any discount).
  final num monthlyPrice;

  /// Discount applied as a percentage (0–100). 0 = no discount.
  final num discountPercent;

  /// Final price after discount. Null means no discount was applied.
  final num? discountedPrice;

  /// Optional admin note explaining the discount reason.
  final String discountNotes;
  final String billingCycle;
  final DateTime startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final String paymentStatus;
  final String paymentMethod;
  final int offerLimitPerMonth;
  final int activeOfferLimit;
  final int pushNotificationLimitPerMonth;
  final int featuredOfferLimitPerMonth;
  final int cityLimit;
  final int userLimit;
  final String analyticsLevel;
  final bool requiresOfferApproval;
  final bool canRequestPushNotifications;
  final bool canUseFeaturedOffers;
  final bool canExportAnalytics;
  final int trialDays;
  final String createdByAdminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The price the brand actually pays — discounted price if a discount was
  /// applied, otherwise the standard plan price.
  num get effectivePrice => discountedPrice ?? monthlyPrice;

  BrandSubscription copyWith({
    String? id,
    String? status,
    String? paymentStatus,
    num? discountPercent,
    num? discountedPrice,
    String? discountNotes,
  }) {
    return BrandSubscription(
      id: id ?? this.id,
      brandId: brandId,
      planId: planId,
      planName: planName,
      status: status ?? this.status,
      currency: currency,
      monthlyPrice: monthlyPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountNotes: discountNotes ?? this.discountNotes,
      billingCycle: billingCycle,
      startDate: startDate,
      endDate: endDate,
      autoRenew: autoRenew,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod,
      offerLimitPerMonth: offerLimitPerMonth,
      activeOfferLimit: activeOfferLimit,
      pushNotificationLimitPerMonth: pushNotificationLimitPerMonth,
      featuredOfferLimitPerMonth: featuredOfferLimitPerMonth,
      cityLimit: cityLimit,
      userLimit: userLimit,
      analyticsLevel: analyticsLevel,
      requiresOfferApproval: requiresOfferApproval,
      canRequestPushNotifications: canRequestPushNotifications,
      canUseFeaturedOffers: canUseFeaturedOffers,
      canExportAnalytics: canExportAnalytics,
      trialDays: trialDays,
      createdByAdminId: createdByAdminId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isExpired {
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }

  bool get isUsable {
    if (status != 'active' && status != 'trial') return false;
    return !isExpired;
  }

  bool get isTrialExpired => status == 'trial' && isExpired;
  bool get isPaidExpired => status == 'active' && isExpired;
}
