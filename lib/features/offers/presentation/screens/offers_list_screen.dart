import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/list_search.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_screen_body.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/offer.dart';
import '../providers/offer_providers.dart';
import '../widgets/offer_filters_bar.dart';
import '../widgets/offer_tile.dart';

class OffersListScreen extends ConsumerWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);
    final searchQuery = ref.watch(offersListSearchQueryProvider);
    final actionState = ref.watch(offerActionsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = ref.watch(isOwnerProvider);
    final isManager = ref.watch(isManagerProvider);
    final canSeeAllOffers = isOwner || isManager;

    return ScreenScaffold(
      loading: actionState.isLoading,
      title: 'Offers',
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/offers/new'),
          icon: const Icon(Icons.add),
          label: const Text('New offer'),
        ),
      ],
      child: ListScreenBody<List<Offer>>(
        asyncValue: offers,
        onRetry: () => ref.invalidate(offersStreamProvider),
        builder: (items) {
          if (currentUser == null) {
            return const AppLoader();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListSearchField(
                hintText:
                    'Search offers by title, brand, category, status, discount…',
                queryProvider: offersListSearchQueryProvider,
              ),
              const SizedBox(height: 14),
              const OfferFiltersBar(),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedContent(
                  child: _buildOffersContent(
                    context,
                    ref,
                    items,
                    searchQuery,
                    currentUser.id,
                    canSeeAllOffers,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOffersContent(
    BuildContext context,
    WidgetRef ref,
    List<Offer> items,
    String searchQuery,
    String currentUserId,
    bool canSeeAllOffers,
  ) {
    final visibleOffers =
        (canSeeAllOffers
                ? items
                : items
                      .where(
                        (offer) =>
                            offer.createdByUserId == currentUserId ||
                            offer.createdBy == currentUserId,
                      )
                      .toList())
            .where((offer) => _offerMatchesSearch(offer, searchQuery))
            .toList();

    if (visibleOffers.isEmpty) {
      final hasSearch = normalizeSearchQuery(searchQuery).isNotEmpty;
      return EmptyState(
        key: const ValueKey('offers-empty'),
        icon: hasSearch
            ? Icons.search_off_outlined
            : Icons.local_offer_outlined,
        title: hasSearch ? 'No matching offers' : 'No offers found',
        message: hasSearch
            ? 'Try a different search term or clear filters.'
            : 'Create an offer or clear filters to see more records.',
        action: hasSearch
            ? OutlinedButton.icon(
                onPressed: () =>
                    ref.read(offersListSearchQueryProvider.notifier).state = '',
                icon: const Icon(Icons.close),
                label: const Text('Clear search'),
              )
            : FilledButton.icon(
                onPressed: () => context.go('/offers/new'),
                icon: const Icon(Icons.add),
                label: const Text('New offer'),
              ),
      );
    }

    final groups = _groupOffersByBrand(visibleOffers);
    return ListView.separated(
      key: const ValueKey('offers-list'),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final group = groups[index];
        return FadeIn(
          delay: Duration(milliseconds: index * 35),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.brandName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Chip(
                        label: Text('${group.offers.length}'),
                        avatar: const Icon(
                          Icons.local_offer_outlined,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...group.offers.asMap().entries.map((entry) {
                  return Column(
                    children: [
                      OfferTile(offer: entry.value),
                      if (entry.key != group.offers.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OfferBrandGroup {
  const _OfferBrandGroup({required this.brandName, required this.offers});

  final String brandName;
  final List<Offer> offers;
}

List<_OfferBrandGroup> _groupOffersByBrand(List<Offer> offers) {
  final grouped = <String, List<Offer>>{};
  final names = <String, String>{};
  for (final offer in offers) {
    final key = offer.brandId.isEmpty ? offer.brandName : offer.brandId;
    names[key] = offer.brandName.isEmpty ? 'Unknown brand' : offer.brandName;
    grouped.putIfAbsent(key, () => []).add(offer);
  }
  return grouped.entries.map((entry) {
    return _OfferBrandGroup(
      brandName: names[entry.key] ?? 'Unknown brand',
      offers: entry.value,
    );
  }).toList();
}

bool _offerMatchesSearch(Offer offer, String query) {
  return matchesSearchQuery(
    query,
    fields: [
      offer.id,
      offer.title,
      offer.description,
      offer.brandId,
      offer.brandName,
      offer.categoryId,
      offer.categoryName,
      offer.cityId,
      offer.cityName,
      offer.discountText,
      offer.discountType,
      offer.status,
      offer.approvalStatus,
      offer.approvalNotes,
      offer.createdBy,
      offer.createdByUserId,
      offer.createdByRole,
      offer.sourceUrl,
      offer.onlineUrl,
      offer.shareUrl,
      offer.imageDisplayMode,
      ...offer.categoryIds,
      ...offer.categoryNames,
      ...offer.cityIds,
      ...offer.cityNames,
      ...offer.linkSources.map((source) => source.name),
      ...offer.linkSources.map((source) => source.url),
      ...offer.offerLines.map((line) => line.title),
      ...offer.offerLines.map((line) => line.description),
      ...offer.offerLines.map((line) => line.discountText),
    ],
    values: [
      offer.isPublished,
      offer.isVerified,
      offer.isFeatured,
      offer.discountValue,
      offer.aiConfidence,
      offer.viewCount,
      offer.saveCount,
      offer.shareCount,
      offer.clickCount,
      offer.reportCount,
      offer.startDate,
      offer.endDate,
    ],
  );
}
