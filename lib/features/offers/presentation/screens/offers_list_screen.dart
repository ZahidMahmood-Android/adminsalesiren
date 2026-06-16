import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../providers/offer_providers.dart';
import '../widgets/offer_filters_bar.dart';
import '../widgets/offer_tile.dart';

class OffersListScreen extends ConsumerWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);
    final actionState = ref.watch(offerActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      header: ScreenHeader(
        title: 'Offers',
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/offers/new'),
            icon: const Icon(Icons.add),
            label: const Text('New offer'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OfferFiltersBar(),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedContent(
              child: offers.when(
                skipLoadingOnRefresh: true,
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      key: const ValueKey('offers-empty'),
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
                    key: const ValueKey('offers-list'),
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) => FadeIn(
                        delay: Duration(milliseconds: index * 25),
                        child: OfferTile(offer: items[index]),
                      ),
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
          ),
        ],
      ),
    );
  }
}
