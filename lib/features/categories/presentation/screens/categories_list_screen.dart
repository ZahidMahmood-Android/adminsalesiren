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
import '../providers/category_providers.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(visibleCategoriesProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final currentUser = ref.watch(currentUserProvider);
    final actionState = ref.watch(categoryActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      header: ScreenHeader(
        title: 'Categories',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/categories/new'),
            icon: const Icon(Icons.add),
            label: const Text('New category'),
          ),
        ],
      ),
      child: AnimatedContent(
        child: categories.when(
          skipLoadingOnRefresh: true,
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                key: const ValueKey('cats-empty'),
                icon: Icons.category_outlined,
                title: 'No categories yet',
                message:
                    'Add categories like Clothing, Grocery, or Restaurants.',
                action: FilledButton.icon(
                  onPressed: () => context.go('/categories/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New category'),
                ),
              );
            }
            return AppCard(
              key: const ValueKey('cats-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = items[index];
                  final canManageCategory =
                      !isBrandScopedUser || category.userId == currentUser?.id;
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.paper,
                        child: Icon(Icons.category_outlined),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${category.id} · sort ${category.sortOrder}',
                      ),
                      trailing: Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppBadge(
                            label: category.isActive ? 'Active' : 'Inactive',
                            color: category.isActive
                                ? AppTheme.deepGreen
                                : Colors.black45,
                          ),
                          if (canManageCategory) ...[
                            IconButton(
                              tooltip: 'Edit category',
                              onPressed: () =>
                                  context.go('/categories/${category.id}'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete category',
                              onPressed: () async {
                                final confirmed = await showSweetConfirmationDialog(
                                  context: context,
                                  title: 'Delete category?',
                                  message:
                                      'This will remove ${category.name} permanently.',
                                  confirmLabel: 'Delete',
                                );
                                if (!confirmed || !context.mounted) {
                                  return;
                                }
                                await ref
                                    .read(categoryActionsProvider.notifier)
                                    .delete(category.id);
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
          loading: () => const AppLoadingView(label: 'Loading categories'),
          error: (error, _) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(visibleCategoriesProvider),
          ),
        ),
      ),
    );
  }
}
