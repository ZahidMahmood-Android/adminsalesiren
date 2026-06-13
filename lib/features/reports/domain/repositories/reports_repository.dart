import '../entities/offer_report.dart';

abstract class ReportsRepository {
  Stream<List<OfferReport>> watchReports();
  Future<void> updateReportStatus(String id, String status);
}
