import '../../../core/utils/display_label_utils.dart';
import '../../offers/domain/entities/offer.dart';
import '../../offers/domain/entities/offer_line.dart';
import 'offer_alert_input_mapper.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

class AlertTypeSlugs {
  const AlertTypeSlugs._();

  static const newOffer = OfferAlertTypeSlugs.newOffer;
  static const priceDrop = OfferAlertTypeSlugs.priceDrop;
  static const priceUp = OfferAlertTypeSlugs.priceUp;
  static const endingSoon = OfferAlertTypeSlugs.endingSoon;
  static const update = OfferAlertTypeSlugs.update;

  static const selectable = OfferAlertTypeSlugs.all;
}

String alertTypeLabel(String slug) => DisplayLabelUtils.slug(slug);

String resolveAlertTypeForOffer(
  Offer offer, {
  List<String>? enabledSlugs,
  OfferLine? line,
}) {
  final resolvedLine = line ?? offer.resolvedLines.first;
  return OfferAlertInputMapper.resolveAlertType(
    offer: offer,
    line: resolvedLine,
    enabledSlugs: enabledSlugs,
  );
}

String resolveAlertTypeForOfferChange({
  required Offer? previous,
  required Offer current,
  OfferLine? previousLine,
  required OfferLine currentLine,
  List<String>? enabledSlugs,
  OfferNotificationSnapshot? storedSnapshot,
}) {
  return OfferAlertInputMapper.resolveAlertType(
    offer: current,
    line: currentLine,
    previousOffer: previous,
    storedSnapshot: storedSnapshot,
    enabledSlugs: enabledSlugs,
  );
}

String clampAlertTypeSlug(String slug, {List<String>? enabledSlugs}) {
  return clampOfferAlertType(slug, enabledSlugs: enabledSlugs);
}
