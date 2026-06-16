import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/city.dart';

class CityModel extends City {
  const CityModel({
    required super.id,
    required super.name,
    required super.country,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.slug,
    super.countryCode,
    super.countryName,
    super.province,
    super.isComingSoon,
    super.sortOrder,
    super.searchKeywords,
    super.userId,
  });

  factory CityModel.fromEntity(City city) {
    return CityModel(
      id: city.id,
      name: city.name,
      country: city.country,
      isActive: city.isActive,
      createdAt: city.createdAt,
      updatedAt: city.updatedAt,
      slug: city.slug,
      countryCode: city.countryCode,
      countryName: city.countryName,
      province: city.province,
      isComingSoon: city.isComingSoon,
      sortOrder: city.sortOrder,
      searchKeywords: city.searchKeywords,
      userId: city.userId,
    );
  }

  factory CityModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CityModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      country: data['country'] as String? ??
          data['countryName'] as String? ??
          '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      slug: data['slug'] as String? ?? doc.id,
      countryCode: data['countryCode'] as String? ?? 'PK',
      countryName: data['countryName'] as String? ?? 'Pakistan',
      province: data['province'] as String? ?? '',
      isComingSoon: data['isComingSoon'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      searchKeywords: _readStringList(data['searchKeywords']),
      userId: data['userId'] as String? ?? data['createdBy'] as String? ?? '',
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

  Map<String, dynamic> toFirestore({bool includeCreatedAt = true}) {
    return {
      'id': id,
      'name': name,
      'slug': slug.isEmpty ? id : slug,
      'country': country,
      'countryCode': countryCode,
      'countryName': countryName,
      'province': province,
      'isActive': isActive,
      'isComingSoon': isComingSoon,
      'sortOrder': sortOrder,
      'searchKeywords': searchKeywords,
      'userId': userId,
      if (includeCreatedAt) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}
