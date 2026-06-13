class OfferReport {
  const OfferReport({
    required this.id,
    required this.offerId,
    required this.userId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String offerId;
  final String userId;
  final String reason;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
