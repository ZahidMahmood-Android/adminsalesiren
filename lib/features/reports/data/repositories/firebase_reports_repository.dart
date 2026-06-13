import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/offer_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/offer_report_model.dart';

class FirebaseReportsRepository implements ReportsRepository {
  FirebaseReportsRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseReportsRepository');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('offer_reports');

  @override
  Stream<List<OfferReport>> watchReports() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(OfferReportModel.fromSnapshot).toList(),
        );
  }

  @override
  Future<void> updateReportStatus(String id, String status) {
    _log.info('Updating report status id=$id status=$status');
    return _reports.doc(id).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }
}
