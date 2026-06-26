import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_logger.dart';
import '../domain/entities/mobile_ads_settings.dart';
import '../domain/entities/mobile_alert_settings.dart';
import '../domain/repositories/app_settings_repository.dart';

class FirebaseAppSettingsRepository implements AppSettingsRepository {
  FirebaseAppSettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseAppSettingsRepository');

  DocumentReference<Map<String, dynamic>> get _mobileAds =>
      _firestore.collection('app_settings').doc('mobile_ads');

  DocumentReference<Map<String, dynamic>> get _mobileAlerts =>
      _firestore.collection('app_settings').doc(MobileAlertSettings.docId);

  @override
  Stream<MobileAdsSettings> watchMobileAdsSettings() {
    return _mobileAds.snapshots().map((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      return MobileAdsSettings(enabled: data['enabled'] as bool? ?? false);
    });
  }

  @override
  Future<void> updateMobileAdsEnabled(bool enabled) async {
    _log.info('Updating mobile ads enabled=$enabled');
    await _mobileAds.set({
      'id': 'mobile_ads',
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<MobileAlertSettings> watchMobileAlertSettings() {
    return _mobileAlerts.snapshots().map((snapshot) {
      return MobileAlertSettings.fromFirestore(snapshot.data());
    });
  }

  @override
  Future<void> updateMobileAlertSettings(MobileAlertSettings settings) async {
    _log.info('Updating mobile alert settings types=${settings.types.length}');
    await _mobileAlerts.set({
      'id': MobileAlertSettings.docId,
      'types': settings.toFirestoreTypes(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
