import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/list_search.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/catalog_list_summary.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_screen_body.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import '../widgets/category_tile.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(visibleCategoriesProvider);
    final searchQuery = ref.watch(categoriesListSearchQueryProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final currentUser = ref.watch(currentUserProvider);
    final actionState = ref.watch(categoryActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      title: 'Categories',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/categories/new'),
          icon: const Icon(Icons.add),
          label: const Text('New category'),
        ),
      ],
      child: ListScreenBody<List<Category>>(
        asyncValue: categories,
        onRetry: () => ref.invalidate(visibleCategoriesProvider),
        builder: (items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListSearchField(
                hintText: 'Search categories by name, order, status, topic…',
                queryProvider: categoriesListSearchQueryProvider,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedContent(
                  child: _buildCategoriesContent(
                    context,
                    ref,
                    items,
                    searchQuery,
                    isBrandScopedUser,
                    currentUser?.id,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoriesContent(
    BuildContext context,
    WidgetRef ref,
    List<Category> items,
    String searchQuery,
    bool isBrandScopedUser,
    String? currentUserId,
  ) {
    if (items.isEmpty) {
      return EmptyState(
        key: const ValueKey('cats-empty'),
        icon: Icons.category_outlined,
        title: 'No categories yet',
        message: 'Add categories like Clothing, Grocery, or Restaurants.',
        action: FilledButton.icon(
          onPressed: () => context.go('/categories/new'),
          icon: const Icon(Icons.add),
          label: const Text('New category'),
        ),
      );
    }

    final filteredItems = items
        .where((category) => _categoryMatchesSearch(category, searchQuery))
        .toList();
    if (filteredItems.isEmpty) {
      return EmptyState(
        key: const ValueKey('cats-search-empty'),
        icon: Icons.search_off_outlined,
        title: 'No matching categories',
        message: 'Try a different search term.',
        action: OutlinedButton.icon(
          onPressed: () =>
              ref.read(categoriesListSearchQueryProvider.notifier).state = '',
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
          active: filteredItems.where((category) => category.isActive).length,
          inactive: filteredItems
              .where((category) => !category.isActive)
              .length,
          extra: CatalogSummaryChip(
            label: 'Featured',
            value: filteredItems
                .where((category) => category.isFeatured)
                .length,
            icon: Icons.star_outline,
            color: AppTheme.coral,
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
                key: const ValueKey('cats-list'),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1 ? 2.5 : 2.1,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final category = filteredItems[index];
                  final canManageCategory =
                      !isBrandScopedUser || category.userId == currentUserId;
                  return FadeIn(
                    delay: Duration(milliseconds: index * 35),
                    child: CategoryTile(
                      category: category,
                      showActions: canManageCategory,
                      onEdit: () => context.go('/categories/${category.id}'),
                      onDelete: () => _deleteCategory(context, ref, category),
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

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Delete category?',
      message: 'This will remove ${category.name} permanently.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await ref.read(categoryActionsProvider.notifier).delete(category.id);
  }
}

bool _categoryMatchesSearch(Category category, String query) {
  return matchesSearchQuery(
    query,
    fields: [
      category.id,
      category.name,
      category.slug,
      category.description,
      category.topic,
      category.iconName,
      category.colorHex,
      category.userId,
    ],
    values: [category.isActive, category.isFeatured, category.sortOrder],
    keywords: category.searchKeywords,
  );
}
