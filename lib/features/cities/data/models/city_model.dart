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
      userId: city.userId,
    );
  }

  factory CityModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CityModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      country: data['country'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
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
      'country': country,
      'isActive': isActive,
      'userId': userId,
      if (includeCreatedAt) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
