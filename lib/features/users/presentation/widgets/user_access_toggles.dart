import 'package:flutter/material.dart';

import '../../../../core/widgets/app_list_tile_material.dart';

import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../auth/domain/entities/user_roles.dart';

class UserAccessToggles extends StatelessWidget {
  const UserAccessToggles({
    required this.selectedRoleIds,
    required this.isAdminEnabled,
    required this.isMobileAppEnabled,
    required this.onAdminChanged,
    required this.onMobileChanged,
    super.key,
  });

  final Set<String> selectedRoleIds;
  final bool isAdminEnabled;
  final bool isMobileAppEnabled;
  final ValueChanged<bool> onAdminChanged;
  final ValueChanged<bool> onMobileChanged;

  List<String> get _roles => selectedRoleIds.toList();

  bool get _mobileOnly => UserRoleUtils.isMobileUserOnly(_roles);

  bool get _isOwner =>
      UserRoleUtils.hasRole(_roles, UserRoles.owner) ||
      selectedRoleIds.contains(UserRoles.legacySuperAdmin) ||
      selectedRoleIds.contains(UserRoles.legacyUserOwner);

  bool get _canEnableAdmin => UserRoleUtils.canEnableAdminPanel(_roles);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppListTileMaterial(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Admin panel access'),
            subtitle: Text(
              _mobileOnly
                  ? 'Not available for mobile-only users.'
                  : _isOwner
                  ? 'Always enabled for owners.'
                  : 'Allow this user to sign in to the admin panel.',
            ),
            value: UserRoleUtils.resolvesAdminEnabled(_roles, isAdminEnabled),
            onChanged: _canEnableAdmin && !_isOwner ? onAdminChanged : null,
          ),
        ),
        AppListTileMaterial(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mobile app access'),
            subtitle: Text(
              _isOwner
                  ? 'Always enabled for owners.'
                  : 'Allow this user to use the Sale Siren mobile app.',
            ),
            value: UserRoleUtils.resolvesMobileAppEnabled(
              _roles,
              isMobileAppEnabled,
            ),
            onChanged: _isOwner ? null : onMobileChanged,
          ),
        ),
      ],
    );
  }
}

void syncUserAccessFlagsWithRoles({
  required Set<String> selectedRoleIds,
  bool? currentIsAdminEnabled,
  bool? currentIsMobileAppEnabled,
  required void Function(bool isAdminEnabled, bool isMobileAppEnabled) apply,
}) {
  final roles = selectedRoleIds.toList();

  if (UserRoleUtils.isMobileUserOnly(roles)) {
    apply(false, UserRoleUtils.defaultIsMobileAppEnabled(roles));
    return;
  }

  if (UserRoleUtils.hasRole(roles, UserRoles.owner)) {
    apply(true, true);
    return;
  }

  final adminEnabled =
      currentIsAdminEnabled ?? UserRoleUtils.defaultIsAdminEnabled(roles);
  final mobileEnabled =
      currentIsMobileAppEnabled ??
      UserRoleUtils.defaultIsMobileAppEnabled(roles);

  apply(
    UserRoleUtils.resolvesAdminEnabled(roles, adminEnabled),
    UserRoleUtils.resolvesMobileAppEnabled(roles, mobileEnabled),
  );
}
