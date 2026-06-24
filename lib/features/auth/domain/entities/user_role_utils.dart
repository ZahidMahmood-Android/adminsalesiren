import 'user_roles.dart';

import '../../../../core/utils/display_label_utils.dart';

class UserRoleUtils {
  const UserRoleUtils._();

  static const rolePriority = [
    UserRoles.superAdmin,
    'admin',
    UserRoles.brandAdmin,
    UserRoles.manager,
    UserRoles.mobileUser,
  ];

  static List<String> readRoles(Map<String, dynamic> data) {
    final rawRoles = data['roles'];
    if (rawRoles is Iterable) {
      final roles = normalizeRoles(rawRoles.whereType<String>());
      if (roles.isNotEmpty) {
        return roles;
      }
    }

    final singleRole = data['role'] as String?;
    if (singleRole != null && singleRole.isNotEmpty) {
      return [normalizeRole(singleRole)];
    }

    return const [UserRoles.mobileUser];
  }

  static String primaryRole(List<String> roles) {
    final normalizedRoles = normalizeRoles(roles);
    for (final role in rolePriority) {
      final normalizedRole = normalizeRole(role);
      if (normalizedRoles.contains(normalizedRole)) {
        return normalizedRole;
      }
    }
    return normalizedRoles.first;
  }

  static String normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    return switch (normalized) {
      UserRoles.legacySuperAdmin || 'admin' => UserRoles.owner,
      UserRoles.legacyUserOwner => UserRoles.owner,
      UserRoles.brandAdmin => UserRoles.brandAdmin,
      UserRoles.manager => UserRoles.manager,
      UserRoles.mobileUser => UserRoles.mobileUser,
      _ => normalized,
    };
  }

  static List<String> normalizeRoles(Iterable<String> roles) {
    final normalized = <String>[];
    for (final role in roles) {
      final value = normalizeRole(role);
      if (value.isNotEmpty && !normalized.contains(value)) {
        normalized.add(value);
      }
    }
    return normalized.isEmpty ? const [UserRoles.mobileUser] : normalized;
  }

  static bool hasRole(List<String> roles, String role) {
    return normalizeRoles(roles).contains(normalizeRole(role));
  }

  static bool hasAnyRole(List<String> roles, Iterable<String> expected) {
    for (final role in expected) {
      if (hasRole(roles, role)) {
        return true;
      }
    }
    return false;
  }

  static bool isBrandScoped(List<String> roles) {
    return hasAnyRole(roles, [UserRoles.brandAdmin, UserRoles.manager]);
  }

  static bool requiresBrand(List<String> roles) {
    return hasRole(roles, UserRoles.brandAdmin);
  }

  static bool isMobileUserOnly(List<String> roles) {
    final normalized = normalizeRoles(roles);
    return normalized.length == 1 && normalized.first == UserRoles.mobileUser;
  }

  static bool canEnableAdminPanel(List<String> roles) {
    return hasAnyRole(roles, [
      UserRoles.owner,
      UserRoles.brandAdmin,
      UserRoles.manager,
    ]);
  }

  static bool defaultIsAdminEnabled(List<String> roles) {
    if (hasRole(roles, UserRoles.owner)) {
      return true;
    }
    if (isMobileUserOnly(roles)) {
      return false;
    }
    return canEnableAdminPanel(roles);
  }

  static bool resolvesAdminEnabled(List<String> roles, bool storedValue) {
    if (hasRole(roles, UserRoles.owner)) {
      return true;
    }
    if (!canEnableAdminPanel(roles)) {
      return false;
    }
    return storedValue;
  }

  static bool defaultIsMobileAppEnabled(List<String> roles) {
    return true;
  }

  static bool resolvesMobileAppEnabled(List<String> roles, bool storedValue) {
    if (hasRole(roles, UserRoles.owner)) {
      return true;
    }
    return storedValue;
  }

  static String labelsFor(List<String> roles) =>
      DisplayLabelUtils.slugs(normalizeRoles(roles));
}
