import '../entities/bug_report.dart';

abstract class BugReportsRepository {
  Stream<List<BugReport>> watchBugReports();

  Future<void> submitBugReport({
    required String userId,
    required String source,
    required String category,
    required String title,
    required String details,
    String? userEmail,
    String? userName,
    String? appVersion,
    String? platform,
  });

  Future<void> updateStatus({
    required String id,
    required String status,
    String? resolvedBy,
  });
}
