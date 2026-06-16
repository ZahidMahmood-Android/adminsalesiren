import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/brand.dart';

class BrandModel extends Brand {
  const BrandModel({
    required super.id,
    required super.name,
    required super.logoUrl,
    required super.websiteUrl,
    required super.instagramUrl,
    required super.facebookUrl,
    required super.categoryIds,
    required super.cityIds,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.slug,
    super.description,
    super.primaryCategoryId,
    super.type,
    super.isVerified,
    super.isFeatured,
    super.sortOrder,
    super.searchKeywords,
    super.businessContactName,
    super.businessContactPhone,
    super.businessContactEmail,
    super.marketingEmail,
    super.address,
    super.approvalStatus,
    super.ownerUserIds,
    super.createdByAdminId,
    super.userId,
  });

  factory BrandModel.fromEntity(Brand brand) {
    return BrandModel(
      id: brand.id,
      name: brand.name,
      logoUrl: brand.logoUrl,
      websiteUrl: brand.websiteUrl,
      instagramUrl: brand.instagramUrl,
      facebookUrl: brand.facebookUrl,
      categoryIds: brand.categoryIds,
      cityIds: brand.cityIds,
      isActive: brand.isActive,
      createdAt: brand.createdAt,
      updatedAt: brand.updatedAt,
      slug: brand.slug,
      description: brand.description,
      primaryCategoryId: brand.primaryCategoryId,
      type: brand.type,
      isVerified: brand.isVerified,
      isFeatured: brand.isFeatured,
      sortOrder: brand.sortOrder,
      searchKeywords: brand.searchKeywords,
      businessContactName: brand.businessContactName,
      businessContactPhone: brand.businessContactPhone,
      businessContactEmail: brand.businessContactEmail,
      marketingEmail: brand.marketingEmail,
      address: brand.address,
      approvalStatus: brand.approvalStatus,
      ownerUserIds: brand.ownerUserIds,
      createdByAdminId: brand.createdByAdminId,
      userId: brand.userId,
    );
  }

  factory BrandModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BrandModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      logoUrl: data['logoUrl'] as String? ?? '',
      websiteUrl: data['websiteUrl'] as String? ?? '',
      instagramUrl: data['instagramUrl'] as String? ?? '',
      facebookUrl: data['facebookUrl'] as String? ?? '',
      categoryIds: _readStringList(data['categoryIds']),
      cityIds: _readStringList(data['cityIds']),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      slug: data['slug'] as String? ?? doc.id,
      description: data['description'] as String? ?? '',
      primaryCategoryId: data['primaryCategoryId'] as String? ?? '',
      type: data['type'] as String? ?? 'brand',
      isVerified: data['isVerified'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      searchKeywords: _readStringList(data['searchKeywords']),
      businessContactName: data['businessContactName'] as String? ?? '',
      businessContactPhone: data['businessContactPhone'] as String? ?? '',
      businessContactEmail: data['businessContactEmail'] as String? ?? '',
      marketingEmail: data['marketingEmail'] as String? ?? '',
      address: data['address'] as String? ?? '',
      approvalStatus: data['approvalStatus'] as String? ?? 'approved',
      ownerUserIds: _readStringList(data['ownerUserIds']),
      createdByAdminId: data['createdByAdminId'] as String? ?? '',
      userId: data['userId'] as String? ?? data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = true}) {
    return {
      'id': id,
      'name': name,
      'slug': slug.isEmpty ? id : slug,
      'description': description,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'primaryCategoryId': primaryCategoryId,
      'categoryIds': categoryIds,
      'cityIds': cityIds,
      'type': type,
      'isActive': isActive,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'sortOrder': sortOrder,
      'searchKeywords': searchKeywords,
      'businessContactName': businessContactName,
      'businessContactPhone': businessContactPhone,
      'businessContactEmail': businessContactEmail,
      'marketingEmail': marketingEmail,
      'address': address,
      'approvalStatus': approvalStatus,
      'ownerUserIds': ownerUserIds,
      'createdByAdminId': createdByAdminId,
      'userId': userId,
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

  static List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}
