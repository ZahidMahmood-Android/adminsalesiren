import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/firebase_app_settings_repository.dart';
import '../../domain/entities/mobile_ads_settings.dart';
import '../../domain/entities/mobile_alert_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return FirebaseAppSettingsRepository(ref.watch(firestoreProvider));
});

final mobileAdsSettingsProvider = StreamProvider.autoDispose<MobileAdsSettings>(
  (ref) => ref.watch(appSettingsRepositoryProvider).watchMobileAdsSettings(),
);

final mobileAlertSettingsProvider =
    StreamProvider.autoDispose<MobileAlertSettings>((ref) {
      return ref
          .watch(appSettingsRepositoryProvider)
          .watchMobileAlertSettings();
    });

final selectableAlertTypeSlugsProvider = Provider<List<String>>((ref) {
  final slugs = ref.watch(mobileAlertSettingsProvider).maybeWhen(
        data: (settings) => settings.enabledSlugs,
        orElse: () => MobileAlertSettings.defaults().enabledSlugs,
      );
  if (slugs.isEmpty) {
    return MobileAlertSettings.defaults().enabledSlugs;
  }
  return slugs;
});

final appSettingsActionsProvider =
    AsyncNotifierProvider<AppSettingsActionsController, void>(
      AppSettingsActionsController.new,
    );

class AppSettingsActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('AppSettingsActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> setMobileAdsEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _log.info('Mobile ads setting change requested enabled=$enabled');
      await ref
          .read(appSettingsRepositoryProvider)
          .updateMobileAdsEnabled(enabled);
    });
  }

  Future<void> saveMobileAlertSettings(MobileAlertSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _log.info(
        'Mobile alert settings change requested enabled=${settings.enabledSlugs.length}',
      );
      await ref
          .read(appSettingsRepositoryProvider)
          .updateMobileAlertSettings(settings);
    });
  }
}
