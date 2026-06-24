import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../brands/presentation/widgets/selection_block.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/domain/entities/city.dart';
import '../../../cities/presentation/providers/city_providers.dart';

class UserCatalogPreferencesField extends ConsumerWidget {
  const UserCatalogPreferencesField({
    required this.selectedCategoryIds,
    required this.selectedCityIds,
    required this.selectedBrandIds,
    required this.onChanged,
    super.key,
  });

  final Set<String> selectedCategoryIds;
  final Set<String> selectedCityIds;
  final Set<String> selectedBrandIds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(activeCitiesProvider);
    final categories = ref.watch(categoriesProvider);
    final brands = ref.watch(activeBrandsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Cities, categories, and brands this user follows. Can be changed later.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        SelectionBlock<City>(
          title: 'Cities',
          items: cities,
          selectedIds: selectedCityIds,
          idOf: (city) => city.id,
          labelOf: (city) => city.name,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        SelectionBlock<Category>(
          title: 'Categories',
          items: categories,
          selectedIds: selectedCategoryIds,
          idOf: (category) => category.id,
          labelOf: (category) => category.name,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        SelectionBlock<Brand>(
          title: 'Brands',
          items: brands,
          selectedIds: selectedBrandIds,
          idOf: (brand) => brand.id,
          labelOf: (brand) => brand.name,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
