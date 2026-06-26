import '../../../notifications/domain/alert_type_utils.dart';

class AlertTypeSetting {
  const AlertTypeSetting({
    required this.slug,
    required this.label,
    required this.enabled,
    this.builtIn = false,
  });

  final String slug;
  final String label;
  final bool enabled;
  final bool builtIn;

  AlertTypeSetting copyWith({
    String? slug,
    String? label,
    bool? enabled,
    bool? builtIn,
  }) {
    return AlertTypeSetting(
      slug: slug ?? this.slug,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      builtIn: builtIn ?? this.builtIn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'label': label,
      'enabled': enabled,
      'builtIn': builtIn,
    };
  }

  factory AlertTypeSetting.fromMap(Map<String, dynamic> map) {
    return AlertTypeSetting(
      slug: (map['slug'] as String? ?? '').trim(),
      label: (map['label'] as String? ?? '').trim(),
      enabled: map['enabled'] as bool? ?? true,
      builtIn: map['builtIn'] as bool? ?? false,
    );
  }
}

class MobileAlertSettings {
  const MobileAlertSettings({required this.types});

  static const docId = 'mobile_alerts';

  final List<AlertTypeSetting> types;

  static MobileAlertSettings defaults() {
    return MobileAlertSettings(
      types: [
        for (final slug in AlertTypeSlugs.selectable)
          AlertTypeSetting(
            slug: slug,
            label: alertTypeLabel(slug),
            enabled: true,
            builtIn: true,
          ),
      ],
    );
  }

  List<String> get enabledSlugs =>
      types.where((type) => type.enabled).map((type) => type.slug).toList();

  List<AlertTypeSetting> get enabledTypes =>
      types.where((type) => type.enabled).toList();

  String labelFor(String slug) {
    for (final type in types) {
      if (type.slug == slug && type.label.isNotEmpty) {
        return type.label;
      }
    }
    return alertTypeLabel(slug);
  }

  String clampSlug(String slug) {
    final allowed = enabledSlugs;
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

  factory MobileAlertSettings.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return defaults();
    }
    final raw = data['types'];
    if (raw is! Iterable) {
      return defaults();
    }
    final parsed = raw
        .whereType<Map>()
        .map((item) => AlertTypeSetting.fromMap(Map<String, dynamic>.from(item)))
        .where((type) => type.slug.isNotEmpty)
        .toList();
    if (parsed.isEmpty) {
      return defaults();
    }
    final merged = _mergeWithBuiltIns(parsed);
    if (merged.every((type) => !type.enabled)) {
      return defaults();
    }
    return MobileAlertSettings(types: merged);
  }

  static List<AlertTypeSetting> _mergeWithBuiltIns(
    List<AlertTypeSetting> saved,
  ) {
    final bySlug = {for (final type in saved) type.slug: type};
    final merged = <AlertTypeSetting>[];
    for (final slug in AlertTypeSlugs.selectable) {
      merged.add(
        bySlug.remove(slug) ??
            AlertTypeSetting(
              slug: slug,
              label: alertTypeLabel(slug),
              enabled: true,
              builtIn: true,
            ),
      );
    }
    merged.addAll(
      bySlug.values.map(
        (type) => type.copyWith(builtIn: false),
      ),
    );
    return merged;
  }

  List<Map<String, dynamic>> toFirestoreTypes() {
    return types.map((type) => type.toMap()).toList();
  }
}

String normalizeAlertTypeSlug(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

bool isValidAlertTypeSlug(String slug) {
  return RegExp(r'^[a-z][a-z0-9_]{1,39}$').hasMatch(slug);
}
