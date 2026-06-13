import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/offer_report.dart';

class OfferReportModel extends OfferReport {
  const OfferReportModel({
    required super.id,
    required super.offerId,
    required super.userId,
    required super.reason,
    required super.description,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OfferReportModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return OfferReportModel(
      id: data['id'] as String? ?? doc.id,
      offerId: data['offerId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
