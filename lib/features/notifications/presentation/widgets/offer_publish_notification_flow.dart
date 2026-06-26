import 'package:flutter/material.dart';

import '../../../offers/domain/entities/offer.dart';
import '../../domain/entities/offer_notification_draft.dart';
import 'offer_publish_notification_dialog.dart';

Future<Map<String, OfferNotificationDraft>?> confirmOfferNotificationDrafts(
  BuildContext context,
  Offer offer, {
  Offer? previousOffer,
  String confirmLabel = 'Publish',
  String title = 'Notification preview',
  String subtitle =
      'Review and edit the push notification before publishing this offer.',
  List<String>? selectableAlertTypes,
  Map<String, String>? alertTypeLabels,
  List<String>? enabledSlugs,
}) async {
  final drafts = await showOfferPublishNotificationDialog(
    context,
    drafts: OfferNotificationDraftUtils.defaultsForOffer(
      offer,
      previousOffer: previousOffer,
      enabledSlugs: enabledSlugs,
    ),
    title: title,
    subtitle: subtitle,
    confirmLabel: confirmLabel,
    selectableAlertTypes: selectableAlertTypes,
    alertTypeLabels: alertTypeLabels,
  );
  if (drafts == null) {
    return null;
  }
  return OfferNotificationDraftUtils.draftsByLineId(drafts);
}
