class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.topic,
    required this.type,
    required this.data,
    required this.status,
    required this.createdAt,
    this.brandId = '',
    this.offerId = '',
    this.requestedByUserId = '',
    this.targetCityIds = const [],
    this.targetCategoryIds = const [],
    this.targetTopics = const [],
    this.adminNotes = '',
    this.approvedBy = '',
    this.approvedAt,
    this.sentAt,
    this.sentCount = 0,
    this.openCount = 0,
  });

  final String id;
  final String title;
  final String body;
  final String topic;
  final String type;
  final Map<String, String> data;
  final String status;
  final DateTime createdAt;
  final String brandId;
  final String offerId;
  final String requestedByUserId;
  final List<String> targetCityIds;
  final List<String> targetCategoryIds;
  final List<String> targetTopics;
  final String adminNotes;
  final String approvedBy;
  final DateTime? approvedAt;
  final DateTime? sentAt;
  final int sentCount;
  final int openCount;
}
