import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/admin_access_diagnostics_screen.dart';
import '../../features/notifications/domain/entities/notification_request.dart';
import '../../features/notifications/presentation/providers/notification_providers.dart';
import '../../features/subscriptions/domain/entities/brand_subscription.dart';
import '../../features/subscriptions/domain/entities/subscription_request.dart';
import '../../features/subscriptions/presentation/providers/subscription_providers.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_providers.dart';
import '../utils/copy_utils.dart';
import 'app_background.dart';
import 'app_card.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';
import 'sweet_confirmation_dialog.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context).matchedLocation;
    final isCompact = MediaQuery.sizeOf(context).width < 920;
    final userProfile = ref.watch(currentUserProfileProvider);
    final adminAccess = ref.watch(adminAccessProvider);
    final isBrandAdmin = ref.watch(isBrandAdminProvider);
    final accessContent = _AccessContent(
      adminAccess: adminAccess,
      isBrandAdmin: isBrandAdmin,
      child: child,
    );

    if (userProfile.isLoading || adminAccess.isLoading) {
      return const Scaffold(
        body: AppLoadingView(
          label: 'Checking admin access\n(may take a moment)',
        ),
      );
    }

    if (isCompact) {
      return Scaffold(
        appBar: const _TopBar(),
        drawer: _MobileDrawer(currentRoute: route),
        body: AppBackground(child: accessContent),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentRoute: route),
          Expanded(
            child: Column(
              children: [
                const _DesktopHeader(),
                Expanded(child: AppBackground(child: accessContent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessContent extends ConsumerWidget {
  const _AccessContent({
    required this.adminAccess,
    required this.isBrandAdmin,
    required this.child,
  });

  final AsyncValue<bool> adminAccess;
  final bool isBrandAdmin;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return adminAccess.when(
      data: (hasAccess) {
        if (!hasAccess) {
          // Distinguish inactive accounts from unconfigured admins.
          final user = ref.watch(currentUserProvider);
          if (user != null && !user.isActive) {
            return const _InactiveAccountView();
          }
          return const _MissingAdminAccessView();
        }
        if (isBrandAdmin) return _SubscriptionGate(child: child);
        return child;
      },
      loading: () => const AppLoadingView(
        label: 'Checking admin access\n(may take a moment)',
      ),
      error: (error, _) {
        if (error.toString().contains('timeout')) {
          return const AppErrorView(
            message:
                'Admin access check timed out. '
                'This may be due to slow internet. '
                'Try refreshing the page.',
          );
        }
        return AppErrorView(message: error.toString());
      },
    );
  }
}

class _SubscriptionGate extends ConsumerWidget {
  const _SubscriptionGate({required this.child});

  final Widget child;

  // Routes where brand admins can still navigate even without an active subscription.
  static const _freeRoutes = {
    '/subscriptions/my',
    '/subscriptions/request',
    '/subscriptions/payments',
    '/subscriptions/my-usage',
    '/dashboard',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context).matchedLocation;
    // Always allow free routes so the user can pay/renew without being stuck.
    if (_freeRoutes.any((r) => route == r || route.startsWith('$r/'))) {
      return child;
    }

    final subAsync = ref.watch(activeBrandSubscriptionProvider);
    return subAsync.when(
      // Still loading — show the page normally to avoid flickering.
      loading: () => child,
      error: (_, __) => child,
      data: (sub) {
        if (sub == null || !sub.isUsable) {
          return _SubscriptionExpiredView(sub: sub);
        }
        return child;
      },
    );
  }
}

class _SubscriptionExpiredView extends StatelessWidget {
  const _SubscriptionExpiredView({this.sub});

  final BrandSubscription? sub;

  @override
  Widget build(BuildContext context) {
    final isTrialExpired = sub?.isTrialExpired ?? false;
    final isPaidExpired = sub?.isPaidExpired ?? false;
    final noSub = sub == null;

    final title = noSub
        ? 'No Active Subscription'
        : isTrialExpired
        ? 'Free Trial Ended'
        : isPaidExpired
        ? 'Subscription Expired'
        : 'Subscription Required';

    final message = noSub
        ? 'You do not have an active subscription.\nContact your admin or request a plan to continue.'
        : isTrialExpired
        ? 'Your free trial has ended.\nPlease make a payment to continue using all features.'
        : isPaidExpired
        ? 'Your subscription has expired.\nRenew your plan to continue using all features.'
        : 'Your subscription is not active.\nPlease contact support or renew your plan.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isTrialExpired || isPaidExpired
                    ? Icons.timer_off_outlined
                    : Icons.lock_outline,
                size: 48,
                color: AppTheme.saffron,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/subscriptions/my'),
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text('View Subscription & Pay'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.go('/subscriptions/request'),
                icon: const Icon(Icons.upgrade),
                label: const Text('Request Upgrade / Renewal'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showSweetConfirmationDialog(
    context: context,
    title: 'Logout?',
    message: 'You will need to sign in again to continue.',
    confirmLabel: 'Logout',
    icon: Icons.logout,
    color: AppTheme.saffron,
  );
  if (confirmed) {
    html.window.localStorage.clear();
    html.window.sessionStorage.clear();
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(adminAccessProvider);
  }
}

class _InactiveAccountView extends ConsumerWidget {
  const _InactiveAccountView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_outlined, size: 48, color: Colors.red),
              const SizedBox(height: 14),
              Text(
                'Account Deactivated',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'Your account has been deactivated by the super admin.\n'
                'Please contact customer support to request reactivation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingAdminAccessView extends ConsumerWidget {
  const _MissingAdminAccessView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 46,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'Admin Access Required',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account is not configured as an admin. Create a Firestore document to enable access.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Instructions:',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        final uid = user?.id ?? 'paste-your-uid-here';
                        if (uid != 'paste-your-uid-here') {
                          CopyUtils.copyToClipboard(context, uid, label: 'UID');
                        }
                      },
                      child: Text(
                        '1. Go to Firebase Console > Firestore > Create document\n'
                        '2. Collection: admins\n'
                        '3. Document ID: ${user?.id ?? 'paste-your-uid-here'} (click to copy)\n'
                        '4. Add field: email = "${user?.email ?? 'your-email'}"\n'
                        '5. Refresh this page',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final uid = user?.id ?? 'N/A';
                      CopyUtils.copyToClipboard(context, uid, label: 'UID');
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Your UID'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Refresh your browser to check admin access again',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminAccessDiagnosticsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report_outlined),
                        label: const Text('Run Diagnostics'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _bellCount(WidgetRef ref) {
  final isSuperAdmin = ref.watch(isSuperAdminProvider);
  final subRequests = ref.watch(subscriptionRequestsProvider);
  if (isSuperAdmin) {
    final notifRequests = ref.watch(notificationRequestsProvider);
    final subPending = subRequests.maybeWhen(
      data: (items) => items.where((r) => r.status == 'pending').length,
      orElse: () => 0,
    );
    final notifPending = notifRequests.maybeWhen(
      data: (items) => items.where((r) => r.status == 'pending').length,
      orElse: () => 0,
    );
    return subPending + notifPending;
  } else {
    return subRequests.maybeWhen(
      data: (items) => items.where((r) => r.status == 'approved').length,
      orElse: () => 0,
    );
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final count = _bellCount(ref);
    return _BellPopup(isSuperAdmin: isSuperAdmin, count: count);
  }
}

class _BellPopup extends ConsumerWidget {
  const _BellPopup({required this.isSuperAdmin, required this.count});

  final bool isSuperAdmin;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: count > 0 ? '$count pending notification(s)' : 'Notifications',
      offset: const Offset(0, 46),
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
      onSelected: (route) => GoRouter.of(context).go(route),
      itemBuilder: (context) => _buildItems(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Badge(
          label: Text('$count'),
          isLabelVisible: count > 0,
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildItems(
    BuildContext context,
    WidgetRef ref,
  ) {
    final entries = <PopupMenuEntry<String>>[];

    entries.add(
      PopupMenuItem<String>(
        enabled: false,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          'Notifications',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
    entries.add(const PopupMenuDivider());

    if (isSuperAdmin) {
      final subRequests = ref.watch(subscriptionRequestsProvider);
      final notifRequests = ref.watch(notificationRequestsProvider);

      final pendingSubs = subRequests.maybeWhen(
        data: (items) => items.where((r) => r.status == 'pending').toList(),
        orElse: () => <SubscriptionRequest>[],
      );
      final pendingNotifs = notifRequests.maybeWhen(
        data: (items) => items.where((r) => r.status == 'pending').toList(),
        orElse: () => <NotificationRequest>[],
      );

      if (pendingSubs.isEmpty && pendingNotifs.isEmpty) {
        entries.add(_emptyItem(context, 'All caught up! No pending items.'));
      } else {
        for (final r in pendingSubs.take(4)) {
          entries.add(
            PopupMenuItem<String>(
              value: '/subscriptions/requests',
              child: _NotifTile(
                icon: Icons.upgrade_outlined,
                iconColor: Colors.blue,
                title:
                    '${r.type[0].toUpperCase()}${r.type.substring(1)} request',
                subtitle: 'Brand: ${r.brandId} · Plan: ${r.requestedPlanId}',
              ),
            ),
          );
        }
        if (pendingSubs.length > 4) {
          entries.add(
            PopupMenuItem<String>(
              value: '/subscriptions/requests',
              child: _NotifTile(
                icon: Icons.more_horiz,
                title: '+${pendingSubs.length - 4} more subscription requests',
                subtitle: 'Tap to view all',
              ),
            ),
          );
        }
        for (final r in pendingNotifs.take(3)) {
          entries.add(
            PopupMenuItem<String>(
              value: '/notifications',
              child: _NotifTile(
                icon: Icons.notifications_active_outlined,
                iconColor: Colors.orange,
                title: r.title.isEmpty ? 'Push notification request' : r.title,
                subtitle: 'Brand: ${r.brandId}',
              ),
            ),
          );
        }
        if (pendingNotifs.length > 3) {
          entries.add(
            PopupMenuItem<String>(
              value: '/notifications',
              child: _NotifTile(
                icon: Icons.more_horiz,
                title:
                    '+${pendingNotifs.length - 3} more notification requests',
                subtitle: 'Tap to view all',
              ),
            ),
          );
        }
      }
    } else {
      // Brand admin: approved requests
      final subRequests = ref.watch(subscriptionRequestsProvider);
      final approved = subRequests.maybeWhen(
        data: (items) => items.where((r) => r.status == 'approved').toList(),
        orElse: () => <SubscriptionRequest>[],
      );

      if (approved.isEmpty) {
        entries.add(_emptyItem(context, 'No new notifications right now.'));
      } else {
        for (final r in approved.take(5)) {
          final typeLabel = '${r.type[0].toUpperCase()}${r.type.substring(1)}';
          entries.add(
            PopupMenuItem<String>(
              value: '/subscriptions/my',
              child: _NotifTile(
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
                title: '$typeLabel request approved!',
                subtitle: 'Plan: ${r.requestedPlanId} · Tap to view',
              ),
            ),
          );
        }
        if (approved.length > 5) {
          entries.add(
            PopupMenuItem<String>(
              value: '/subscriptions/my',
              child: _NotifTile(
                icon: Icons.more_horiz,
                title: '+${approved.length - 5} more approvals',
                subtitle: 'Tap to view all',
              ),
            ),
          );
        }
      }
    }

    entries.add(const PopupMenuDivider());
    entries.add(
      PopupMenuItem<String>(
        value: isSuperAdmin ? '/subscriptions/requests' : '/subscriptions/my',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View all',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );

    return entries;
  }

  PopupMenuItem<String> _emptyItem(BuildContext context, String message) {
    return PopupMenuItem<String>(
      enabled: false,
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mutedColor = AppColors.textMuted(cs.brightness);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? mutedColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: mutedColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopHeader extends ConsumerWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border(cs.brightness)),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          // Dark / light toggle
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 4),
          const _BellButton(),
          const SizedBox(width: 4),
          if (user != null) _ProfileMenu(email: user.email),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const _TopBar();

  @override
  Size get preferredSize => const Size.fromHeight(57);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      toolbarHeight: 56,
      titleSpacing: 16,
      title: Text(
        AppConstants.appName,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
          ),
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
        const _BellButton(),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: user == null
              ? const SizedBox.shrink()
              : _ProfileMenu(email: user.email),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = email.isEmpty ? 'A' : email.characters.first.toUpperCase();
    final user = ref.watch(currentUserProvider);
    final isBrandAdmin = ref.watch(isBrandAdminProvider);
    final brandId = user?.brandId ?? '';

    return PopupMenuButton<String>(
      tooltip: 'Profile',
      offset: const Offset(0, 46),
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
      onSelected: (value) {
        if (value == 'copy_brand_id' && brandId.isNotEmpty) {
          CopyUtils.copyToClipboard(context, brandId, label: 'Brand ID');
          return;
        }
        if (value == 'profile') {
          context.go(isBrandAdmin ? '/brands' : '/settings');
        }
        if (value == 'logout') {
          _confirmLogout(context, ref);
        }
      },
      itemBuilder: (context) => [
        // Email header
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            email.isEmpty ? 'Admin' : email,
            style: Theme.of(context).textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Brand ID row — visible to brand admins only
        if (isBrandAdmin && brandId.isNotEmpty)
          PopupMenuItem<String>(
            value: 'copy_brand_id',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Builder(
              builder: (context) {
                final mutedColor = AppColors.textMuted(
                  Theme.of(context).colorScheme.brightness,
                );
                return Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Brand ID',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(color: mutedColor),
                          ),
                          Text(
                            brandId,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.copy_outlined, size: 14, color: mutedColor),
                  ],
                );
              },
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.manage_accounts_outlined),
            title: Text('Profile settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.deepGreen,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _visibleItems(ref);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: AppColors.border(cs.brightness)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 28),
                    ...items.map(
                      (item) => _NavTile(
                        item: item,
                        selected: currentRoute.startsWith(item.route),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _MobileDrawer extends ConsumerWidget {
  const _MobileDrawer({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _visibleItems(ref);
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(),
              const SizedBox(height: 24),
              ...items.map(
                (item) => _NavTile(
                  item: item,
                  selected: currentRoute.startsWith(item.route),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends ConsumerWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = ref.watch(isSuperAdminProvider) ? 'Super Admin' : 'Admin';
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.deepGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_offer, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? AppColors.darkCard : AppColors.greenTint;
    final iconColor = selected
        ? cs.primary
        : AppColors.textMuted(cs.brightness);
    final textColor = selected
        ? cs.primary
        : AppColors.textPrimary(cs.brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Scaffold.maybeOf(context)?.closeDrawer();
            context.go(item.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mutedColor = AppColors.textMuted(cs.brightness);
    return InkWell(
      onTap: () => html.window.open(AppConstants.byteCinchWebsite, '_blank'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border(cs.brightness)),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                AppConstants.byteCinchLogoAsset,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.business, size: 28, color: mutedColor),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Developed by',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mutedColor.withOpacity(0.6),
                  ),
                ),
                Text(
                  AppConstants.byteCinchName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}

const _items = [
  _NavItem('Dashboard', '/dashboard', Icons.dashboard_outlined),
  _NavItem('Cities', '/cities', Icons.location_city_outlined),
  _NavItem('Categories', '/categories', Icons.category_outlined),
  _NavItem('Brands', '/brands', Icons.storefront_outlined),
  _NavItem('Users', '/users', Icons.people_outline),
  _NavItem('Reports', '/reports', Icons.flag_outlined),
  _NavItem('Pricing', '/subscriptions/plans', Icons.payments_outlined),
  _NavItem(
    'Subscriptions',
    '/subscriptions/brand-subscriptions',
    Icons.card_membership_outlined,
  ),
  _NavItem('Payments', '/subscriptions/payments', Icons.receipt_long_outlined),
  _NavItem('Usage', '/subscriptions/usage', Icons.bar_chart_outlined),
  _NavItem('Plan Requests', '/subscriptions/requests', Icons.upgrade_outlined),
  _NavItem('Settings', '/settings', Icons.settings_outlined),
];

const _brandItems = [
  _NavItem('Dashboard', '/dashboard', Icons.dashboard_outlined),
  _NavItem('Cities', '/cities', Icons.location_city_outlined),
  _NavItem('Categories', '/categories', Icons.category_outlined),
  _NavItem('My Offers', '/offers', Icons.local_offer_outlined),
  _NavItem(
    'Notification Requests',
    '/notifications',
    Icons.notifications_outlined,
  ),
  _NavItem(
    'My Subscription',
    '/subscriptions/my',
    Icons.card_membership_outlined,
  ),
  _NavItem('My Usage', '/subscriptions/my-usage', Icons.bar_chart_outlined),
  _NavItem('Payments', '/subscriptions/payments', Icons.receipt_long_outlined),
];

List<_NavItem> _visibleItems(WidgetRef ref) {
  return ref.watch(isBrandAdminProvider) ? _brandItems : _items;
}
