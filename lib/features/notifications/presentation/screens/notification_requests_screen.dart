import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/list_search.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_screen_body.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../../core/services/push_dispatch_user_messages.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/notification_request.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_request_tile.dart';

class NotificationRequestsScreen extends ConsumerWidget {
  const NotificationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(notificationRequestsProvider);
    final searchQuery = ref.watch(notificationRequestsListSearchQueryProvider);
    final isOwner = ref.watch(isOwnerProvider);
    final isManager = ref.watch(isManagerProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final canManageRequests = isOwner || isManager;
    final actionState = ref.watch(notificationRequestActionsProvider);
    final hasPendingRequests =
        requests.value?.any(
          (request) =>
              request.status == 'pending' && request.offerId.isNotEmpty,
        ) ??
        false;

    return ScreenScaffold(
      loading: actionState.isLoading,
      title: 'Notification Requests',
      actions: [
        if ((isBrandScopedUser || canManageRequests) && hasPendingRequests)
          FilledButton.icon(
            onPressed: actionState.isLoading
                ? null
                : () async {
                    final confirmed = await showSweetConfirmationDialog(
                      context: context,
                      title: 'Publish all pending?',
                      message:
                          'This will publish every pending notification request shown for your account.',
                      confirmLabel: 'Publish all',
                      icon: Icons.campaign_outlined,
                    );
                    if (!confirmed || !context.mounted) {
                      return;
                    }
                    try {
                      await ref
                          .read(notificationRequestActionsProvider.notifier)
                          .publishAllPending();
                      if (!context.mounted) {
                        return;
                      }
                      final error =
                          ref.read(notificationRequestActionsProvider).error;
                      if (error != null) {
                        await showNotificationDispatchError(context, error);
                        return;
                      }
                      showAppSuccess(
                        context,
                        'Pending notification requests published.',
                      );
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      await showNotificationDispatchError(context, error);
                    }
                  },
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Publish all'),
          ),
      ],
      child: ListScreenBody<List<NotificationRequest>>(
        asyncValue: requests,
        builder: (items) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListSearchField(
                hintText: 'Search by title, brand, offer, status, topic, type…',
                queryProvider: notificationRequestsListSearchQueryProvider,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedContent(
                  child: _buildRequestsContent(
                    context,
                    ref,
                    items,
                    searchQuery,
                    canManageRequests,
                    isBrandScopedUser,
                    actionState,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsContent(
    BuildContext context,
    WidgetRef ref,
    List<NotificationRequest> items,
    String searchQuery,
    bool canManageRequests,
    bool isBrandScopedUser,
    AsyncValue<void> actionState,
  ) {
    if (items.isEmpty) {
      return const EmptyState(
        key: ValueKey('notif-empty'),
        icon: Icons.notifications_none_outlined,
        title: 'No notification requests',
        message: 'Requests appear when a brand submits an offer.',
      );
    }

    final filteredItems = items
        .where(
          (request) => _notificationRequestMatchesSearch(request, searchQuery),
        )
        .toList();
    if (filteredItems.isEmpty) {
      return EmptyState(
        key: const ValueKey('notif-search-empty'),
        icon: Icons.search_off_outlined,
        title: 'No matching requests',
        message: 'Try a different search term.',
        action: OutlinedButton.icon(
          onPressed: () =>
              ref
                      .read(
                        notificationRequestsListSearchQueryProvider.notifier,
                      )
                      .state =
                  '',
          icon: const Icon(Icons.close),
          label: const Text('Clear search'),
        ),
      );
    }

    final groups = _groupNotificationRequestsByBrand(filteredItems);
    return ListView.separated(
      key: const ValueKey('notif-list'),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final group = groups[index];
        return FadeIn(
          delay: Duration(milliseconds: index * 35),
          child: _NotificationBrandGroupCard(
            group: group,
            canManageRequests: canManageRequests,
            isBrandScopedUser: isBrandScopedUser,
            actionState: actionState,
          ),
        );
      },
    );
  }
}

class _NotificationBrandGroup {
  const _NotificationBrandGroup({
    required this.brandName,
    required this.requests,
  });

  final String brandName;
  final List<NotificationRequest> requests;

  int get pendingCount =>
      requests.where((request) => request.status == 'pending').length;
}

List<_NotificationBrandGroup> _groupNotificationRequestsByBrand(
  List<NotificationRequest> items,
) {
  final grouped = <String, List<NotificationRequest>>{};
  final names = <String, String>{};
  for (final request in items) {
    final key = request.brandId.isEmpty
        ? notificationRequestBrandLabel(request)
        : request.brandId;
    names[key] = notificationRequestBrandLabel(request);
    grouped.putIfAbsent(key, () => []).add(request);
  }
  return grouped.entries.map((entry) {
    final requests = entry.value
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _NotificationBrandGroup(
      brandName: names[entry.key] ?? 'Unknown brand',
      requests: requests,
    );
  }).toList();
}

bool _notificationRequestMatchesSearch(
  NotificationRequest request,
  String query,
) {
  return matchesSearchQuery(
    query,
    fields: [
      request.id,
      request.title,
      request.body,
      request.topic,
      request.type,
      request.status,
      request.brandId,
      request.brandName,
      request.offerId,
      request.offerLineId,
      request.requestedByUserId,
      request.adminNotes,
      request.approvedBy,
      request.groupTitle,
      ...request.targetCityIds,
      ...request.targetCategoryIds,
      ...request.targetTopics,
      ...request.data.entries.map((entry) => '${entry.key} ${entry.value}'),
    ],
    values: [
      request.sentCount,
      request.openCount,
      request.createdAt,
      request.approvedAt,
      request.sentAt,
    ],
  );
}

class _NotificationBrandGroupCard extends ConsumerWidget {
  const _NotificationBrandGroupCard({
    required this.group,
    required this.canManageRequests,
    required this.isBrandScopedUser,
    required this.actionState,
  });

  final _NotificationBrandGroup group;
  final bool canManageRequests;
  final bool isBrandScopedUser;
  final AsyncValue<void> actionState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPublishBrand =
        group.pendingCount > 0 && (isBrandScopedUser || canManageRequests);

    return AppCard(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (canPublishBrand)
                  TextButton.icon(
                    onPressed: actionState.isLoading
                        ? null
                        : () => _publishPendingForBrand(context, ref),
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: Text('Publish (${group.pendingCount})'),
                  ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${group.requests.length}'),
                  avatar: const Icon(
                    Icons.notifications_none_outlined,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...group.requests.asMap().entries.map((entry) {
            return Column(
              children: [
                NotificationRequestTile(
                  request: entry.value,
                  canManageRequests: canManageRequests,
                  isBrandScopedUser: isBrandScopedUser,
                  actionState: actionState,
                ),
                if (entry.key != group.requests.length - 1)
                  const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _publishPendingForBrand(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Publish pending for ${group.brandName}?',
      message:
          'This will publish every pending notification request for this brand.',
      confirmLabel: 'Publish',
      icon: Icons.campaign_outlined,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final actions = ref.read(notificationRequestActionsProvider.notifier);
    try {
      for (final request in group.requests) {
        if (request.status != 'pending' || request.offerId.isEmpty) {
          continue;
        }
        await actions.publishRequest(
          requestId: request.id,
          offerId: request.offerId,
          offerLineId: request.offerLineId,
        );
        final error = ref.read(notificationRequestActionsProvider).error;
        if (error != null) {
          await showNotificationDispatchError(context, error);
          return;
        }
      }
      if (!context.mounted) {
        return;
      }
      showAppSuccess(
        context,
        'Pending requests for ${group.brandName} published.',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      await showNotificationDispatchError(context, error);
    }
  }
}
