import '../../offers/domain/entities/offer.dart';
import '../../offers/domain/entities/offer_line.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

class OfferAlertInputMapper {
  const OfferAlertInputMapper._();

  static OfferAlertInput fromOfferLine(
    Offer offer,
    OfferLine line, {
    bool wasPublished = false,
  }) {
    final lineDiscount = line.discountText.trim().isNotEmpty
        ? line.discountText.trim()
        : offer.discountText.trim();
    final lineDiscountValue = line.discountValue ?? offer.discountValue;
    final lineDiscountType = line.discountType.trim().isNotEmpty
        ? line.discountType.trim()
        : offer.discountType.trim();

    return OfferAlertInput(
      publishedAt: offer.approvedAt,
      createdAt: offer.createdAt,
      endDate: offer.endDate,
      endDateMode: offer.endDateMode,
      title: offer.title,
      description: offer.description,
      discountText: lineDiscount,
      discountValue: _toDouble(lineDiscountValue),
      discountType: lineDiscountType,
      wasPublished: wasPublished || offer.isPublished,
      line: OfferAlertLineInput(
        id: line.id,
        title: line.title,
        description: line.description,
        discountText: line.discountText,
        discountValue: _toDouble(line.discountValue),
        discountType: line.discountType,
      ),
    );
  }

  static OfferAlertInput? previousInput({
    Offer? previousOffer,
    OfferNotificationSnapshot? storedSnapshot,
    required OfferLine line,
  }) {
    if (previousOffer != null) {
      return fromOfferLine(previousOffer, line, wasPublished: true);
    }
    return storedSnapshot?.toAlertInput(lineId: line.id);
  }

  static OfferNotificationSnapshot snapshotFromOffer(Offer offer) {
    return OfferNotificationSnapshot(
      capturedAt: DateTime.now(),
      title: offer.title,
      description: offer.description,
      discountText: offer.discountText,
      discountValue: _toDouble(offer.discountValue),
      discountType: offer.discountType,
      endDate: offer.endDate,
      endDateMode: offer.endDateMode,
      lines: [
        for (final line in offer.resolvedLines)
          OfferNotificationLineSnapshot(
            id: line.id,
            title: line.title,
            description: line.description,
            discountText: line.discountText,
            discountValue: _toDouble(line.discountValue),
            discountType: line.discountType,
          ),
      ],
    );
  }

  static String resolveAlertType({
    required Offer offer,
    required OfferLine line,
    Offer? previousOffer,
    OfferNotificationSnapshot? storedSnapshot,
    List<String>? enabledSlugs,
    DateTime? now,
  }) {
    final current = fromOfferLine(offer, line, wasPublished: offer.isPublished);
    final previous = previousInput(
      previousOffer: previousOffer,
      storedSnapshot: storedSnapshot,
      line: line,
    );
    return calculateOfferAlertType(
      current: current,
      previous: previous,
      now: now,
      enabledSlugs: enabledSlugs,
    );
  }

  static double? _toDouble(num? value) {
    return value?.toDouble();
  }
}
