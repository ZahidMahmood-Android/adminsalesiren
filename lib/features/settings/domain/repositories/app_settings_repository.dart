import '../entities/mobile_ads_settings.dart';
import '../entities/mobile_alert_settings.dart';

abstract class AppSettingsRepository {
  Stream<MobileAdsSettings> watchMobileAdsSettings();
  Future<void> updateMobileAdsEnabled(bool enabled);
  Stream<MobileAlertSettings> watchMobileAlertSettings();
  Future<void> updateMobileAlertSettings(MobileAlertSettings settings);
}
