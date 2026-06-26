import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_line.dart';

class OfferNotificationContentUtils {
  OfferNotificationContentUtils._();

  /// `{brandName}: {discountText}`
  static String suggestedTitle(Offer offer, OfferLine line) {
    final brand = offer.brandName.trim();
    final discount = _discountText(offer, line);

    if (brand.isEmpty && discount.isEmpty) {
      return 'New offer';
    }
    if (brand.isEmpty) {
      return discount;
    }
    if (discount.isEmpty) {
      return brand;
    }
    return '$brand: $discount';
  }

  /// `{offerTitle}. {offerDescription}` on one line (period added if missing).
  static String suggestedBody(Offer offer) {
    final title = offer.title.trim();
    final description = offer.description.trim();

    if (title.isEmpty && description.isEmpty) {
      return '';
    }
    if (title.isEmpty) {
      return description;
    }
    if (description.isEmpty) {
      return title;
    }

    final separator = title.endsWith('.') ? ' ' : '. ';
    return '$title$separator$description';
  }

  static String _discountText(Offer offer, OfferLine line) {
    final lineDiscount = line.discountText.trim();
    if (lineDiscount.isNotEmpty) {
      return lineDiscount;
    }
    return offer.discountText.trim();
  }
}
