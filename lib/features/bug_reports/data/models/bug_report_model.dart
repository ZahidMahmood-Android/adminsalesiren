import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/bug_report.dart';

class BugReportModel {
  static BugReport fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return BugReport(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      source: data['source'] as String? ?? 'mobile',
      category: data['category'] as String? ?? 'other',
      title: data['title'] as String? ?? '',
      details: data['details'] as String? ?? '',
      status: data['status'] as String? ?? 'new',
      userEmail: data['userEmail'] as String?,
      userName: data['userName'] as String?,
      appVersion: data['appVersion'] as String?,
      platform: data['platform'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
    );
  }
}
