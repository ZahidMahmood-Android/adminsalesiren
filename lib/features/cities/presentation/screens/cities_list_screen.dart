import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/city_providers.dart';

class CitiesListScreen extends ConsumerWidget {
  const CitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(visibleCitiesProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final actionState = ref.watch(cityActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      header: ScreenHeader(
        title: 'Cities',
        actions: isBrandScopedUser
            ? []
            : [
                FilledButton.icon(
                  onPressed: () => context.go('/cities/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New city'),
                ),
              ],
      ),
      child: AnimatedContent(
        child: cities.when(
          skipLoadingOnRefresh: true,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const ValueKey('cities-empty'),
                icon: Icons.location_city_outlined,
                title: 'No cities yet',
                message: 'Cities will appear here once they are available.',
                action: isBrandScopedUser
                    ? null
                    : FilledButton.icon(
                        onPressed: () => context.go('/cities/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('New city'),
                      ),
              );
            }
            return AppCard(
              key: const ValueKey('cities-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.paper,
                        child: Icon(Icons.location_city_outlined),
                      ),
                      title: Text(
                        city.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('${city.id} · ${city.country}'),
                      trailing: Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppBadge(
                            label: city.isActive ? 'Active' : 'Inactive',
                            color: city.isActive
                                ? AppTheme.deepGreen
                                : Colors.black45,
                          ),
                          if (!isBrandScopedUser) ...[
                            IconButton(
                              tooltip: 'Edit city',
                              onPressed: () => context.go('/cities/${city.id}'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete city',
                              onPressed: () async {
                                final confirmed = await showSweetConfirmationDialog(
                                  context: context,
                                  title: 'Delete city?',
                                  message:
                                      'This will remove ${city.name} permanently.',
                                  confirmLabel: 'Delete',
                                );
                                if (!confirmed || !context.mounted) {
                                  return;
                                }
                                await ref
                                    .read(cityActionsProvider.notifier)
                                    .delete(city.id);
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const AppLoadingView(label: 'Loading cities'),
          error: (error, _) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(visibleCitiesProvider),
          ),
        ),
      ),
    );
  }
}
