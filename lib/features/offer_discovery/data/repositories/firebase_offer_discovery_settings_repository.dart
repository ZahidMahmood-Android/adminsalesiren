import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/offer_discovery_settings.dart';

class FirebaseOfferDiscoverySettingsRepository {
  FirebaseOfferDiscoverySettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('app_settings').doc(OfferDiscoverySettings.docId);

  Stream<OfferDiscoverySettings> watchSettings() {
    return _doc.snapshots().map((snapshot) {
      return OfferDiscoverySettings.fromFirestore(snapshot.data());
    });
  }

  Future<void> saveSettings(
    OfferDiscoverySettings settings, {
    required String updatedByUserId,
  }) async {
    await _doc.set({
      ...settings.toFirestore(),
      'updatedByUserId': updatedByUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
