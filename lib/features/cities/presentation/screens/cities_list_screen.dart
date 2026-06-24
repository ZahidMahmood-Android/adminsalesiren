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
import '../../domain/entities/city.dart';
import '../providers/city_providers.dart';
import '../widgets/city_tile.dart';

class CitiesListScreen extends ConsumerWidget {
  const CitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(visibleCitiesProvider);
    final searchQuery = ref.watch(citiesListSearchQueryProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final actionState = ref.watch(cityActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
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
      child: ListScreenBody<List<City>>(
        asyncValue: cities,
        onRetry: () => ref.invalidate(visibleCitiesProvider),
        builder: (items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListSearchField(
                hintText:
                    'Search cities by name, order, status, province, country…',
                queryProvider: citiesListSearchQueryProvider,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedContent(
                  child: _buildCitiesContent(
                    context,
                    ref,
                    items,
                    searchQuery,
                    isBrandScopedUser,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCitiesContent(
    BuildContext context,
    WidgetRef ref,
    List<City> items,
    String searchQuery,
    bool isBrandScopedUser,
  ) {
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

    final filteredItems = items
        .where((city) => _cityMatchesSearch(city, searchQuery))
        .toList();
    if (filteredItems.isEmpty) {
      return EmptyState(
        key: const ValueKey('cities-search-empty'),
        icon: Icons.search_off_outlined,
        title: 'No matching cities',
        message: 'Try a different search term.',
        action: OutlinedButton.icon(
          onPressed: () =>
              ref.read(citiesListSearchQueryProvider.notifier).state = '',
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
          active: filteredItems.where((city) => city.isActive).length,
          inactive: filteredItems.where((city) => !city.isActive).length,
          extra: CatalogSummaryChip(
            label: 'Coming soon',
            value: filteredItems.where((city) => city.isComingSoon).length,
            icon: Icons.schedule_outlined,
            color: AppTheme.saffron,
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
                key: const ValueKey('cities-list'),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1 ? 2.8 : 2.35,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final city = filteredItems[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 35),
                    child: CityTile(
                      city: city,
                      showActions: !isBrandScopedUser,
                      onEdit: () => context.go('/cities/${city.id}'),
                      onDelete: () => _deleteCity(context, ref, city),
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

  Future<void> _deleteCity(
    BuildContext context,
    WidgetRef ref,
    City city,
  ) async {
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Delete city?',
      message: 'This will remove ${city.name} permanently.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await ref.read(cityActionsProvider.notifier).delete(city.id);
  }
}

bool _cityMatchesSearch(City city, String query) {
  return matchesSearchQuery(
    query,
    fields: [
      city.id,
      city.name,
      city.slug,
      city.country,
      city.countryCode,
      city.countryName,
      city.province,
      city.userId,
    ],
    values: [city.isActive, city.isComingSoon, city.sortOrder],
    keywords: city.searchKeywords,
  );
}
