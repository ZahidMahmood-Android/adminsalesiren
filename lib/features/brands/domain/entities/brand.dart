class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.websiteUrl,
    required this.instagramUrl,
    required this.facebookUrl,
    required this.categoryIds,
    required this.cityIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.userId = '',
  });

  final String id;
  final String name;
  final String logoUrl;
  final String websiteUrl;
  final String instagramUrl;
  final String facebookUrl;
  final List<String> categoryIds;
  final List<String> cityIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  Brand copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? websiteUrl,
    String? instagramUrl,
    String? facebookUrl,
    List<String>? categoryIds,
    List<String>? cityIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      categoryIds: categoryIds ?? this.categoryIds,
      cityIds: cityIds ?? this.cityIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
