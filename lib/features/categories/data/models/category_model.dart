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
    super.slug,
    super.description,
    super.colorHex,
    super.isFeatured,
    super.searchKeywords,
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
      slug: category.slug,
      description: category.description,
      colorHex: category.colorHex,
      isFeatured: category.isFeatured,
      searchKeywords: category.searchKeywords,
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
      slug: data['slug'] as String? ?? doc.id,
      description: data['description'] as String? ?? '',
      colorHex: data['colorHex'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
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
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'isActive': isActive,
      'isFeatured': isFeatured,
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
