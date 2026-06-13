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
      'cityId': cityId,
      'cityName': cityName,
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
}
