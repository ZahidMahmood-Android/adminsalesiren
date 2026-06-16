class BrandUsage {
  const BrandUsage({
    required this.id,
    required this.brandId,
    required this.year,
    required this.month,
    required this.offersCreated,
    required this.activeOffers,
    required this.pushNotificationsRequested,
    required this.pushNotificationsSent,
    required this.featuredOffersUsed,
    required this.viewCount,
    required this.saveCount,
    required this.shareCount,
    required this.clickCount,
    required this.reportCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String brandId;
  final int year;
  final int month;
  final int offersCreated;
  final int activeOffers;
  final int pushNotificationsRequested;
  final int pushNotificationsSent;
  final int featuredOffersUsed;
  final int viewCount;
  final int saveCount;
  final int shareCount;
  final int clickCount;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
