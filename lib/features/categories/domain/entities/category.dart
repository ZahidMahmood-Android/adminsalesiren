class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.slug = '',
    this.topic = '',
    this.description = '',
    this.colorHex = '',
    this.isFeatured = false,
    this.searchKeywords = const [],
    this.userId = '',
  });

  final String id;
  final String name;
  final String iconName;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String slug;
  final String topic;
  final String description;
  final String colorHex;
  final bool isFeatured;
  final List<String> searchKeywords;
  final String userId;

  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? slug,
    String? topic,
    String? description,
    String? colorHex,
    bool? isFeatured,
    List<String>? searchKeywords,
    String? userId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      isFeatured: isFeatured ?? this.isFeatured,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      userId: userId ?? this.userId,
    );
  }
}
