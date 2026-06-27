import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_line.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

class OfferNotificationContentUtils {
  OfferNotificationContentUtils._();

  static String suggestedTitle(
    Offer offer,
    OfferLine line, {
    required String alertType,
  }) {
    return OfferNotificationCopy.title(
      alertType: alertType,
      brandName: offer.brandName,
    );
  }

  static String suggestedBody(Offer offer, {required String alertType}) {
    return OfferNotificationCopy.body(
      alertType: alertType,
      offerTitle: offer.title,
    );
  }
}
