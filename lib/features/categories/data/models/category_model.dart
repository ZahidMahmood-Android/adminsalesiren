import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.iconName,
    required super.isActive,
    required super.sortOrder,
    required super.createdAt,
    required super.updatedAt,
    super.userId,
  });

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      iconName: category.iconName,
      isActive: category.isActive,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      userId: category.userId,
    );
  }

  factory CategoryModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CategoryModel(
      id: data['id'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      iconName: data['iconName'] as String? ?? 'local_offer',
      isActive: data['isActive'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
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
      'iconName': iconName,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'userId': userId,
      if (includeCreatedAt) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
