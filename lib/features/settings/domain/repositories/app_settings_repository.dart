import '../entities/mobile_ads_settings.dart';

abstract class AppSettingsRepository {
  Stream<MobileAdsSettings> watchMobileAdsSettings();
  Future<void> updateMobileAdsEnabled(bool enabled);
}
