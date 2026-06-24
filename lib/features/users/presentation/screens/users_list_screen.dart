import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/list_search.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_info_row.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/catalog_list_summary.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_screen_body.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/user_management_providers.dart';
import '../widgets/user_tile.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(managedUsersProvider);
    final searchQuery = ref.watch(usersListSearchQueryProvider);
    final actionState = ref.watch(userManagementActionsProvider);
    final isOwner = ref.watch(isOwnerProvider);
    final actionsEnabled = isOwner && !actionState.isLoading;

    ref.listen(userManagementActionsProvider, (previous, next) {
      if (next.hasError && context.mounted) {
        showAppError(context, next.error, title: 'Could Not Update User');
      }
    });

    return ScreenScaffold(
      loading: actionState.isLoading,
      title: 'Users',
      actions: [
        if (isOwner)
          FilledButton.icon(
            onPressed: () => context.go('/users/new'),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Register User'),
          ),
      ],
      child: ListScreenBody<List<AppUser>>(
        asyncValue: users,
        onRetry: () => ref.invalidate(managedUsersProvider),
        builder: (items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOwner)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: AppErrorView(
                    message:
                        'Only owners can edit, delete, or change user accounts. '
                        'You can view user details.',
                  ),
                ),
              ListSearchField(
                hintText:
                    'Search users by name, email, role, brand, phone, status…',
                queryProvider: usersListSearchQueryProvider,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedContent(
                  child: _buildUsersContent(
                    context,
                    ref,
                    items,
                    searchQuery,
                    actionsEnabled,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersContent(
    BuildContext context,
    WidgetRef ref,
    List<AppUser> items,
    String searchQuery,
    bool actionsEnabled,
  ) {
    if (items.isEmpty) {
      return const EmptyState(
        key: ValueKey('users-empty'),
        icon: Icons.people_outline,
        title: 'No users found',
        message: 'User profiles will appear here once created.',
      );
    }

    final filteredItems = items
        .where((user) => _userMatchesSearch(user, searchQuery))
        .toList();
    if (filteredItems.isEmpty) {
      return EmptyState(
        key: const ValueKey('users-search-empty'),
        icon: Icons.search_off_outlined,
        title: 'No matching users',
        message: 'Try a different search term.',
        action: OutlinedButton.icon(
          onPressed: () =>
              ref.read(usersListSearchQueryProvider.notifier).state = '',
          icon: const Icon(Icons.close),
          label: const Text('Clear search'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CatalogListSummary(
          total: filteredItems.length,
          active: filteredItems.where((user) => user.isActive).length,
          inactive: filteredItems.where((user) => !user.isActive).length,
          extra: CatalogSummaryChip(
            label: 'Admin access',
            value: filteredItems
                .where((user) => user.effectiveIsAdminEnabled)
                .length,
            icon: Icons.admin_panel_settings_outlined,
            color: AppTheme.freshGreen,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 2
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              return GridView.builder(
                key: const ValueKey('users-list'),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1 ? 2.15 : 1.75,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final user = filteredItems[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 35),
                    child: UserTile(
                      user: user,
                      actionsEnabled: actionsEnabled,
                      onActiveChanged: (value) => ref
                          .read(userManagementActionsProvider.notifier)
                          .setActive(user.id, value),
                      onEdit: () => context.go('/users/${user.id}'),
                      onViewDetails: () => _showUserDetails(context, user),
                      onDelete: () => _deleteUser(context, ref, user),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteUser(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Delete user profile?',
      message: 'This removes this user profile from Firestore.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await ref
        .read(userManagementActionsProvider.notifier)
        .deleteUserProfile(user.id);
  }
}

bool _userMatchesSearch(AppUser user, String query) {
  return matchesSearchQuery(
    query,
    fields: [
      user.id,
      user.email,
      user.displayName,
      user.fullName,
      user.phoneNumber,
      user.brandId,
      UserRoleUtils.labelsFor(user.roles),
      ...user.roles,
      ...user.categoryIds,
      ...user.cityIds,
      ...user.brandIds,
    ],
    values: [
      user.isActive,
      user.notificationEnabled,
      user.effectiveIsAdminEnabled,
      user.effectiveIsMobileAppEnabled,
      user.mustChangePassword,
      user.categoryIds.length,
      user.cityIds.length,
      user.brandIds.length,
    ],
  );
}

void _showUserDetails(BuildContext context, AppUser user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _UserDetailSheet(user: user),
  );
}

class _UserDetailSheet extends StatelessWidget {
  const _UserDetailSheet({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                AppAvatar(
                  name: user.email.isEmpty ? user.id : user.email,
                  radius: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextView.title(
                        user.fullName.isEmpty ? 'Unknown Name' : user.fullName,
                        fontWeight: FontWeight.w900,
                      ),
                      AppTextView.body(
                        user.email.isEmpty ? 'No email' : user.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppStatusChip(status: user.isActive ? 'active' : 'inactive'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            AppInfoRow(
              label: 'User ID',
              value: user.id,
              icon: Icons.fingerprint_outlined,
              onTap: () {
                Clipboard.setData(ClipboardData(text: user.id));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User ID copied')));
              },
            ),
            const AppInfoRow.divider(),
            AppInfoRow(
              label: 'Roles',
              value: UserRoleUtils.labelsFor(user.roles),
              icon: Icons.badge_outlined,
            ),
            if (user.brandId.isNotEmpty) ...[
              const AppInfoRow.divider(),
              AppInfoRow(
                label: 'Brand ID',
                value: user.brandId,
                icon: Icons.storefront_outlined,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.brandId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Brand ID copied')),
                  );
                },
              ),
            ],
            if (user.phoneNumber.isNotEmpty) ...[
              const AppInfoRow.divider(),
              AppInfoRow(
                label: 'Phone',
                value: user.phoneNumber,
                icon: Icons.phone_outlined,
              ),
            ],
            const AppInfoRow.divider(),
            AppInfoRow(
              label: 'Notifications',
              value: user.notificationEnabled ? 'Enabled' : 'Disabled',
              icon: Icons.notifications_outlined,
            ),
            const AppInfoRow.divider(),
            AppInfoRow(
              label: 'Status',
              valueWidget: AppStatusChip(
                status: user.isActive ? 'active' : 'inactive',
              ),
              icon: Icons.toggle_on_outlined,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
