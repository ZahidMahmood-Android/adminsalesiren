import '../../offers/domain/entities/offer.dart';
import '../../offers/domain/entities/offer_line.dart';
import '../../../core/utils/display_label_utils.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

class AlertTypeSlugs {
  const AlertTypeSlugs._();

  static const newOffer = 'new_offer';
  static const priceDrop = 'price_drop';
  static const priceUp = 'price_up';
  static const endingSoon = 'ending_soon';
  static const update = 'update';

  static const selectable = [
    newOffer,
    priceDrop,
    priceUp,
    endingSoon,
    update,
  ];
}

String alertTypeLabel(String slug) => DisplayLabelUtils.slug(slug);

/// Classifies a first-time offer notification.
String resolveAlertTypeForOffer(
  Offer offer, {
  List<String>? enabledSlugs,
}) {
  final resolved = _resolveAlertTypeForOffer(offer);
  return clampAlertTypeSlug(resolved, enabledSlugs: enabledSlugs);
}

String _resolveAlertTypeForOffer(Offer offer) {
  if (offer.endDateMode == OfferEndDateModes.fixed && offer.endDate != null) {
    final daysLeft = offer.endDate!.difference(DateTime.now()).inDays;
    if (daysLeft >= 0 && daysLeft <= 3) {
      return AlertTypeSlugs.endingSoon;
    }
  }
  final discount = offer.discountText.toLowerCase();
  if (discount.contains('%') ||
      discount.contains('upto') ||
      discount.contains(' off')) {
    return AlertTypeSlugs.priceDrop;
  }
  return AlertTypeSlugs.newOffer;
}

/// Suggests an alert category when a published offer is edited.
String resolveAlertTypeForOfferChange({
  required Offer? previous,
  required Offer current,
  OfferLine? previousLine,
  required OfferLine currentLine,
  List<String>? enabledSlugs,
}) {
  final resolved = _resolveAlertTypeForOfferChange(
    previous: previous,
    current: current,
    previousLine: previousLine,
    currentLine: currentLine,
  );
  return clampAlertTypeSlug(resolved, enabledSlugs: enabledSlugs);
}

String _resolveAlertTypeForOfferChange({
  required Offer? previous,
  required Offer current,
  OfferLine? previousLine,
  required OfferLine currentLine,
}) {
  if (current.endDateMode == OfferEndDateModes.fixed && current.endDate != null) {
    final daysLeft = current.endDate!.difference(DateTime.now()).inDays;
    if (daysLeft >= 0 && daysLeft <= 3) {
      return AlertTypeSlugs.endingSoon;
    }
  }

  final previousPercent = _discountPercent(
    offer: previous,
    line: previousLine,
  );
  final nextPercent = _discountPercent(offer: current, line: currentLine);
  if (previousPercent != null && nextPercent != null) {
    if (nextPercent > previousPercent) {
      return AlertTypeSlugs.priceDrop;
    }
    if (nextPercent < previousPercent) {
      return AlertTypeSlugs.priceUp;
    }
  }

  if (previous != null) {
    final before = previousLine ??
        (previous.resolvedLines.isNotEmpty ? previous.resolvedLines.first : null);
    if (before != null &&
        (before.discountText.trim() != currentLine.discountText.trim() ||
            before.discountValue != currentLine.discountValue ||
            before.title.trim() != currentLine.title.trim() ||
            before.description.trim() != currentLine.description.trim())) {
      return AlertTypeSlugs.update;
    }
  }

  return _resolveAlertTypeForOffer(current);
}

String clampAlertTypeSlug(
  String slug, {
  List<String>? enabledSlugs,
}) {
  final allowed = (enabledSlugs ?? AlertTypeSlugs.selectable)
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (allowed.isEmpty) {
    return slug;
  }
  if (allowed.contains(slug)) {
    return slug;
  }
  for (final candidate in [
    AlertTypeSlugs.update,
    AlertTypeSlugs.newOffer,
    AlertTypeSlugs.priceDrop,
    AlertTypeSlugs.priceUp,
    AlertTypeSlugs.endingSoon,
    ...allowed,
  ]) {
    if (allowed.contains(candidate)) {
      return candidate;
    }
  }
  return allowed.first;
}

double? _discountPercent({Offer? offer, OfferLine? line}) {
  final value = line?.discountValue ?? offer?.discountValue;
  if (value != null && value > 0) {
    return value.toDouble();
  }

  final text = (line?.discountText ?? offer?.discountText ?? '').toLowerCase();
  final match = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(text);
  if (match != null) {
    return double.tryParse(match.group(1)!);
  }
  return null;
}
