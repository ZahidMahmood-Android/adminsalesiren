import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/bug_report.dart';
import '../../domain/repositories/bug_reports_repository.dart';
import '../models/bug_report_model.dart';

class FirebaseBugReportsRepository implements BugReportsRepository {
  FirebaseBugReportsRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseBugReportsRepository');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('bug_reports');

  @override
  Stream<List<BugReport>> watchBugReports() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(BugReportModel.fromSnapshot).toList(),
        );
  }

  @override
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
  }) {
    _log.info('Submitting bug report userId=$userId source=$source');
    return _reports.add({
      'userId': userId,
      'source': source,
      'category': category,
      'title': title,
      'details': details,
      'status': 'new',
      'userEmail': userEmail,
      'userName': userName,
      'appVersion': appVersion,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateStatus({
    required String id,
    required String status,
    String? resolvedBy,
  }) {
    _log.info('Updating bug report id=$id status=$status');
    final payload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'resolved') {
      payload['resolvedAt'] = FieldValue.serverTimestamp();
      if (resolvedBy != null) {
        payload['resolvedBy'] = resolvedBy;
      }
    }
    return _reports.doc(id).update(payload);
  }
}
