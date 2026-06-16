import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/domain/entities/app_user.dart';

final managedUsersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  return ref.watch(firestoreProvider).collection('users').snapshots().map((
    snapshot,
  ) {
    final users = snapshot.docs.map(_appUserFromSnapshot).toList()
      ..sort((a, b) => a.email.compareTo(b.email));
    return users;
  });
});

final userManagementActionsProvider =
    AsyncNotifierProvider.autoDispose<UserManagementActionsController, void>(
      UserManagementActionsController.new,
    );

class UserManagementActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('UserManagementActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> setActive(String userId, bool isActive) async {
    _log.info('Updating user active state id=$userId active=$isActive');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(firestoreProvider).collection('users').doc(userId).update(
        {'isActive': isActive, 'updatedAt': Timestamp.now()},
      );
    });
    _logResult('Update user active state', userId);
  }

  Future<void> deleteUserProfile(String userId) async {
    _log.warning('Deleting user profile id=$userId');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(firestoreProvider)
          .collection('users')
          .doc(userId)
          .delete();
    });
    _logResult('Delete user profile', userId);
  }

  void _logResult(String label, String userId) {
    if (state.hasError) {
      _log.severe('$label failed id=$userId', state.error, state.stackTrace);
    } else {
      _log.info('$label completed id=$userId');
    }
  }
}

AppUser _appUserFromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? <String, dynamic>{};
  final email = data['email'] as String? ?? '';
  final displayName =
      data['displayName'] as String? ?? data['fullName'] as String? ?? email;
  return AppUser(
    id: doc.id,
    email: email,
    displayName: displayName,
    fullName: data['fullName'] as String? ?? displayName,
    phoneNumber: data['phoneNumber'] as String? ?? '',
    role: data['role'] as String? ?? 'mobile_user',
    brandId: data['brandId'] as String? ?? '',
    isActive: data['isActive'] as bool? ?? true,
  );
}
