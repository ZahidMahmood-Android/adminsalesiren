import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_line.dart';
import '../alert_type_utils.dart';
import '../offer_alert_input_mapper.dart';
import 'notification_request.dart';
import 'offer_notification_content_utils.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

class OfferNotificationDraft {
  const OfferNotificationDraft({
    required this.offerLineId,
    required this.title,
    required this.body,
    required this.includeImage,
    this.imageUrl = '',
    this.lineLabel = '',
    this.alertType = AlertTypeSlugs.newOffer,
  });

  final String offerLineId;
  final String title;
  final String body;
  final bool includeImage;
  final String imageUrl;
  final String lineLabel;
  final String alertType;

  OfferNotificationDraft copyWith({
    String? offerLineId,
    String? title,
    String? body,
    bool? includeImage,
    String? imageUrl,
    String? lineLabel,
    String? alertType,
  }) {
    return OfferNotificationDraft(
      offerLineId: offerLineId ?? this.offerLineId,
      title: title ?? this.title,
      body: body ?? this.body,
      includeImage: includeImage ?? this.includeImage,
      imageUrl: imageUrl ?? this.imageUrl,
      lineLabel: lineLabel ?? this.lineLabel,
      alertType: alertType ?? this.alertType,
    );
  }
}

class OfferNotificationDraftUtils {
  OfferNotificationDraftUtils._();

  static String primaryImageUrl(Offer offer) {
    final urls = offer.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isNotEmpty) {
      return urls.first;
    }
    return offer.imageUrl.trim();
  }

  static String primaryImageUrlForLine(Offer offer, OfferLine line) {
    final lineUrls = line.resolvedImageUrls();
    if (lineUrls.isNotEmpty) {
      return lineUrls.first.trim();
    }
    return primaryImageUrl(offer);
  }

  static List<OfferNotificationDraft> defaultsForOffer(
    Offer offer, {
    Offer? previousOffer,
    List<String>? enabledSlugs,
    OfferNotificationSnapshot? storedSnapshot,
  }) {
    return offer.resolvedLines.map((line) {
      final alertType = OfferAlertInputMapper.resolveAlertType(
        offer: offer,
        line: line,
        previousOffer: previousOffer,
        storedSnapshot: storedSnapshot ?? _storedSnapshot(offer),
        enabledSlugs: enabledSlugs,
      );
      final imageUrl = primaryImageUrlForLine(offer, line);
      final hasImage = imageUrl.isNotEmpty;
      return OfferNotificationDraft(
        offerLineId: line.id,
        title: OfferNotificationContentUtils.suggestedTitle(
          offer,
          line,
          alertType: alertType,
        ),
        body: OfferNotificationContentUtils.suggestedBody(
          offer,
          alertType: alertType,
        ),
        includeImage: hasImage,
        imageUrl: imageUrl,
        lineLabel: offer.isGroupOffer
            ? line.displayTitle(line.categoryName)
            : '',
        alertType: alertType,
      );
    }).toList();
  }

  static OfferLine lineForRequest(Offer offer, NotificationRequest request) {
    if (request.offerLineId.isNotEmpty) {
      for (final line in offer.resolvedLines) {
        if (line.id == request.offerLineId) {
          return line;
        }
      }
    }
    final lines = offer.resolvedLines;
    if (lines.isEmpty) {
      return OfferLine(
        id: request.offerLineId,
        categoryId: offer.categoryId,
        categoryName: offer.categoryName,
        discountText: offer.discountText,
        discountType: offer.discountType,
        discountValue: offer.discountValue,
        imageUrl: offer.imageUrl,
        imageUrls: offer.imageUrls,
      );
    }
    return lines.first;
  }

  static OfferNotificationDraft draftForExistingRequest(
    NotificationRequest request,
    Offer offer,
  ) {
    final line = lineForRequest(offer, request);
    final imageUrl = request.data['imageUrl']?.trim().isNotEmpty == true
        ? request.data['imageUrl']!.trim()
        : primaryImageUrlForLine(offer, line);
    final alertType = OfferAlertInputMapper.resolveAlertType(
      offer: offer,
      line: line,
      storedSnapshot: _storedSnapshot(offer),
    );
    return OfferNotificationDraft(
      offerLineId: request.offerLineId.isNotEmpty
          ? request.offerLineId
          : line.id,
      title: OfferNotificationContentUtils.suggestedTitle(
        offer,
        line,
        alertType: alertType,
      ),
      body: OfferNotificationContentUtils.suggestedBody(
        offer,
        alertType: alertType,
      ),
      includeImage: request.includeImage && imageUrl.isNotEmpty,
      imageUrl: imageUrl,
      lineLabel: request.groupTitle.isNotEmpty
          ? request.groupTitle
          : (offer.isGroupOffer ? line.displayTitle(line.categoryName) : ''),
      alertType: alertType,
    );
  }

  static OfferNotificationDraft fromNotificationRequest(
    NotificationRequest request,
  ) {
    final imageUrl = request.data['imageUrl']?.trim() ?? '';
    final alertType = request.type.isNotEmpty
        ? request.type
        : request.data['type'] ?? AlertTypeSlugs.newOffer;
    return OfferNotificationDraft(
      offerLineId: request.offerLineId,
      title: request.title,
      body: request.body,
      includeImage: request.includeImage,
      imageUrl: imageUrl,
      lineLabel: request.groupTitle,
      alertType: alertType,
    );
  }

  static Map<String, OfferNotificationDraft> draftsByLineId(
    List<OfferNotificationDraft> drafts,
  ) {
    return {
      for (final draft in drafts)
        if (draft.offerLineId.isNotEmpty) draft.offerLineId: draft,
    };
  }

  static OfferNotificationDraft? draftForLine(
    OfferLine line,
    Map<String, OfferNotificationDraft>? draftsByLineId,
  ) {
    if (draftsByLineId == null || draftsByLineId.isEmpty) {
      return null;
    }
    return draftsByLineId[line.id] ??
        (draftsByLineId.length == 1 ? draftsByLineId.values.first : null);
  }

  static OfferNotificationSnapshot? _storedSnapshot(Offer offer) {
    final raw = offer.notificationSnapshot;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return OfferNotificationSnapshot.fromMap(raw);
  }
}
