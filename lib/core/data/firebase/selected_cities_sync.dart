import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_legacy_preference_fields.dart';

class SelectedCitiesSync {
  const SelectedCitiesSync._();

  static const collectionName = 'selected_cities';

  static Future<List<String>> fetch(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => _readCityId(doc.id, doc.data())).toList();
    }

    final userDoc = await firestore.collection('users').doc(userId).get();
    return _readStringList(userDoc.data()?['cityIds']);
  }

  static Future<void> sync(
    FirebaseFirestore firestore,
    String userId,
    List<String> cityIds,
  ) async {
    final collection = firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName);
    final desired = cityIds.where((id) => id.trim().isNotEmpty).toSet();
    final existing = (await collection.get()).docs
        .map((doc) => _readCityId(doc.id, doc.data()))
        .toSet();

    for (final cityId in desired.difference(existing)) {
      await collection.doc(cityId).set({
        'cityId': cityId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final cityId in existing.difference(desired)) {
      await collection.doc(cityId).delete();
    }

    await UserLegacyPreferenceFields.deleteFromUserDoc(firestore, userId);
  }

  static String _readCityId(String docId, Map<String, dynamic> data) {
    final fromData = data['cityId'];
    if (fromData is String && fromData.trim().isNotEmpty) {
      return fromData.trim();
    }
    return docId;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().where((item) => item.isNotEmpty).toList();
  }
}
