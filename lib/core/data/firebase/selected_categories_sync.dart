import 'package:cloud_firestore/cloud_firestore.dart';

class SelectedCategoriesSync {
  const SelectedCategoriesSync._();

  static const collectionName = 'selected_categories';

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
      return snapshot.docs.map((doc) => doc.id).toList();
    }

    final userDoc = await firestore.collection('users').doc(userId).get();
    return _readStringList(userDoc.data()?['selectedCategories']);
  }

  static Future<void> sync(
    FirebaseFirestore firestore,
    String userId,
    List<String> categoryIds,
  ) async {
    final collection = firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName);
    final desired = categoryIds.toSet();
    final existing = (await collection.get()).docs.map((doc) => doc.id).toSet();

    for (final categoryId in desired.difference(existing)) {
      await collection.doc(categoryId).set({
        'categoryId': categoryId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final categoryId in existing.difference(desired)) {
      await collection.doc(categoryId).delete();
    }

    await firestore.collection('users').doc(userId).set({
      'selectedCategories': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static List<String> _readStringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.whereType<String>().where((item) => item.isNotEmpty).toList();
  }
}
