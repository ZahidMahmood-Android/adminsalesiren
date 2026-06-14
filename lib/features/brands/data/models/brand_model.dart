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
      userId: data['userId'] as String? ?? data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = true}) {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'categoryIds': categoryIds,
      'cityIds': cityIds,
      'isActive': isActive,
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
