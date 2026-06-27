import 'package:flutter/material.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

import '../../../offers/domain/entities/offer.dart';
import '../../domain/entities/offer_notification_draft.dart';
import 'offer_publish_notification_dialog.dart';

Future<Map<String, OfferNotificationDraft>?> confirmOfferNotificationDrafts(
  BuildContext context,
  Offer offer, {
  Offer? previousOffer,
  String confirmLabel = 'Publish',
  String title = 'Notification preview',
  String? subtitle,
  Map<String, String>? alertTypeLabels,
  List<String>? enabledSlugs,
}) async {
  final drafts = await showOfferPublishNotificationDialog(
    context,
    drafts: OfferNotificationDraftUtils.defaultsForOffer(
      offer,
      previousOffer: previousOffer,
      enabledSlugs: enabledSlugs,
      storedSnapshot: OfferNotificationSnapshot.fromMap(
        offer.notificationSnapshot,
      ),
    ),
    title: title,
    subtitle:
        subtitle ??
        'Review the push notification before publishing. Alert category is calculated automatically from the offer.',
    confirmLabel: confirmLabel,
    alertTypeLabels: alertTypeLabels,
  );
  if (drafts == null) {
    return null;
  }
  return OfferNotificationDraftUtils.draftsByLineId(drafts);
}
