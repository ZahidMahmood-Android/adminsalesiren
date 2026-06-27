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
import '../../../../core/utils/delete_action_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/brand.dart';
import '../providers/brand_providers.dart';
import '../widgets/brand_tile.dart';

class BrandsListScreen extends ConsumerWidget {
  const BrandsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);
    final searchQuery = ref.watch(brandsListSearchQueryProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final isManager = ref.watch(isManagerProvider);
    final canRegisterBrand = !isBrandScopedUser && !isManager;
    final canDeleteBrand = ref.watch(canDeleteBrandProvider);
    final actionState = ref.watch(brandActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      title: isBrandScopedUser ? 'My Brand Profile' : 'Brands',
      actions: isBrandScopedUser
          ? []
          : [
              if (canRegisterBrand)
                OutlinedButton.icon(
                  onPressed: () => context.go('/brands/register'),
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text('Register brand'),
                ),
              FilledButton.icon(
                onPressed: () => context.go('/brands/new'),
                icon: const Icon(Icons.add),
                label: const Text('New brand'),
              ),
            ],
      child: ListScreenBody<List<Brand>>(
        asyncValue: brands,
        onRetry: () => ref.invalidate(brandsProvider),
        builder: (items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListSearchField(
                hintText: 'Search brands by name, order, status, id, contact…',
                queryProvider: brandsListSearchQueryProvider,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedContent(
                  child: _buildBrandsContent(
                    context,
                    ref,
                    items,
                    searchQuery,
                    isBrandScopedUser,
                    canDeleteBrand,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteBrand(
    BuildContext context,
    WidgetRef ref,
    Brand brand,
  ) async {
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Delete brand?',
      message: 'This will remove ${brand.name} permanently.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await ref.read(brandActionsProvider.notifier).delete(brand.id);
    if (!context.mounted) {
      return;
    }
    await completeDeleteAction(
      context,
      ref.read(brandActionsProvider),
      errorTitle: 'Could Not Delete Brand',
    );
  }

  Widget _buildBrandsContent(
    BuildContext context,
    WidgetRef ref,
    List<Brand> items,
    String searchQuery,
    bool isBrandScopedUser,
    bool canDeleteBrand,
  ) {
    if (items.isEmpty) {
      return EmptyState(
        key: const ValueKey('brands-empty'),
        icon: Icons.storefront_outlined,
        title: 'No brands yet',
        message: isBrandScopedUser
            ? 'Your brand profile is not linked yet.'
            : 'Create the first brand to start entering offers.',
        action: isBrandScopedUser
            ? null
            : FilledButton.icon(
                onPressed: () => context.go('/brands/new'),
                icon: const Icon(Icons.add),
                label: const Text('New brand'),
              ),
      );
    }

    final filteredItems = items
        .where((brand) => _brandMatchesSearch(brand, searchQuery))
        .toList();
    sortByNameAscending(filteredItems, (brand) => brand.name);
    if (filteredItems.isEmpty) {
      return EmptyState(
        key: const ValueKey('brands-search-empty'),
        icon: Icons.search_off_outlined,
        title: 'No matching brands',
        message: 'Try a different search term.',
        action: OutlinedButton.icon(
          onPressed: () =>
              ref.read(brandsListSearchQueryProvider.notifier).state = '',
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
          active: filteredItems.where((brand) => brand.isActive).length,
          inactive: filteredItems.where((brand) => !brand.isActive).length,
          extra: CatalogSummaryChip(
            label: 'Featured',
            value: filteredItems.where((brand) => brand.isFeatured).length,
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
                key: const ValueKey('brands-list'),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1 ? 2.5 : 2.1,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final brand = filteredItems[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 35),
                    child: BrandTile(
                      brand: brand,
                      showDelete: canDeleteBrand,
                      onEdit: () => context.go('/brands/${brand.id}'),
                      onDelete: () => _deleteBrand(context, ref, brand),
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
}

bool _brandMatchesSearch(Brand brand, String query) {
  return matchesSearchQuery(
    query,
    fields: [
      brand.id,
      brand.name,
      brand.slug,
      brand.description,
      brand.topic,
      brand.type,
      brand.approvalStatus,
      brand.primaryCategoryId,
      brand.websiteUrl,
      brand.instagramUrl,
      brand.facebookUrl,
      brand.businessContactName,
      brand.businessContactEmail,
      brand.businessContactPhone,
      brand.marketingEmail,
      brand.address,
      brand.createdByAdminId,
      brand.userId,
      ...brand.categoryIds,
      ...brand.cityIds,
      ...brand.ownerUserIds,
      ...brand.urlSources.map((source) => source.name),
      ...brand.urlSources.map((source) => source.url),
    ],
    values: [
      brand.isActive,
      brand.isFeatured,
      brand.isVerified,
      brand.sortOrder,
      brand.categoryIds.length,
      brand.cityIds.length,
    ],
    keywords: brand.searchKeywords,
  );
}
