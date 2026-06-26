import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_line.dart';
import '../alert_type_utils.dart';
import 'notification_request.dart';
import 'offer_notification_content_utils.dart';

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

  static List<OfferNotificationDraft> defaultsForOffer(
    Offer offer, {
    Offer? previousOffer,
    List<String>? enabledSlugs,
  }) {
    final imageUrl = primaryImageUrl(offer);
    final hasImage = imageUrl.isNotEmpty;
    return offer.resolvedLines.map((line) {
      OfferLine? previousLine;
      if (previousOffer != null) {
        for (final item in previousOffer.resolvedLines) {
          if (item.id == line.id) {
            previousLine = item;
            break;
          }
        }
        previousLine ??= previousOffer.resolvedLines.isNotEmpty
            ? previousOffer.resolvedLines.first
            : null;
      }
      final alertType = clampAlertTypeSlug(
        previousOffer == null
            ? resolveAlertTypeForOffer(
                offer.copyWith(discountText: line.discountText),
                enabledSlugs: enabledSlugs,
              )
            : resolveAlertTypeForOfferChange(
                previous: previousOffer,
                current: offer,
                previousLine: previousLine,
                currentLine: line,
                enabledSlugs: enabledSlugs,
              ),
        enabledSlugs: enabledSlugs,
      );
      return OfferNotificationDraft(
        offerLineId: line.id,
        title: OfferNotificationContentUtils.suggestedTitle(offer, line),
        body: OfferNotificationContentUtils.suggestedBody(offer),
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
        : primaryImageUrl(offer);
    final suggestedBody = OfferNotificationContentUtils.suggestedBody(offer);
    return OfferNotificationDraft(
      offerLineId: request.offerLineId.isNotEmpty ? request.offerLineId : line.id,
      title: OfferNotificationContentUtils.suggestedTitle(offer, line),
      body: suggestedBody.isNotEmpty ? suggestedBody : request.body,
      includeImage: request.includeImage && imageUrl.isNotEmpty,
      imageUrl: imageUrl,
      lineLabel: request.groupTitle.isNotEmpty
          ? request.groupTitle
          : (offer.isGroupOffer ? line.displayTitle(line.categoryName) : ''),
      alertType: request.type.isNotEmpty ? request.type : request.data['type'] ?? AlertTypeSlugs.newOffer,
    );
  }

  static OfferNotificationDraft fromNotificationRequest(
    NotificationRequest request,
  ) {
    final imageUrl = request.data['imageUrl']?.trim() ?? '';
    return OfferNotificationDraft(
      offerLineId: request.offerLineId,
      title: request.title,
      body: request.body,
      includeImage: request.includeImage,
      imageUrl: imageUrl,
      lineLabel: request.groupTitle,
      alertType: request.type.isNotEmpty ? request.type : request.data['type'] ?? AlertTypeSlugs.newOffer,
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
}
