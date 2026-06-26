import '../../offers/domain/entities/offer.dart';
import '../../offers/domain/entities/offer_line.dart';

class OfferEditNotificationUtils {
  const OfferEditNotificationUtils._();

  static bool hasNotifiableChange({
    required Offer previous,
    required Offer next,
  }) {
    if (!previous.isPublished || !next.isPublished) {
      return false;
    }

    final previousLines = previous.resolvedLines;
    final nextLines = next.resolvedLines;
    if (previousLines.length != nextLines.length) {
      return true;
    }

    for (var index = 0; index < nextLines.length; index++) {
      final before = previousLines[index];
      final after = nextLines[index];
      if (_lineChanged(before, after)) {
        return true;
      }
    }

    return previous.title.trim() != next.title.trim() ||
        previous.description.trim() != next.description.trim() ||
        previous.discountText.trim() != next.discountText.trim() ||
        previous.discountValue != next.discountValue ||
        previous.endDate != next.endDate;
  }

  static bool _lineChanged(OfferLine before, OfferLine after) {
    return before.discountText.trim() != after.discountText.trim() ||
        before.discountValue != after.discountValue ||
        before.discountType != after.discountType ||
        before.title.trim() != after.title.trim() ||
        before.description.trim() != after.description.trim() ||
        before.categoryId != after.categoryId;
  }
}
