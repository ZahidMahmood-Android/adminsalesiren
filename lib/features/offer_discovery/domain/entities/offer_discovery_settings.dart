class OfferDiscoverySettings {
  const OfferDiscoverySettings({
    required this.timeZone,
    required this.scheduledTimes,
    required this.autoDiscoveryEnabled,
  });

  static const docId = 'offer_discovery';
  static const defaultTimeZone = 'Asia/Karachi';

  final String timeZone;
  final List<String> scheduledTimes;
  final bool autoDiscoveryEnabled;

  factory OfferDiscoverySettings.defaults() {
    return const OfferDiscoverySettings(
      timeZone: defaultTimeZone,
      scheduledTimes: ['00:00', '12:00'],
      autoDiscoveryEnabled: true,
    );
  }

  OfferDiscoverySettings copyWith({
    String? timeZone,
    List<String>? scheduledTimes,
    bool? autoDiscoveryEnabled,
  }) {
    return OfferDiscoverySettings(
      timeZone: timeZone ?? this.timeZone,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      autoDiscoveryEnabled: autoDiscoveryEnabled ?? this.autoDiscoveryEnabled,
    );
  }

  static OfferDiscoverySettings fromFirestore(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return OfferDiscoverySettings.defaults();
    }
    final rawTimes = data['scheduledTimes'];
    final times = rawTimes is Iterable
        ? rawTimes
              .whereType<String>()
              .map((value) => normalizeTime(value))
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
        : <String>[];
    times.sort();
    return OfferDiscoverySettings(
      timeZone: data['timeZone'] as String? ?? defaultTimeZone,
      scheduledTimes:
          times.isEmpty ? OfferDiscoverySettings.defaults().scheduledTimes : times,
      autoDiscoveryEnabled: data['autoDiscoveryEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    final normalized = scheduledTimes
        .map(normalizeTime)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return {
      'id': docId,
      'timeZone': timeZone.trim().isEmpty ? defaultTimeZone : timeZone.trim(),
      'scheduledTimes': normalized.isEmpty
          ? OfferDiscoverySettings.defaults().scheduledTimes
          : normalized,
      'autoDiscoveryEnabled': autoDiscoveryEnabled,
    };
  }

  static String normalizeTime(String raw) {
    final value = raw.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      return '';
    }
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return '';
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String fromTimeOfDay(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
