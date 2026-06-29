import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_legacy_preference_fields.dart';

class SavedBrandsSync {
  const SavedBrandsSync._();

  static const collectionName = 'saved_brands';

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
      return _brandIdsFromDocs(snapshot.docs);
    }

    final userDoc = await firestore.collection('users').doc(userId).get();
    return {
      ..._readStringList(userDoc.data()?['brandIds']),
      ..._readStringList(userDoc.data()?['favoriteBrands']),
    }.toList();
  }

  static Future<void> sync(
    FirebaseFirestore firestore,
    String userId,
    List<String> brandIds,
  ) async {
    final collection = firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName);
    final desired = brandIds.where((id) => id.trim().isNotEmpty).toSet();
    final snapshot = await collection.get();
    final existingByBrandId = <String, String>{};

    for (final doc in snapshot.docs) {
      final brandId = _readBrandId(doc.id, doc.data());
      if (brandId.isEmpty) continue;
      existingByBrandId[brandId] = doc.id;
    }

    for (final brandId in desired) {
      if (existingByBrandId.containsKey(brandId)) continue;
      await collection.doc(brandId).set({
        'brandId': brandId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final entry in existingByBrandId.entries) {
      if (desired.contains(entry.key)) continue;
      await collection.doc(entry.value).delete();
    }

    await UserLegacyPreferenceFields.deleteFromUserDoc(firestore, userId);
  }

  static List<String> _brandIdsFromDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final ids = <String>{};
    for (final doc in docs) {
      final brandId = _readBrandId(doc.id, doc.data());
      if (brandId.isNotEmpty) {
        ids.add(brandId);
      }
    }
    return ids.toList();
  }

  static String _readBrandId(String docId, Map<String, dynamic> data) {
    final fromData = data['brandId'];
    if (fromData is String && fromData.trim().isNotEmpty) {
      return fromData.trim();
    }
    if (docId.contains('--')) {
      return '';
    }
    return docId;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().where((item) => item.isNotEmpty).toList();
  }
}
