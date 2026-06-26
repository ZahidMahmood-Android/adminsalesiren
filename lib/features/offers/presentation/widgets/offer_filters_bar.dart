import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/multi_select_field.dart';
import '../../../../core/widgets/single_select_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../providers/offer_providers.dart';

class OfferFiltersBar extends ConsumerWidget {
  const OfferFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(offerFiltersProvider);
    final cities = ref.watch(visibleCitiesProvider).value ?? const [];
    final categories = ref.watch(visibleCategoriesProvider).value ?? const [];
    final brands = ref.watch(activeBrandsProvider).value ?? const [];
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final controller = ref.read(offerFiltersProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MultiSelectField(
            label: 'Cities',
            prefixIcon: Icons.location_city_outlined,
            emptyLabel: 'Any city',
            options: cities
                .map((city) => MultiSelectOption(id: city.id, label: city.name))
                .toList(),
            selectedIds: filters.cityIds,
            onChanged: (ids) => controller.update(
              filters.copyWith(cityIds: ids, clearCity: true),
            ),
          ),
          MultiSelectField(
            label: 'Categories',
            prefixIcon: Icons.category_outlined,
            emptyLabel: 'Any category',
            options: categories
                .map(
                  (category) =>
                      MultiSelectOption(id: category.id, label: category.name),
                )
                .toList(),
            selectedIds: filters.categoryIds,
            onChanged: (ids) => controller.update(
              filters.copyWith(categoryIds: ids, clearCategory: true),
            ),
          ),
          if (!isBrandScopedUser)
            MultiSelectField(
              label: 'Brands',
              prefixIcon: Icons.storefront_outlined,
              emptyLabel: 'Any brand',
              options: brands
                  .map(
                    (brand) =>
                        MultiSelectOption(id: brand.id, label: brand.name),
                  )
                  .toList(),
              selectedIds: filters.brandIds,
              onChanged: (ids) => controller.update(
                filters.copyWith(brandIds: ids, clearBrand: true),
              ),
            ),
          SingleSelectField<bool?>(
            label: 'Published',
            prefixIcon: Icons.publish_outlined,
            value: filters.isPublished,
            emptyLabel: 'Any',
            allowAny: true,
            options: const [
              SingleSelectOption(value: true, label: 'Published'),
              SingleSelectOption(value: false, label: 'Draft'),
            ],
            onChanged: (value) => controller.update(
              filters.copyWith(
                isPublished: value,
                clearPublished: value == null,
              ),
            ),
          ),
          SingleSelectField<bool?>(
            label: 'Verified',
            prefixIcon: Icons.verified_outlined,
            value: filters.isVerified,
            emptyLabel: 'Any',
            allowAny: true,
            options: const [
              SingleSelectOption(value: true, label: 'Verified'),
              SingleSelectOption(value: false, label: 'Unverified'),
            ],
            onChanged: (value) => controller.update(
              filters.copyWith(
                isVerified: value,
                clearVerified: value == null,
              ),
            ),
          ),
          if (filters.hasActiveFilters)
            OutlinedButton.icon(
              onPressed: controller.clear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }
}
