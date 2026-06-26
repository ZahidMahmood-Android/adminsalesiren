import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/push_dispatch_user_messages.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../domain/entities/notification_request.dart';
import '../providers/notification_providers.dart';
import 'notification_request_draft_flow.dart';

enum NotificationPublishMode { withNotification, withoutNotification }

enum NotificationPublishButtonStyle { publishAll, single }

extension NotificationPublishModeX on NotificationPublishMode {
  bool get sendNotification => this == NotificationPublishMode.withNotification;

  String buttonLabel({required NotificationPublishButtonStyle style}) {
    if (style == NotificationPublishButtonStyle.publishAll) {
      return sendNotification
          ? 'Publish all with notification'
          : 'Publish all without notification';
    }
    return sendNotification
        ? 'Publish with notification'
        : 'Publish without notification';
  }

  String confirmTitle({String? brandName, int? count}) {
    final scope = brandName == null
        ? 'all pending requests'
        : 'pending requests for $brandName';
    final countLabel = count == null ? '' : ' ($count)';
    return sendNotification
        ? 'Publish$countLabel $scope with notification?'
        : 'Publish$countLabel $scope without notification?';
  }

  String confirmMessage({String? brandName}) {
    if (sendNotification) {
      if (brandName == null) {
        return 'Every pending offer linked to a notification request will be '
            'published and a push notification will be sent to mobile users.';
      }
      return 'Every pending offer for $brandName will be published and a push '
          'notification will be sent to mobile users.';
    }
    if (brandName == null) {
      return 'Every pending offer linked to a notification request will be '
          'published live without sending a push notification.';
    }
    return 'Every pending offer for $brandName will be published live without '
        'sending a push notification.';
  }

  String successMessage({String? brandName}) {
    if (brandName == null) {
      return sendNotification
          ? 'Pending notification requests published with push notifications.'
          : 'Pending offers published without push notifications.';
    }
    return sendNotification
        ? 'Pending requests for $brandName published with push notifications.'
        : 'Pending offers for $brandName published without push notifications.';
  }

  String tileConfirmTitle() => sendNotification
      ? 'Publish with notification?'
      : 'Publish without notification?';

  String tileConfirmMessage(NotificationRequest request) {
    if (sendNotification) {
      return request.offerLineId.isNotEmpty
          ? 'This will publish this offer line and send its push notification.'
          : 'This will publish the offer and send its push notification.';
    }
    return request.offerLineId.isNotEmpty
        ? 'This will publish this offer line without sending a push notification.'
        : 'This will publish the offer without sending a push notification.';
  }

  String tileSuccessMessage(NotificationRequest request) {
    if (!sendNotification) {
      return request.offerId.isNotEmpty
          ? 'Offer published without push notification.'
          : 'Notification request approved.';
    }
    return request.offerId.isNotEmpty
        ? 'Offer published and push notification sent.'
        : 'Notification request approved.';
  }
}

Future<bool> confirmNotificationPublish(
  BuildContext context, {
  required NotificationPublishMode mode,
  String? brandName,
  int? count,
}) {
  return showSweetConfirmationDialog(
    context: context,
    title: mode.confirmTitle(brandName: brandName, count: count),
    message: mode.confirmMessage(brandName: brandName),
    confirmLabel: mode.sendNotification ? 'Publish' : 'Publish without notify',
    icon: mode.sendNotification
        ? Icons.campaign_outlined
        : Icons.publish_outlined,
  );
}

Future<void> publishAllPendingRequests(
  BuildContext context,
  WidgetRef ref, {
  required NotificationPublishMode mode,
}) async {
  final confirmed = await confirmNotificationPublish(context, mode: mode);
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(notificationRequestActionsProvider.notifier)
        .publishAllPending(sendNotification: mode.sendNotification);
    if (!context.mounted) {
      return;
    }
    final error = ref.read(notificationRequestActionsProvider).error;
    if (error != null) {
      await showNotificationDispatchError(context, error);
      return;
    }
    showAppSuccess(context, mode.successMessage());
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await showNotificationDispatchError(context, error);
  }
}

Future<void> publishBrandPendingRequests(
  BuildContext context,
  WidgetRef ref, {
  required NotificationPublishMode mode,
  required String brandName,
  required List<NotificationRequest> requests,
}) async {
  final pendingCount = requests
      .where(
        (request) => request.status == 'pending' && request.offerId.isNotEmpty,
      )
      .length;
  if (pendingCount == 0) {
    return;
  }
  final confirmed = await confirmNotificationPublish(
    context,
    mode: mode,
    brandName: brandName,
    count: pendingCount,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(notificationRequestActionsProvider.notifier)
        .publishPendingRequests(
          requests,
          sendNotification: mode.sendNotification,
        );
    if (!context.mounted) {
      return;
    }
    final error = ref.read(notificationRequestActionsProvider).error;
    if (error != null) {
      await showNotificationDispatchError(context, error);
      return;
    }
    showAppSuccess(context, mode.successMessage(brandName: brandName));
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await showNotificationDispatchError(context, error);
  }
}

