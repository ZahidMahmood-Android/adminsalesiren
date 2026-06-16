class PricingPlan {
  const PricingPlan({
    required this.id,
    this.slug = '',
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.currency,
    required this.billingCycle,
    required this.trialDays,
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
    required this.isActive,
    required this.isPublic,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Human-readable slug (e.g. 'free_trial', 'starter').
  /// Stored in Firestore as a separate field so the document ID can be
  /// the Firestore auto-generated ID while business logic still identifies
  /// plans by slug.
  final String slug;

  final String name;
  final String description;
  final num monthlyPrice;
  final String currency;
  final String billingCycle;
  final int trialDays;
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
  final bool isActive;
  final bool isPublic;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  PricingPlan copyWith({
    String? id,
    String? slug,
    String? name,
    String? description,
    num? monthlyPrice,
    String? currency,
    String? billingCycle,
    int? trialDays,
    int? offerLimitPerMonth,
    int? activeOfferLimit,
    int? pushNotificationLimitPerMonth,
    int? featuredOfferLimitPerMonth,
    int? cityLimit,
    int? userLimit,
    String? analyticsLevel,
    bool? requiresOfferApproval,
    bool? canRequestPushNotifications,
    bool? canUseFeaturedOffers,
    bool? canExportAnalytics,
    bool? isActive,
    bool? isPublic,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PricingPlan(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      trialDays: trialDays ?? this.trialDays,
      offerLimitPerMonth: offerLimitPerMonth ?? this.offerLimitPerMonth,
      activeOfferLimit: activeOfferLimit ?? this.activeOfferLimit,
      pushNotificationLimitPerMonth:
          pushNotificationLimitPerMonth ?? this.pushNotificationLimitPerMonth,
      featuredOfferLimitPerMonth:
          featuredOfferLimitPerMonth ?? this.featuredOfferLimitPerMonth,
      cityLimit: cityLimit ?? this.cityLimit,
      userLimit: userLimit ?? this.userLimit,
      analyticsLevel: analyticsLevel ?? this.analyticsLevel,
      requiresOfferApproval:
          requiresOfferApproval ?? this.requiresOfferApproval,
      canRequestPushNotifications:
          canRequestPushNotifications ?? this.canRequestPushNotifications,
      canUseFeaturedOffers: canUseFeaturedOffers ?? this.canUseFeaturedOffers,
      canExportAnalytics: canExportAnalytics ?? this.canExportAnalytics,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
