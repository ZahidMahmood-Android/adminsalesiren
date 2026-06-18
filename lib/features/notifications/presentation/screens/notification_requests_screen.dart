import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/notification_request.dart';
import '../providers/notification_providers.dart';

class NotificationRequestsScreen extends ConsumerWidget {
  const NotificationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(notificationRequestsProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final isManager = ref.watch(isManagerProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final canManageRequests = isSuperAdmin || isManager;
    final actionState = ref.watch(notificationRequestActionsProvider);

    return ScreenScaffold(
      loading: actionState.isLoading,
      header: const ScreenHeader(title: 'Notification Requests'),
      child: AnimatedContent(
        child: requests.when(
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                key: ValueKey('notif-empty'),
                icon: Icons.notifications_none_outlined,
                title: 'No notification requests',
                message: 'Requests appear when a brand submits an offer.',
              );
            }
            return AppCard(
              key: const ValueKey('notif-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final request = items[index];
                  final isPublished =
                      request.status == 'approved' ||
                      request.status == 'published';
                  final showStatusSelector =
                      request.status == 'pending' &&
                      (isBrandScopedUser || canManageRequests);
                  final canEditOrDelete =
                      !isPublished && request.status != 'sent';
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      title: Text(request.title),
                      subtitle: Text(
                        '${request.body}\nBrand: ${request.brandId} · Offer: ${request.offerId}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!showStatusSelector)
                            AppBadge(
                              label: _requestStatusLabel(request.status),
                              color: _requestStatusColor(request.status),
                            ),
                          if (showStatusSelector)
                            PopupMenuButton<String>(
                              tooltip: 'Change status',
                              enabled: !actionState.isLoading,
                              initialValue: request.status == 'approved'
                                  ? 'published'
                                  : 'pending',
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'pending',
                                  child: Text('Pending Review'),
                                ),
                                PopupMenuItem(
                                  value: 'published',
                                  child: Text('Published'),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == request.status ||
                                    (value == 'published' && isPublished)) {
                                  return;
                                }
                                if (value == 'pending') {
                                  await ref
                                      .read(
                                        notificationRequestActionsProvider
                                            .notifier,
                                      )
                                      .updateStatus(request.id, 'pending');
                                  return;
                                }
                                final confirmed = await showSweetConfirmationDialog(
                                  context: context,
                                  title: 'Publish offer?',
                                  message:
                                      'This will publish the offer and approve its notification request.',
                                  confirmLabel: 'Publish',
                                  icon: Icons.campaign_outlined,
                                );
                                if (!confirmed || !context.mounted) {
                                  return;
                                }
                                if (request.offerId.isNotEmpty) {
                                  await ref
                                      .read(
                                        notificationRequestActionsProvider
                                            .notifier,
                                      )
                                      .publishRequest(
                                        requestId: request.id,
                                        offerId: request.offerId,
                                      );
                                } else {
                                  await ref
                                      .read(
                                        notificationRequestActionsProvider
                                            .notifier,
                                      )
                                      .updateStatus(request.id, 'approved');
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppBadge(
                                    label: _requestStatusLabel(request.status),
                                    color: _requestStatusColor(request.status),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          if (request.offerId.isNotEmpty)
                            IconButton(
                              tooltip: 'Preview offer',
                              onPressed: () =>
                                  context.go('/offers/${request.offerId}'),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          if ((isBrandScopedUser || canManageRequests) &&
                              canEditOrDelete)
                            IconButton(
                              tooltip: 'Edit request',
                              onPressed: actionState.isLoading
                                  ? null
                                  : () async {
                                      final updated = await _editRequestDialog(
                                        context,
                                        request,
                                      );
                                      if (updated == null) {
                                        return;
                                      }
                                      await ref
                                          .read(
                                            notificationRequestActionsProvider
                                                .notifier,
                                          )
                                          .saveRequest(updated);
                                    },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          if ((isBrandScopedUser || canManageRequests) &&
                              canEditOrDelete)
                            IconButton(
                              tooltip: 'Delete request',
                              onPressed: actionState.isLoading
                                  ? null
                                  : () async {
                                      final confirmed =
                                          await showSweetConfirmationDialog(
                                            context: context,
                                            title: 'Delete request?',
                                            message:
                                                'This notification request will be removed.',
                                            confirmLabel: 'Delete',
                                          );
                                      if (!confirmed || !context.mounted) {
                                        return;
                                      }
                                      await ref
                                          .read(
                                            notificationRequestActionsProvider
                                                .notifier,
                                          )
                                          .deleteRequest(request.id);
                                    },
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () =>
              const AppLoadingView(label: 'Loading notification requests'),
          error: (error, _) => AppErrorView(message: error.toString()),
        ),
      ),
    );
  }
}

String _requestStatusLabel(String status) {
  if (status == 'approved' || status == 'published') {
    return 'Published';
  }
  if (status == 'pending') {
    return 'Pending Review';
  }
  if (status == 'rejected') {
    return 'Rejected';
  }
  return status.isEmpty ? 'Pending Review' : status;
}

Color _requestStatusColor(String status) {
  if (status == 'approved' || status == 'published') {
    return Colors.green;
  }
  if (status == 'rejected') {
    return Colors.red;
  }
  return Colors.orange;
}

Future<NotificationRequest?> _editRequestDialog(
  BuildContext context,
  NotificationRequest request,
) {
  final titleController = TextEditingController(text: request.title);
  final bodyController = TextEditingController(text: request.body);
  return showDialog<NotificationRequest>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit notification request'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              ctx,
              NotificationRequest(
                id: request.id,
                title: titleController.text.trim(),
                body: bodyController.text.trim(),
                topic: request.topic,
                type: request.type,
                data: request.data,
                status: request.status,
                createdAt: request.createdAt,
                brandId: request.brandId,
                offerId: request.offerId,
                requestedByUserId: request.requestedByUserId,
                targetCityIds: request.targetCityIds,
                targetCategoryIds: request.targetCategoryIds,
                targetTopics: request.targetTopics,
                adminNotes: request.adminNotes,
                approvedBy: request.approvedBy,
                approvedAt: request.approvedAt,
                sentAt: request.sentAt,
                sentCount: request.sentCount,
                openCount: request.openCount,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
