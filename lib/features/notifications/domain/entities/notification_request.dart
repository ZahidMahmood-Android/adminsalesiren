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
  });

  final String id;
  final String title;
  final String body;
  final String topic;
  final String type;
  final Map<String, String> data;
  final String status;
  final DateTime createdAt;
}
