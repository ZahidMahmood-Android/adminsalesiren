import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_card.dart';
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
    final isBrandAdmin = ref.watch(isBrandAdminProvider);
    final controller = ref.read(offerFiltersProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: filters.cityId,
              decoration: const InputDecoration(labelText: 'City'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All cities'),
                ),
                ...cities.map(
                  (city) =>
                      DropdownMenuItem(value: city.id, child: Text(city.name)),
                ),
              ],
              onChanged: (value) => controller.update(
                filters.copyWith(cityId: value, clearCity: value == null),
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String>(
              initialValue: filters.categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All categories'),
                ),
                ...categories.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) => controller.update(
                filters.copyWith(
                  categoryId: value,
                  clearCategory: value == null,
                ),
              ),
            ),
          ),
          if (!isBrandAdmin)
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: filters.brandId,
                decoration: const InputDecoration(labelText: 'Brand'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All brands'),
                  ),
                  ...brands.map(
                    (brand) => DropdownMenuItem(
                      value: brand.id,
                      child: Text(brand.name),
                    ),
                  ),
                ],
                onChanged: (value) => controller.update(
                  filters.copyWith(brandId: value, clearBrand: value == null),
                ),
              ),
            ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<bool>(
              initialValue: filters.isPublished,
              decoration: const InputDecoration(labelText: 'Published'),
              items: const [
                DropdownMenuItem<bool>(value: null, child: Text('Any')),
                DropdownMenuItem(value: true, child: Text('Published')),
                DropdownMenuItem(value: false, child: Text('Draft')),
              ],
              onChanged: (value) => controller.update(
                filters.copyWith(
                  isPublished: value,
                  clearPublished: value == null,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<bool>(
              initialValue: filters.isVerified,
              decoration: const InputDecoration(labelText: 'Verified'),
              items: const [
                DropdownMenuItem<bool>(value: null, child: Text('Any')),
                DropdownMenuItem(value: true, child: Text('Verified')),
                DropdownMenuItem(value: false, child: Text('Unverified')),
              ],
              onChanged: (value) => controller.update(
                filters.copyWith(
                  isVerified: value,
                  clearVerified: value == null,
                ),
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
