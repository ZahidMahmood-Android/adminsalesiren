import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/entities/user_roles.dart';

class AdminReferenceSync {
  const AdminReferenceSync._();

  static Future<void> syncForRoles(
    FirebaseFirestore firestore,
    String userId,
    List<String> roles,
  ) async {
    final ref = firestore.collection('admins').doc(userId);
    if (roles.contains(UserRoles.owner)) {
      await ref.set({
        'id': userId,
        'role': UserRoles.owner,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      return;
    }

    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
    }
  }

  static Future<void> deleteReference(
    FirebaseFirestore firestore,
    String userId,
  ) {
    return firestore.collection('admins').doc(userId).delete();
  }
}
