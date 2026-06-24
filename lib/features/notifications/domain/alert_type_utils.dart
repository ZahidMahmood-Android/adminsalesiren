import '../../offers/domain/entities/offer.dart';
import '../../../core/utils/display_label_utils.dart';

class AlertTypeSlugs {
  const AlertTypeSlugs._();

  static const newOffer = 'new_offer';
  static const priceDrop = 'price_drop';
  static const endingSoon = 'ending_soon';
  static const update = 'update';
}

String alertTypeLabel(String slug) => DisplayLabelUtils.slug(slug);

/// Classifies an offer notification into a persisted alert type slug.
String resolveAlertTypeForOffer(Offer offer) {
  final daysLeft = offer.endDate.difference(DateTime.now()).inDays;
  if (daysLeft >= 0 && daysLeft <= 3) {
    return AlertTypeSlugs.endingSoon;
  }
  final discount = offer.discountText.toLowerCase();
  if (discount.contains('%') ||
      discount.contains('upto') ||
      discount.contains(' off')) {
    return AlertTypeSlugs.priceDrop;
  }
  return AlertTypeSlugs.newOffer;
}
