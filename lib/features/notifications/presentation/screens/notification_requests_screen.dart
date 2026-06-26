import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/list_search.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/list_screen_body.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/notification_request.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_publish_actions.dart';
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
          notificationPublishModeButtons(
            enabled: !actionState.isLoading,
            hasPending: hasPendingRequests,
            onPublish: (mode) => publishAllPendingRequests(context, ref, mode: mode),
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

  int get pendingCount => requests
      .where(
        (request) => request.status == 'pending' && request.offerId.isNotEmpty,
      )
      .length;
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

class _NotificationBrandGroupCard extends ConsumerStatefulWidget {
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
  ConsumerState<_NotificationBrandGroupCard> createState() =>
      _NotificationBrandGroupCardState();
}

class _NotificationBrandGroupCardState
    extends ConsumerState<_NotificationBrandGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final canPublishBrand =
        group.pendingCount > 0 &&
        (widget.isBrandScopedUser || widget.canManageRequests);
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              group.brandName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('${group.requests.length}'),
                            avatar: const Icon(
                              Icons.notifications_none_outlined,
                              size: 18,
                            ),
                          ),
                          if (group.pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: Text('${group.pendingCount} pending'),
                              backgroundColor: theme
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.55),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                if (canPublishBrand)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                    child: notificationPublishModeButtons(
                      enabled: !widget.actionState.isLoading,
                      hasPending: group.pendingCount > 0,
                      onPublish: (mode) => publishBrandPendingRequests(
                        context,
                        ref,
                        mode: mode,
                        brandName: group.brandName,
                        requests: group.requests,
                      ),
                    ),
                  ),
                ...group.requests.asMap().entries.map((entry) {
                  return Column(
                    children: [
                      NotificationRequestTile(
                        request: entry.value,
                        canManageRequests: widget.canManageRequests,
                        isBrandScopedUser: widget.isBrandScopedUser,
                        actionState: widget.actionState,
                      ),
                      if (entry.key != group.requests.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
