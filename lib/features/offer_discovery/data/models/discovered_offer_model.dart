import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/discovered_offer.dart';
import '../../domain/entities/discovered_offer_status.dart';

class DiscoveredOfferModel extends DiscoveredOffer {
  const DiscoveredOfferModel({
    required super.id,
    required super.brandId,
    required super.brandName,
    required super.sourceType,
    required super.sourceUrl,
    required super.rawText,
    required super.suggestedTitle,
    required super.suggestedDescription,
    required super.suggestedDiscountText,
    super.suggestedDiscountType = '',
    super.suggestedDiscountValue,
    required super.suggestedCategoryCodes,
    required super.suggestedCityCodes,
    required super.imageUrl,
    required super.confidenceScore,
    required super.status,
    required super.convertedOfferId,
    required super.rejectionReason,
    required super.duplicateOfOfferId,
    required super.createdAt,
    required super.updatedAt,
    required super.checkedAt,
  });

  factory DiscoveredOfferModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return DiscoveredOfferModel(
      id: doc.id,
      brandId: data['brandId'] as String? ?? '',
      brandName: data['brandName'] as String? ?? '',
      sourceType: data['sourceType'] as String? ?? '',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      rawText: data['rawText'] as String? ?? '',
      suggestedTitle: data['suggestedTitle'] as String? ?? '',
      suggestedDescription: data['suggestedDescription'] as String? ?? '',
      suggestedDiscountText: data['suggestedDiscountText'] as String? ?? '',
      suggestedDiscountType: data['suggestedDiscountType'] as String? ?? '',
      suggestedDiscountValue: _readOptionalInt(data['suggestedDiscountValue']),
      suggestedCategoryCodes: _readStringList(data['suggestedCategoryCodes']),
      suggestedCityCodes: _readStringList(data['suggestedCityCodes']),
      imageUrl: data['imageUrl'] as String? ?? '',
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0,
      status:
          data['status'] as String? ?? DiscoveredOfferStatuses.pendingReview,
      convertedOfferId: data['convertedOfferId'] as String? ?? '',
      rejectionReason: data['rejectionReason'] as String? ?? '',
      duplicateOfOfferId: data['duplicateOfOfferId'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      checkedAt: _readOptionalDate(data['checkedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = true}) {
    return {
      'brandId': brandId,
      'brandName': brandName,
      'sourceType': sourceType,
      'sourceUrl': sourceUrl,
      'rawText': rawText,
      'suggestedTitle': suggestedTitle,
      'suggestedDescription': suggestedDescription,
      'suggestedDiscountText': suggestedDiscountText,
      if (suggestedDiscountType.isNotEmpty)
        'suggestedDiscountType': suggestedDiscountType,
      if (suggestedDiscountValue != null)
        'suggestedDiscountValue': suggestedDiscountValue,
      'suggestedCategoryCodes': suggestedCategoryCodes,
      'suggestedCityCodes': suggestedCityCodes,
      'imageUrl': imageUrl,
      'confidenceScore': confidenceScore,
      'status': status,
      'convertedOfferId': convertedOfferId,
      'rejectionReason': rejectionReason,
      'duplicateOfOfferId': duplicateOfOfferId,
      if (includeCreatedAt) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (checkedAt != null) 'checkedAt': Timestamp.fromDate(checkedAt!),
    };
  }

  static List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  static int? _readOptionalInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
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

  static DateTime? _readOptionalDate(Object? value) {
    if (value == null) {
      return null;
    }
    return _readDate(value);
  }
}
