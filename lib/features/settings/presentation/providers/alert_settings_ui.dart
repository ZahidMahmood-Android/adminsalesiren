import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/mobile_alert_settings.dart';
import 'app_settings_providers.dart';

MobileAlertSettings readMobileAlertSettings(WidgetRef ref) {
  return ref.read(mobileAlertSettingsProvider).value ??
      MobileAlertSettings.defaults();
}

class AlertNotificationOptions {
  const AlertNotificationOptions({
    required this.enabledSlugs,
    required this.selectableAlertTypes,
    required this.alertTypeLabels,
  });

  final List<String> enabledSlugs;
  final List<String> selectableAlertTypes;
  final Map<String, String> alertTypeLabels;

  factory AlertNotificationOptions.from(MobileAlertSettings settings) {
    final slugs = settings.enabledSlugs.isEmpty
        ? MobileAlertSettings.defaults().enabledSlugs
        : settings.enabledSlugs;
    return AlertNotificationOptions(
      enabledSlugs: slugs,
      selectableAlertTypes: slugs,
      alertTypeLabels: {
        for (final type in settings.types) type.slug: type.label,
      },
    );
  }
}

AlertNotificationOptions readAlertNotificationOptions(WidgetRef ref) {
  return AlertNotificationOptions.from(readMobileAlertSettings(ref));
}
