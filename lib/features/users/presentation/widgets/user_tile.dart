import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role_utils.dart';

class UserTile extends StatelessWidget {
  const UserTile({
    required this.user,
    required this.onEdit,
    required this.onViewDetails,
    required this.onDelete,
    required this.onActiveChanged,
    this.actionsEnabled = true,
    super.key,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onViewDetails;
  final VoidCallback onDelete;
  final ValueChanged<bool> onActiveChanged;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = _accentForUser(user);
    final displayName = user.fullName.isNotEmpty
        ? user.fullName
        : (user.displayName.isNotEmpty ? user.displayName : 'Unknown user');
    final subtitle = user.email.isNotEmpty
        ? user.email
        : (user.phoneNumber.isNotEmpty ? user.phoneNumber : user.id);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: AppAvatar(
                name: displayName,
                radius: 22,
                backgroundColor: accent.withValues(alpha: 0.12),
                foregroundColor: accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.title(
                  displayName,
                  fontWeight: FontWeight.w900,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AppTextView.body(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.textMuted(brightness),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(icon: Icons.fingerprint_outlined, label: user.id),
                    _MetaChip(
                      icon: Icons.badge_outlined,
                      label: UserRoleUtils.labelsFor(user.roles),
                    ),
                    if (user.brandId.isNotEmpty)
                      _MetaChip(
                        icon: Icons.storefront_outlined,
                        label: user.brandId,
                      ),
                    if (user.phoneNumber.isNotEmpty)
                      _MetaChip(
                        icon: Icons.phone_outlined,
                        label: user.phoneNumber,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppBadge(
                      label: user.isActive ? 'Active' : 'Inactive',
                      color: user.isActive
                          ? AppTheme.deepGreen
                          : Colors.black45,
                    ),
                    if (user.effectiveIsAdminEnabled)
                      const AppBadge(
                        label: 'Admin access',
                        color: AppTheme.freshGreen,
                      ),
                    if (user.effectiveIsMobileAppEnabled)
                      const AppBadge(
                        label: 'Mobile app',
                        color: AppTheme.saffron,
                      ),
                    if (user.notificationEnabled)
                      const AppBadge(
                        label: 'Notifications on',
                        color: AppTheme.coral,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: user.isActive,
                onChanged: actionsEnabled ? onActiveChanged : null,
              ),
              IconButton(
                tooltip: 'Edit user',
                onPressed: actionsEnabled ? onEdit : null,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'View user details',
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: 'Delete user profile',
                onPressed: actionsEnabled ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _accentForUser(AppUser user) {
  final role = UserRoleUtils.primaryRole(user.roles);
  return switch (role) {
    'owner' || 'super_admin' => AppTheme.deepGreen,
    'brand_admin' => AppTheme.freshGreen,
    'manager' => AppTheme.saffron,
    _ => Colors.blueGrey,
  };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
