import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/display_label_utils.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/services/push_dispatch_user_messages.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../domain/entities/notification_request.dart';
import '../../domain/alert_type_utils.dart';
import '../providers/notification_providers.dart';

class NotificationRequestTile extends ConsumerWidget {
  const NotificationRequestTile({
    required this.request,
    required this.canManageRequests,
    required this.isBrandScopedUser,
    required this.actionState,
    super.key,
  });

  final NotificationRequest request;
  final bool canManageRequests;
  final bool isBrandScopedUser;
  final AsyncValue<void> actionState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublished =
        request.status == 'approved' || request.status == 'published';
    final showStatusSelector =
        request.status == 'pending' && (isBrandScopedUser || canManageRequests);
    final canEditRequest = true;
    final canDeleteRequest = !isPublished && request.status != 'sent';
    final canResendNotification =
        request.offerId.isNotEmpty &&
        (request.status == 'approved' ||
            request.status == 'published' ||
            request.status == 'sent');
    final headline = request.offerLineId.isNotEmpty
        ? request.body
        : request.title;
    final subtitle = request.groupTitle.isNotEmpty
        ? request.groupTitle
        : request.title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 92,
            height: 74,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.title(
                  headline,
                  fontWeight: FontWeight.w900,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppTextView.body(subtitle, maxLines: 1),
                    if (request.offerId.isNotEmpty)
                      AppTextView.label(
                        'Offer ${request.offerId}',
                        color: AppColors.textMuted(
                          Theme.of(context).colorScheme.brightness,
                        ),
                      ),
                    AppTextView.label(
                      _formatCreatedAt(request.createdAt),
                      color: AppColors.textMuted(
                        Theme.of(context).colorScheme.brightness,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!showStatusSelector)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      AppBadge(
                        label: notificationRequestStatusLabel(request.status),
                        color: notificationRequestStatusColor(request.status),
                      ),
                      if (request.type.isNotEmpty)
                        AppBadge(
                          label: alertTypeLabel(request.type),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      AppBadge(
                        label: request.includeImage
                            ? 'With image'
                            : 'Text only',
                        color: request.includeImage
                            ? Theme.of(context).colorScheme.tertiary
                            : AppColors.textMuted(
                                Theme.of(context).colorScheme.brightness,
                              ),
                      ),
                    ],
                  ),
                if (showStatusSelector)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (request.type.isNotEmpty)
                          AppBadge(
                            label: alertTypeLabel(request.type),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        AppBadge(
                          label: request.includeImage
                              ? 'With image'
                              : 'Text only',
                          color: request.includeImage
                              ? Theme.of(context).colorScheme.tertiary
                              : AppColors.textMuted(
                                  Theme.of(context).colorScheme.brightness,
                                ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
                    PopupMenuItem(value: 'published', child: Text('Published')),
                  ],
                  onSelected: (value) =>
                      _onStatusSelected(context, ref, value, isPublished),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBadge(
                        label: notificationRequestStatusLabel(request.status),
                        color: notificationRequestStatusColor(request.status),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              if (request.offerId.isNotEmpty)
                IconButton(
                  tooltip: 'Preview offer',
                  onPressed: () => context.go('/offers/${request.offerId}'),
                  icon: const Icon(Icons.visibility_outlined),
                ),
              if ((isBrandScopedUser || canManageRequests) &&
                  canResendNotification)
                IconButton(
                  tooltip: 'Resend notification',
                  onPressed: actionState.isLoading
                      ? null
                      : () async {
                          final confirmed = await showSweetConfirmationDialog(
                            context: context,
                            title: 'Resend notification?',
                            message:
                                'Send this notification to all mobile users again.',
                            confirmLabel: 'Resend',
                            icon: Icons.campaign_outlined,
                          );
                          if (!confirmed || !context.mounted) {
                            return;
                          }
                          try {
                            final result = await ref
                                .read(
                                  notificationRequestActionsProvider.notifier,
                                )
                                .resendNotification(request);
                            if (!context.mounted) {
                              return;
                            }
                            showNotificationDispatchSuccess(context, result);
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            await showNotificationDispatchError(context, error);
                          }
                        },
                  icon: const Icon(Icons.campaign_outlined),
                ),
              if ((isBrandScopedUser || canManageRequests) && canEditRequest)
                IconButton(
                  tooltip: 'Edit request',
                  onPressed: actionState.isLoading
                      ? null
                      : () async {
                          final updated = await editNotificationRequestDialog(
                            context,
                            request,
                          );
                          if (updated == null) {
                            return;
                          }
                          await ref
                              .read(notificationRequestActionsProvider.notifier)
                              .saveRequest(updated);
                        },
                  icon: const Icon(Icons.edit_outlined),
                ),
              if ((isBrandScopedUser || canManageRequests) && canDeleteRequest)
                IconButton(
                  tooltip: 'Delete request',
                  onPressed: actionState.isLoading
                      ? null
                      : () async {
                          final confirmed = await showSweetConfirmationDialog(
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
                              .read(notificationRequestActionsProvider.notifier)
                              .deleteRequest(request.id);
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onStatusSelected(
    BuildContext context,
    WidgetRef ref,
    String value,
    bool isPublished,
  ) async {
    if (value == request.status || (value == 'published' && isPublished)) {
      return;
    }
    if (value == 'pending') {
      await ref
          .read(notificationRequestActionsProvider.notifier)
          .updateStatus(request.id, 'pending');
      return;
    }
    final confirmed = await showSweetConfirmationDialog(
      context: context,
      title: 'Publish this request?',
      message: request.offerLineId.isNotEmpty
          ? 'This will publish this offer line and send its notification.'
          : 'This will publish the offer and approve its notification request.',
      confirmLabel: 'Publish',
      icon: Icons.campaign_outlined,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      if (request.offerId.isNotEmpty) {
        await ref
            .read(notificationRequestActionsProvider.notifier)
            .publishRequest(
              requestId: request.id,
              offerId: request.offerId,
              offerLineId: request.offerLineId,
            );
      } else {
        await ref
            .read(notificationRequestActionsProvider.notifier)
            .updateStatus(request.id, 'approved');
      }
      if (!context.mounted) {
        return;
      }
      final error = ref.read(notificationRequestActionsProvider).error;
      if (error != null) {
        await showNotificationDispatchError(context, error);
        return;
      }
      showAppSuccess(
        context,
        request.offerId.isNotEmpty
            ? 'Offer published and push notification sent.'
            : 'Notification request approved.',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      await showNotificationDispatchError(context, error);
    }
  }
}

String notificationRequestBrandLabel(NotificationRequest request) {
  if (request.brandName.trim().isNotEmpty) {
    return request.brandName.trim();
  }
  final dataBrand = request.data['brandName']?.trim();
  if (dataBrand != null && dataBrand.isNotEmpty) {
    return dataBrand;
  }
  final bodyBrand = request.body.split(':').first.trim();
  if (bodyBrand.isNotEmpty && bodyBrand != request.body.trim()) {
    return bodyBrand;
  }
  return request.brandId.isEmpty ? 'Unknown brand' : request.brandId;
}

String notificationRequestStatusLabel(String status) {
  if (status == 'approved' || status == 'published') {
    return 'Published';
  }
  if (status == 'pending') {
    return 'Pending Review';
  }
  if (status == 'rejected') {
    return 'Rejected';
  }
  return DisplayLabelUtils.slug(status, fallback: 'Pending Review');
}

Color notificationRequestStatusColor(String status) {
  if (status == 'approved' || status == 'published') {
    return Colors.green;
  }
  if (status == 'rejected') {
    return Colors.red;
  }
  return AppColors.pendingReview;
}

String _formatCreatedAt(DateTime value) {
  final local = value.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

Future<NotificationRequest?> editNotificationRequestDialog(
  BuildContext context,
  NotificationRequest request,
) {
  final titleController = TextEditingController(text: request.title);
  final bodyController = TextEditingController(text: request.body);
  var includeImage = request.includeImage;
  return showDialog<NotificationRequest>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Send with image'),
                subtitle: const Text(
                  'Include the offer image in the mobile push notification.',
                ),
                value: includeImage,
                onChanged: (value) =>
                    setDialogState(() => includeImage = value),
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
                  offerLineId: request.offerLineId,
                  groupTitle: request.groupTitle,
                  brandName: request.brandName,
                  includeImage: includeImage,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
