import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/offer_providers.dart';
import '../widgets/offer_filters_bar.dart';
import '../widgets/offer_tile.dart';

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
          const OfferFiltersBar(),
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
                        OfferTile(offer: items[index]),
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
