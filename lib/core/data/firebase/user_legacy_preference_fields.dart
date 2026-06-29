import 'package:cloud_firestore/cloud_firestore.dart';

/// Root-level user doc fields replaced by preference subcollections.
class UserLegacyPreferenceFields {
  const UserLegacyPreferenceFields._();

  static const rootFieldNames = [
    'categoryIds',
    'cityIds',
    'brandIds',
    'selectedCategories',
    'favoriteBrands',
  ];

  static Map<String, dynamic> deletePayload() {
    return {
      for (final field in rootFieldNames) field: FieldValue.delete(),
    };
  }

  static Future<void> deleteFromUserDoc(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    await firestore.collection('users').doc(userId).set({
      ...deletePayload(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
