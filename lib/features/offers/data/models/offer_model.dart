import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/offer.dart';

class OfferModel extends Offer {
  const OfferModel({
    required super.id,
    required super.title,
    required super.description,
    required super.brandId,
    required super.brandName,
    required super.categoryId,
    required super.categoryName,
    required super.cityId,
    required super.cityName,
    required super.discountText,
    required super.discountType,
    required super.discountValue,
    required super.imageUrl,
    required super.sourceUrl,
    required super.onlineUrl,
    required super.startDate,
    required super.endDate,
    required super.isVerified,
    required super.isPublished,
    required super.isFeatured,
    required super.aiConfidence,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.createdByUserId,
    super.createdByRole,
    super.status,
    super.approvalStatus,
    super.approvalNotes,
    super.approvedBy,
    super.approvedAt,
    super.categoryIds,
    super.categoryNames,
    super.cityIds,
    super.cityNames,
    super.viewCount,
    super.saveCount,
    super.shareCount,
    super.clickCount,
    super.reportCount,
  });

  factory OfferModel.fromEntity(Offer offer) {
    return OfferModel(
      id: offer.id,
      title: offer.title,
      description: offer.description,
      brandId: offer.brandId,
      brandName: offer.brandName,
      categoryId: offer.categoryId,
      categoryName: offer.categoryName,
      cityId: offer.cityId,
      cityName: offer.cityName,
      discountText: offer.discountText,
      discountType: offer.discountType,
      discountValue: offer.discountValue,
      imageUrl: offer.imageUrl,
      sourceUrl: offer.sourceUrl,
      onlineUrl: offer.onlineUrl,
      startDate: offer.startDate,
      endDate: offer.endDate,
      isVerified: offer.isVerified,
      isPublished: offer.isPublished,
      isFeatured: offer.isFeatured,
      aiConfidence: offer.aiConfidence,
      createdBy: offer.createdBy,
      createdAt: offer.createdAt,
      updatedAt: offer.updatedAt,
      createdByUserId: offer.createdByUserId,
      createdByRole: offer.createdByRole,
      status: offer.status,
      approvalStatus: offer.approvalStatus,
      approvalNotes: offer.approvalNotes,
      approvedBy: offer.approvedBy,
      approvedAt: offer.approvedAt,
      categoryIds: offer.categoryIds,
      categoryNames: offer.categoryNames,
      cityIds: offer.cityIds,
      cityNames: offer.cityNames,
      viewCount: offer.viewCount,
      saveCount: offer.saveCount,
      shareCount: offer.shareCount,
      clickCount: offer.clickCount,
      reportCount: offer.reportCount,
    );
  }

  factory OfferModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return OfferModel(
      id: data['id'] as String? ?? doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      brandId: data['brandId'] as String? ?? '',
      brandName: data['brandName'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      cityId: data['cityId'] as String? ?? '',
      cityName: data['cityName'] as String? ?? '',
      discountText: data['discountText'] as String? ?? '',
      discountType: data['discountType'] as String? ?? 'percentage',
      discountValue: data['discountValue'] as num?,
      imageUrl: data['imageUrl'] as String? ?? '',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      onlineUrl: data['onlineUrl'] as String? ?? '',
      startDate: _readDate(data['startDate']),
      endDate: _readDate(data['endDate']),
      isVerified: data['isVerified'] as bool? ?? false,
      isPublished: data['isPublished'] as bool? ?? false,
      isFeatured: data['isFeatured'] as bool? ?? false,
      aiConfidence: data['aiConfidence'] as num?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      createdByUserId:
          data['createdByUserId'] as String? ??
          data['createdBy'] as String? ??
          '',
      createdByRole: data['createdByRole'] as String? ?? 'super_admin',
      status:
          data['status'] as String? ??
          ((data['isPublished'] as bool? ?? false) ? 'published' : 'draft'),
      approvalStatus:
          data['approvalStatus'] as String? ??
          ((data['isVerified'] as bool? ?? false) ? 'approved' : 'pending'),
      approvalNotes: data['approvalNotes'] as String? ?? '',
      approvedBy: data['approvedBy'] as String? ?? '',
      approvedAt: _readOptionalDate(data['approvedAt']),
      categoryIds: _readStringList(data['categoryIds']).isEmpty
          ? [
              data['categoryId'] as String? ?? '',
            ].where((id) => id.isNotEmpty).toList()
          : _readStringList(data['categoryIds']),
      categoryNames: _readStringList(data['categoryNames']).isEmpty
          ? [
              data['categoryName'] as String? ?? '',
            ].where((name) => name.isNotEmpty).toList()
          : _readStringList(data['categoryNames']),
      cityIds: _readStringList(data['cityIds']).isEmpty
          ? [
              data['cityId'] as String? ?? '',
            ].where((id) => id.isNotEmpty).toList()
          : _readStringList(data['cityIds']),
      cityNames: _readStringList(data['cityNames']).isEmpty
          ? [
              data['cityName'] as String? ?? '',
            ].where((name) => name.isNotEmpty).toList()
          : _readStringList(data['cityNames']),
      viewCount: data['viewCount'] as int? ?? 0,
      saveCount: data['saveCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      clickCount: data['clickCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = true}) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'brandId': brandId,
      'brandName': brandName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
      'cityId': cityId,
      'cityName': cityName,
      'cityIds': cityIds,
      'cityNames': cityNames,
      'discountText': discountText,
      'discountType': discountType,
      'discountValue': discountValue,
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'onlineUrl': onlineUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isVerified': isVerified,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'aiConfidence': aiConfidence,
      'createdBy': createdBy,
      'createdByUserId': createdByUserId,
      'createdByRole': createdByRole,
      'status': status,
      'approvalStatus': approvalStatus,
      'approvalNotes': approvalNotes,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'viewCount': viewCount,
      'saveCount': saveCount,
      'shareCount': shareCount,
      'clickCount': clickCount,
      'reportCount': reportCount,
      if (includeCreatedAt) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
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

  static List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}
