import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_screen_body.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../domain/entities/discovered_offer.dart';
import '../../domain/entities/discovered_offer_status.dart';
import '../providers/discovered_offer_providers.dart';
import '../widgets/discovered_offer_tile.dart';
import '../widgets/offer_discovery_result_dialog.dart';
import '../widgets/offer_discovery_schedule_card.dart';

class OfferDiscoveryScreen extends ConsumerWidget {
  const OfferDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccess = ref.watch(canAccessOfferDiscoveryProvider);
    if (!canAccess) {
      return const ScreenScaffold(
        title: 'Offer Discovery',
        child: EmptyState(
          icon: Icons.lock_outline,
          title: 'No access',
          message: 'Offer Discovery is not enabled for your account.',
        ),
      );
    }

    final canRun = ref.watch(canRunOfferDiscoveryProvider);
    final selectedStatus = ref.watch(discoveredOfferStatusFilterProvider);
    final discoveredOffers = ref.watch(discoveredOffersStreamProvider);
    final actions = ref.watch(discoveredOfferActionsProvider);
    final runState = ref.watch(offerDiscoveryRunProvider);
    final clearState = ref.watch(offerDiscoveryClearProvider);
    final scheduleSaveState = ref.watch(offerDiscoverySettingsActionsProvider);
    final isBusy =
        actions.isLoading ||
        runState.isLoading ||
        clearState.isLoading ||
        scheduleSaveState.isLoading;

    return ScreenScaffold(
      loading: isBusy,
      title: 'Offer Discovery',
      subtitle: 'Scan brand website URLs for offer suggestions. Nothing is auto-published.',
      actions: [
        if (canRun) ...[
          OutlinedButton.icon(
            onPressed: isBusy ? null : () => _clearAll(context, ref),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear All'),
          ),
          FilledButton.icon(
            onPressed: isBusy ? null : () => _runDiscovery(context, ref),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Run Discovery Now'),
          ),
        ],
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OfferDiscoveryScheduleCard(),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in DiscoveredOfferStatuses.all) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(DiscoveredOfferStatuses.label(status)),
                      selected: selectedStatus == status,
                      onSelected: (selected) {
                        if (!selected) return;
                        ref
                                .read(discoveredOfferStatusFilterProvider.notifier)
                                .state =
                            status;
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListScreenBody<List<DiscoveredOffer>>(
              asyncValue: discoveredOffers,
              builder: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    key: ValueKey('discovered-$selectedStatus-empty'),
                    icon: Icons.travel_explore_outlined,
                    title: 'No ${DiscoveredOfferStatuses.label(selectedStatus)} items',
                    message: selectedStatus ==
                            DiscoveredOfferStatuses.pendingReview
                        ? 'Run discovery to scan active brand website URLs for possible offers.'
                        : 'Nothing in this status yet.',
                  );
                }

                return AnimatedContent(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return DiscoveredOfferTile(
                        offer: item,
                        busy: actions.isLoading,
                        onCreateOfficialOffer:
                            item.status ==
                                DiscoveredOfferStatuses.pendingReview
                            ? () => _convert(context, ref, item)
                            : null,
                        onReject:
                            item.status ==
                                DiscoveredOfferStatuses.pendingReview
                            ? () => _reject(context, ref, item)
                            : null,
                        onMarkDuplicate:
                            item.status ==
                                DiscoveredOfferStatuses.pendingReview
                            ? () => _markDuplicate(context, ref, item)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiscovery(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(offerDiscoveryRunProvider.notifier)
          .runNow();
      if (!context.mounted) return;
      await showOfferDiscoveryResultDialog(context: context, result: result);
    } catch (error) {
      if (!context.mounted) return;
      await showAppError(context, error);
    }
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Clear all discovery suggestions?',
      message:
          'This removes every offer discovery suggestion — pending, converted, '
          'rejected, duplicate, and source error.\n\n'
          'Official offers already in the Offers list are not deleted.',
      confirmLabel: 'Clear all',
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      final deletedCount = await ref
          .read(offerDiscoveryClearProvider.notifier)
          .clearAll();
      if (!context.mounted) return;
      showAppSuccess(
        context,
        deletedCount > 0
            ? 'Removed $deletedCount discovery suggestion(s). You can run discovery again.'
            : 'No discovery suggestions to remove.',
      );
    } catch (error) {
      if (!context.mounted) return;
      await showAppError(context, error);
    }
  }

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    DiscoveredOffer item,
  ) async {
    try {
      await convertDiscoveredOfferAndOpenEditor(
        ref,
        item,
        (route) => context.go(route),
      );
    } catch (error) {
      if (!context.mounted) return;
      await showAppError(context, error);
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    DiscoveredOffer item,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject suggestion'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(discoveredOfferActionsProvider.notifier)
          .reject(item, reason: reasonController.text);
    } catch (error) {
      if (!context.mounted) return;
      await showAppError(context, error);
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _markDuplicate(
    BuildContext context,
    WidgetRef ref,
    DiscoveredOffer item,
  ) async {
    try {
      await ref
          .read(discoveredOfferActionsProvider.notifier)
          .markDuplicate(item);
    } catch (error) {
      if (!context.mounted) return;
      await showAppError(context, error);
    }
  }
}
