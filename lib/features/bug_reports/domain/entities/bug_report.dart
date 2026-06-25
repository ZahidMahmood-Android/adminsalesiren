class BugReport {
  const BugReport({
    required this.id,
    required this.userId,
    required this.source,
    required this.category,
    required this.title,
    required this.details,
    required this.status,
    required this.createdAt,
    this.userEmail,
    this.userName,
    this.appVersion,
    this.platform,
    this.resolvedAt,
    this.resolvedBy,
  });

  final String id;
  final String userId;
  final String source;
  final String category;
  final String title;
  final String details;
  final String status;
  final String? userEmail;
  final String? userName;
  final String? appVersion;
  final String? platform;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
}
