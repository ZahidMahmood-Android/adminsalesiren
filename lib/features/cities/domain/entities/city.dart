class City {
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.slug = '',
    this.countryCode = 'PK',
    this.countryName = 'Pakistan',
    this.province = '',
    this.isComingSoon = false,
    this.sortOrder = 0,
    this.searchKeywords = const [],
    this.userId = '',
  });

  final String id;
  final String name;
  final String country;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String slug;
  final String countryCode;
  final String countryName;
  final String province;
  final bool isComingSoon;
  final int sortOrder;
  final List<String> searchKeywords;
  final String userId;

  City copyWith({
    String? id,
    String? name,
    String? country,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? slug,
    String? countryCode,
    String? countryName,
    String? province,
    bool? isComingSoon,
    int? sortOrder,
    List<String>? searchKeywords,
    String? userId,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      province: province ?? this.province,
      isComingSoon: isComingSoon ?? this.isComingSoon,
      sortOrder: sortOrder ?? this.sortOrder,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      userId: userId ?? this.userId,
    );
  }
}
