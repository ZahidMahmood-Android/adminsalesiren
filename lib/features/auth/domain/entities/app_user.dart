class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.fullName = '',
    this.phoneNumber = '',
    this.role = 'super_admin',
    this.brandId = '',
    this.isActive = true,
  });

  final String id;
  final String email;
  final String displayName;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String brandId;
  final bool isActive;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? fullName,
    String? phoneNumber,
    String? role,
    String? brandId,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      brandId: brandId ?? this.brandId,
      isActive: isActive ?? this.isActive,
    );
  }
}