Future<void> publishSingleNotificationRequest(
  BuildContext context,
  WidgetRef ref, {
  required NotificationRequest request,
  required NotificationPublishMode mode,
}) async {
  final draftList = await confirmNotificationRequestDrafts(
    context,
    ref,
    request: request,
    title: 'Notification preview',
    subtitle: mode.sendNotification
        ? 'Review and edit the push notification before publishing this offer.'
        : 'Review the notification details before publishing without push.',
    confirmLabel: mode.sendNotification ? 'Publish' : 'Publish without notify',
  );
  if (draftList == null || draftList.isEmpty || !context.mounted) {
    return;
  }
  final draft = draftList.first;
  final updatedRequest = notificationRequestFromDraft(request, draft);
  try {
    await ref
        .read(notificationRequestActionsProvider.notifier)
        .saveRequest(updatedRequest);
    if (request.offerId.isNotEmpty) {
      await ref.read(notificationRequestActionsProvider.notifier).publishRequest(
            requestId: request.id,
            offerId: request.offerId,
            offerLineId: request.offerLineId,
            sendNotification: mode.sendNotification,
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
    showAppSuccess(context, mode.tileSuccessMessage(request));
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await showNotificationDispatchError(context, error);
  }
}

Widget notificationPublishModeButtons({
  required bool enabled,
  required bool hasPending,
  required void Function(NotificationPublishMode mode) onPublish,
  NotificationPublishButtonStyle style = NotificationPublishButtonStyle.publishAll,
}) {
  if (!hasPending) {
    return const SizedBox.shrink();
  }

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FilledButton.tonalIcon(
        onPressed: enabled
            ? () => onPublish(NotificationPublishMode.withNotification)
            : null,
        icon: const Icon(Icons.campaign_outlined, size: 18),
        label: Text(
          NotificationPublishMode.withNotification.buttonLabel(style: style),
        ),
      ),
      OutlinedButton.icon(
        onPressed: enabled
            ? () => onPublish(NotificationPublishMode.withoutNotification)
            : null,
        icon: const Icon(Icons.publish_outlined, size: 18),
        label: Text(
          NotificationPublishMode.withoutNotification.buttonLabel(style: style),
        ),
      ),
    ],
  );
}

Widget notificationSinglePublishPanel({
  required bool enabled,
  required void Function(NotificationPublishMode mode) onPublish,
}) {
  return NotificationSinglePublishControl(
    enabled: enabled,
    onPublish: onPublish,
  );
}

class NotificationSinglePublishControl extends StatefulWidget {
  const NotificationSinglePublishControl({
    required this.enabled,
    required this.onPublish,
    super.key,
  });

  final bool enabled;
  final void Function(NotificationPublishMode mode) onPublish;

  @override
  State<NotificationSinglePublishControl> createState() =>
      _NotificationSinglePublishControlState();
}

class _NotificationSinglePublishControlState
    extends State<NotificationSinglePublishControl> {
  NotificationPublishMode _mode = NotificationPublishMode.withNotification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final segmented = SegmentedButton<NotificationPublishMode>(
      segments: const [
        ButtonSegment<NotificationPublishMode>(
          value: NotificationPublishMode.withNotification,
          icon: Icon(Icons.campaign_outlined, size: 17),
          label: Text('With'),
          tooltip: 'Publish with notification',
        ),
        ButtonSegment<NotificationPublishMode>(
          value: NotificationPublishMode.withoutNotification,
          icon: Icon(Icons.publish_outlined, size: 17),
          label: Text('Without'),
          tooltip: 'Publish without notification',
        ),
      ],
      selected: {_mode},
      showSelectedIcon: false,
      onSelectionChanged: widget.enabled
          ? (selection) => setState(() => _mode = selection.first)
          : null,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );

    final publishButton = FilledButton.icon(
      onPressed: widget.enabled ? () => widget.onPublish(_mode) : null,
      icon: const Icon(Icons.rocket_launch_outlined, size: 18),
      label: const Text('Publish'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final modeHint = _mode == NotificationPublishMode.withNotification
              ? 'Publish with notification'
              : 'Publish without notification';

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  modeHint,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 8),
                segmented,
                const SizedBox(height: 8),
                publishButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: segmented),
              const SizedBox(width: 10),
              publishButton,
            ],
          );
        },
      ),
    );
  }
}
