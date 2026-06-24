import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_logger.dart';
import '../domain/entities/mobile_ads_settings.dart';
import '../domain/repositories/app_settings_repository.dart';

class FirebaseAppSettingsRepository implements AppSettingsRepository {
  FirebaseAppSettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseAppSettingsRepository');

  DocumentReference<Map<String, dynamic>> get _mobileAds =>
      _firestore.collection('app_settings').doc('mobile_ads');

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
}
