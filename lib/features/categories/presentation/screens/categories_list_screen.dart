import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../providers/category_providers.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/categories/new'),
                icon: const Icon(Icons.add),
                label: const Text('New category'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: categories.when(
              skipLoadingOnRefresh: true,
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
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
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = items[index];
                      return ListTile(
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
                            IconButton(
                              tooltip: 'Edit category',
                              onPressed: () =>
                                  context.go('/categories/${category.id}'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete category',
                              onPressed: () async {
                                final confirmed =
                                    await showSweetConfirmationDialog(
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
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const AppLoadingView(label: 'Loading categories'),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
