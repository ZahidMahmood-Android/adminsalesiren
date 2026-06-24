import 'user_role_utils.dart';
import 'user_roles.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.fullName = '',
    this.phoneNumber = '',
    List<String>? roles,
    this.brandId = '',
    this.categoryIds = const [],
    this.cityIds = const [],
    this.brandIds = const [],
    this.isActive = true,
    this.notificationEnabled = true,
    this.isAdminEnabled = false,
    this.isMobileAppEnabled = true,
    this.mustChangePassword = false,
    this.featureIds = const [],
  }) : roles = roles ?? const [UserRoles.mobileUser];

  final String id;
  final String email;
  final String displayName;
  final String fullName;
  final String phoneNumber;
  final List<String> roles;
  final String brandId;
  final List<String> categoryIds;
  final List<String> cityIds;
  final List<String> brandIds;
  final bool isActive;
  final bool notificationEnabled;
  final bool isAdminEnabled;
  final bool isMobileAppEnabled;
  final bool mustChangePassword;
  final List<String> featureIds;

  String get role => UserRoleUtils.primaryRole(roles);

  bool get canAccessAdminPanel =>
      isActive &&
      UserRoleUtils.resolvesAdminEnabled(roles, isAdminEnabled) &&
      UserRoleUtils.canEnableAdminPanel(roles);

  bool get effectiveIsAdminEnabled =>
      UserRoleUtils.resolvesAdminEnabled(roles, isAdminEnabled);

  bool get effectiveIsMobileAppEnabled =>
      UserRoleUtils.resolvesMobileAppEnabled(roles, isMobileAppEnabled);

  bool hasRole(String role) => UserRoleUtils.hasRole(roles, role);

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? fullName,
    String? phoneNumber,
    List<String>? roles,
    String? brandId,
    List<String>? categoryIds,
    List<String>? cityIds,
    List<String>? brandIds,
    bool? isActive,
    bool? notificationEnabled,
    bool? isAdminEnabled,
    bool? isMobileAppEnabled,
    bool? mustChangePassword,
    List<String>? featureIds,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roles: roles ?? this.roles,
      brandId: brandId ?? this.brandId,
      categoryIds: categoryIds ?? this.categoryIds,
      cityIds: cityIds ?? this.cityIds,
      brandIds: brandIds ?? this.brandIds,
      isActive: isActive ?? this.isActive,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      isAdminEnabled: isAdminEnabled ?? this.isAdminEnabled,
      isMobileAppEnabled: isMobileAppEnabled ?? this.isMobileAppEnabled,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      featureIds: featureIds ?? this.featureIds,
    );
  }
}
