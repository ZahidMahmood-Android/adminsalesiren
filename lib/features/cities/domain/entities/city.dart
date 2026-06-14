class City {
  const City({
    required this.id,
    required this.name,
    required this.country,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.userId = '',
  });

  final String id;
  final String name;
  final String country;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  City copyWith({
    String? id,
    String? name,
    String? country,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
