class SubscriptionRequest {
  const SubscriptionRequest({
    required this.id,
    required this.brandId,
    required this.currentPlanId,
    required this.requestedPlanId,
    required this.type,
    required this.message,
    required this.status,
    required this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String brandId;
  final String currentPlanId;
  final String requestedPlanId;
  final String type;
  final String message;
  final String status;
  final String adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
