import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_info_row.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/user_management_providers.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(managedUsersProvider);
    final actionState = ref.watch(userManagementActionsProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      header: ScreenHeader(
        title: 'Users',
        actions: [
          if (isSuperAdmin)
            FilledButton.icon(
              onPressed: () => context.go('/users/new'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Register User'),
            ),
        ],
      ),
      child: AnimatedContent(
        child: users.when(
          skipLoadingOnRefresh: true,
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                key: ValueKey('users-empty'),
                icon: Icons.people_outline,
                title: 'No users found',
                message: 'User profiles will appear here once created.',
              );
            }
            return AppCard(
              key: const ValueKey('users-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: AppAvatar(
                        name: user.email.isEmpty ? user.id : user.email,
                        radius: 22,
                      ),
                      title: AppTextView.title(
                        user.email.isEmpty ? user.id : user.email,
                        fontWeight: FontWeight.w800,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: AppTextView.body(
                        [
                          user.role,
                          if (user.brandId.isNotEmpty) user.brandId,
                        ].join(' · '),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppStatusChip(
                            status: user.isActive ? 'active' : 'inactive',
                          ),
                          Switch(
                            value: user.isActive,
                            onChanged: actionState.isLoading
                                ? null
                                : (value) => ref
                                      .read(
                                        userManagementActionsProvider.notifier,
                                      )
                                      .setActive(user.id, value),
                          ),
                          IconButton(
                            tooltip: 'View user details',
                            onPressed: () => _showUserDetails(context, user),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete user profile',
                            onPressed: actionState.isLoading
                                ? null
                                : () async {
                                    final confirmed =
                                        await showSweetConfirmationDialog(
                                          context: context,
                                          title: 'Delete user profile?',
                                          message:
                                              'This removes this user profile from Firestore.',
                                          confirmLabel: 'Delete',
                                        );
                                    if (!confirmed || !context.mounted) {
                                      return;
                                    }
                                    await ref
                                        .read(
                                          userManagementActionsProvider
                                              .notifier,
                                        )
                                        .deleteUserProfile(user.id);
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const AppLoadingView(label: 'Loading users'),
          error: (error, _) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(managedUsersProvider),
          ),
        ),
      ),
    );
  }
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
    final brightness = Theme.of(context).colorScheme.brightness;
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
                  color: AppColors.border(brightness),
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
                        color: AppColors.textMuted(brightness),
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
              label: 'Role',
              value: user.role,
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
