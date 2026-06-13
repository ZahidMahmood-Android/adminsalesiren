import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/admin_access_diagnostics_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../utils/copy_utils.dart';
import 'app_card.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = GoRouterState.of(context).matchedLocation;
    final isCompact = MediaQuery.sizeOf(context).width < 920;
    final adminAccess = ref.watch(adminAccessProvider);

    if (isCompact) {
      return Scaffold(
        appBar: _TopBar(route: route),
        drawer: _MobileDrawer(currentRoute: route),
        body: adminAccess.when(
          data: (hasAccess) =>
              hasAccess ? child : const _MissingAdminAccessView(),
          loading: () => const AppLoadingView(
            label: 'Checking admin access\n(may take a moment)',
          ),
          error: (error, _) {
            // If it's a timeout, show helpful message
            if (error.toString().contains('timeout')) {
              return AppErrorView(
                message:
                    'Admin access check timed out. '
                    'This may be due to slow internet. '
                    'Try refreshing the page.',
              );
            }
            return AppErrorView(message: error.toString());
          },
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(currentRoute: route),
          Expanded(
            child: Column(
              children: [
                _DesktopHeader(route: route),
                Expanded(
                  child: adminAccess.when(
                    data: (hasAccess) =>
                        hasAccess ? child : const _MissingAdminAccessView(),
                    loading: () => const AppLoadingView(
                      label: 'Checking admin access\n(may take a moment)',
                    ),
                    error: (error, _) {
                      // If it's a timeout, show helpful message
                      if (error.toString().contains('timeout')) {
                        return AppErrorView(
                          message:
                              'Admin access check timed out. '
                              'This may be due to slow internet. '
                              'Try refreshing the page.',
                        );
                      }
                      return AppErrorView(message: error.toString());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
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

class _DesktopHeader extends ConsumerWidget {
  const _DesktopHeader({required this.route});

  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final title = _items
        .firstWhere(
          (item) => route.startsWith(item.route),
          orElse: () => _items.first,
        )
        .label;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${AppConstants.defaultCityName} operations',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                user.email,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          IconButton.filledTonal(
            tooltip: 'Logout',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const _TopBar({required this.route});

  final String route;

  @override
  Size get preferredSize => const Size.fromHeight(73);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final title = _items
        .firstWhere(
          (item) => route.startsWith(item.route),
          orElse: () => _items.first,
        )
        .label;

    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 24,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Text(
            '${AppConstants.defaultCityName} operations',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              user.email,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: IconButton.filledTonal(
            tooltip: 'Logout',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.line)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandMark(),
                const SizedBox(height: 28),
                ..._items.map(
                  (item) => _NavTile(
                    item: item,
                    selected: currentRoute.startsWith(item.route),
                  ),
                ),
                const SizedBox(height: 28),
                const _SidebarNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(),
              const SizedBox(height: 24),
              ..._items.map(
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
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
              'Admin Panel',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.black54,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFE5F4F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Scaffold.maybeOf(context)?.closeDrawer();
            context.go(item.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: selected ? AppTheme.deepGreen : Colors.black54,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? AppTheme.deepGreen : AppTheme.ink,
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

class _SidebarNote extends StatelessWidget {
  const _SidebarNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'MVP: verified offers first.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
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
  _NavItem('Offers', '/offers', Icons.local_offer_outlined),
  _NavItem('Reports', '/reports', Icons.flag_outlined),
];
