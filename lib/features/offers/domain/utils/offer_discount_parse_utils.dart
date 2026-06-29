import 'package:sale_siren_models/sale_siren_models.dart';

class ParsedOfferDiscount {
  const ParsedOfferDiscount({
    required this.discountText,
    required this.discountType,
    this.discountValue,
  });

  final String discountText;
  final String discountType;
  final int? discountValue;
}

class OfferDiscountParseUtils {
  const OfferDiscountParseUtils._();

  static ParsedOfferDiscount resolve({
    required String discountText,
    String discountType = '',
    num? discountValue,
  }) {
    final text = discountText.trim();
    final hasValue = discountValue != null;
    final normalizedType = discountType.trim();
    if (hasValue &&
        normalizedType.isNotEmpty &&
        OfferDiscountType.all.contains(normalizedType)) {
      return ParsedOfferDiscount(
        discountText: text,
        discountType: normalizedType,
        discountValue: discountValue!.round(),
      );
    }

    final parsed = parseFromText(text);
    if (parsed.discountValue != null) {
      return parsed;
    }

    if (text.isNotEmpty) {
      return ParsedOfferDiscount(
        discountText: text,
        discountType: OfferDiscountType.other,
        discountValue: null,
      );
    }

    return const ParsedOfferDiscount(
      discountText: '',
      discountType: OfferDiscountType.percentage,
      discountValue: null,
    );
  }

  static ParsedOfferDiscount parseFromText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const ParsedOfferDiscount(
        discountText: '',
        discountType: OfferDiscountType.percentage,
        discountValue: null,
      );
    }

    final upToPct = RegExp(
      r'up\s*to\s*(\d[\d,]*)\s*%',
      caseSensitive: false,
    ).firstMatch(text);
    if (upToPct != null) {
      final value = _readInt(upToPct.group(1));
      if (value != null) {
        return ParsedOfferDiscount(
          discountText: 'Up to $value% off',
          discountType: OfferDiscountType.uptoPercentage,
          discountValue: value,
        );
      }
    }

    final upToAmount = RegExp(
      r'up\s*to\s*(?:rs\.?|pkr|₨)\s*(\d[\d,]*)',
      caseSensitive: false,
    ).firstMatch(text);
    if (upToAmount != null) {
      final value = _readInt(upToAmount.group(1));
      if (value != null) {
        return ParsedOfferDiscount(
          discountText: 'Up to Rs. $value off',
          discountType: OfferDiscountType.uptoAmount,
          discountValue: value,
        );
      }
    }

    final flatPct = RegExp(
      r'flat\s*(\d[\d,]*)\s*%',
      caseSensitive: false,
    ).firstMatch(text);
    if (flatPct != null) {
      final value = _readInt(flatPct.group(1));
      if (value != null) {
        return ParsedOfferDiscount(
          discountText: '$value% off',
          discountType: OfferDiscountType.percentage,
          discountValue: value,
        );
      }
    }

    final flatAmount = RegExp(
      r'flat\s*(?:rs\.?|pkr|₨)?\s*(\d[\d,]*)\s*off',
      caseSensitive: false,
    ).firstMatch(text);
    if (flatAmount != null) {
      final value = _readInt(flatAmount.group(1));
      if (value != null) {
        return ParsedOfferDiscount(
          discountText: 'Rs. $value off',
          discountType: OfferDiscountType.flat,
          discountValue: value,
        );
      }
    }

    final pct = RegExp(r'(\d[\d,]*)\s*%', caseSensitive: false).firstMatch(text);
    if (pct != null) {
      final value = _readInt(pct.group(1));
      if (value != null) {
        return ParsedOfferDiscount(
          discountText: '$value% off',
          discountType: OfferDiscountType.percentage,
          discountValue: value,
        );
      }
    }

    final flat = RegExp(
      r'(?:rs\.?|pkr|₨)\s*(\d[\d,]*)\s*(?:off|discount)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (flat != null) {
      final value = _readInt(flat.group(1));
      if (value != null) {
        return ParsedOfferDiscount(
          discountText: 'Rs. $value off',
          discountType: OfferDiscountType.flat,
          discountValue: value,
        );
      }
    }

    final saveAmount = RegExp(
      r'(?:save|get)\s*(?:rs\.?|pkr|₨)?\s*(\d[\d,]*)\s*(?:off|discount)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (saveAmount != null) {
      final value = _readInt(saveAmount.group(1));
      if (value != null) {
        return ParsedOfferDiscount(
          discountText: 'Rs. $value off',
          discountType: OfferDiscountType.flat,
          discountValue: value,
        );
      }
    }

    if (RegExp(r'\bbundle\b', caseSensitive: false).hasMatch(text)) {
      return ParsedOfferDiscount(
        discountText: text,
        discountType: OfferDiscountType.bundle,
        discountValue: null,
      );
    }

    return ParsedOfferDiscount(
      discountText: text,
      discountType: OfferDiscountType.other,
      discountValue: null,
    );
  }

  static int? _readInt(String? raw) {
    if (raw == null) {
      return null;
    }
    return int.tryParse(raw.replaceAll(',', '').trim());
  }
}
