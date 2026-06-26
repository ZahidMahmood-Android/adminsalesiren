import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../offers/presentation/providers/offer_providers.dart';
import '../../domain/entities/notification_request.dart';
import '../../domain/entities/offer_notification_draft.dart';
import 'offer_publish_notification_dialog.dart';

Future<OfferNotificationDraft> resolveNotificationDraftForRequest(
  WidgetRef ref,
  NotificationRequest request,
) async {
  if (request.offerId.isEmpty) {
    return OfferNotificationDraftUtils.fromNotificationRequest(request);
  }

  final offer = await ref.read(offersRepositoryProvider).getOffer(request.offerId);
  if (offer == null) {
    return OfferNotificationDraftUtils.fromNotificationRequest(request);
  }

  return OfferNotificationDraftUtils.draftForExistingRequest(request, offer);
}

Future<List<OfferNotificationDraft>?> confirmNotificationRequestDrafts(
  BuildContext context,
  WidgetRef ref, {
  required NotificationRequest request,
  required String confirmLabel,
  String title = 'Notification preview',
  String? subtitle,
}) {
  return _showNotificationRequestDialog(
    context,
    ref,
    request: request,
    title: title,
    subtitle: subtitle ??
        'Review and edit the push notification before publishing this offer.',
    confirmLabel: confirmLabel,
  );
}

Future<NotificationRequest?> editNotificationRequestWithOffer(
  BuildContext context,
  WidgetRef ref,
  NotificationRequest request,
) async {
  final drafts = await _showNotificationRequestDialog(
    context,
    ref,
    request: request,
    title: 'Edit notification request',
    subtitle:
        'Update the push notification title, message, and image option.',
    confirmLabel: 'Save',
  );
  if (drafts == null || drafts.isEmpty) {
    return null;
  }
  return _notificationRequestFromDraft(request, drafts.first);
}

Future<List<OfferNotificationDraft>?> _showNotificationRequestDialog(
  BuildContext context,
  WidgetRef ref, {
  required NotificationRequest request,
  required String title,
  required String subtitle,
  required String confirmLabel,
}) async {
  final draft = await resolveNotificationDraftForRequest(ref, request);
  if (!context.mounted) {
    return null;
  }
  return showOfferPublishNotificationDialog(
    context,
    drafts: [draft],
    title: title,
    subtitle: subtitle,
    confirmLabel: confirmLabel,
  );
}

NotificationRequest notificationRequestFromDraft(
  NotificationRequest request,
  OfferNotificationDraft draft,
) {
  return _notificationRequestFromDraft(request, draft);
}

NotificationRequest _notificationRequestFromDraft(
  NotificationRequest request,
  OfferNotificationDraft draft,
) {
  return NotificationRequest(
    id: request.id,
    title: draft.title,
    body: draft.body,
    topic: request.topic,
    type: request.type,
    data: {
      ...request.data,
      'includeImage': draft.includeImage ? 'true' : 'false',
    },
    status: request.status,
    createdAt: request.createdAt,
    brandId: request.brandId,
    brandName: request.brandName,
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
    includeImage: draft.includeImage,
  );
}
