import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../domain/entities/offer.dart';
import '../providers/offer_providers.dart';

class OffersListScreen extends ConsumerWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Offers',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/offers/new'),
                icon: const Icon(Icons.add),
                label: const Text('New offer'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _OfferFiltersBar(),
          const SizedBox(height: 18),
          Expanded(
            child: offers.when(
              skipLoadingOnRefresh: true,
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'No offers found',
                    message:
                        'Create an offer or clear filters to see more records.',
                    action: FilledButton.icon(
                      onPressed: () => context.go('/offers/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New offer'),
                    ),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _OfferTile(offer: items[index]),
                  ),
                );
              },
              loading: () => const AppLoadingView(label: 'Loading offers'),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(offersProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferFiltersBar extends ConsumerWidget {
  const _OfferFiltersBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(offerFiltersProvider);
    final cities = ref.watch(citiesProvider).value ?? const [];
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final brands = ref.watch(activeBrandsProvider).value ?? const [];
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

class _OfferTile extends ConsumerWidget {
  const _OfferTile({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(offerActionsProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 58,
          height: 58,
          child: offer.imageUrl.isEmpty
              ? ColoredBox(
                  color: AppTheme.paper,
                  child: Icon(
                    Icons.local_offer_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Image.network(offer.imageUrl, fit: BoxFit.cover),
        ),
      ),
      title: Text(
        offer.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(offer.brandName),
            Text(offer.discountText),
            Text('${offer.startDate.shortDate} - ${offer.endDate.shortDate}'),
          ],
        ),
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppBadge(
            label: offer.isPublished ? 'Published' : 'Draft',
            color: offer.isPublished ? AppTheme.deepGreen : Colors.black45,
          ),
          AppBadge(
            label: offer.isVerified ? 'Verified' : 'Unverified',
            color: offer.isVerified ? AppTheme.freshGreen : AppTheme.saffron,
          ),
          IconButton(
            tooltip: offer.isPublished ? 'Unpublish' : 'Publish',
            onPressed: actionState.isLoading
                ? null
                : () => ref
                      .read(offerActionsProvider.notifier)
                      .publish(offer.id, !offer.isPublished),
            icon: Icon(
              offer.isPublished
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Open offer',
            onPressed: () => context.go('/offers/${offer.id}'),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
