import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/firebase/user_preferences_sync.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../domain/entities/app_user.dart';
import 'auth_providers.dart';

final profileUpdateProvider =
    AsyncNotifierProvider.autoDispose<ProfileUpdateController, void>(
      ProfileUpdateController.new,
    );

class ProfileUpdateController extends AsyncNotifier<void> {
  final _log = AppLogger.get('ProfileUpdateController');

  @override
  FutureOr<void> build() {}

  Future<void> save(AppUser user) async {
    _log.info('Profile update started for uid=${user.id}');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null || uid != user.id) {
        throw AppException('You must be signed in to update your profile.');
      }

      await ref.read(firestoreProvider).collection('users').doc(uid).update({
        'fullName': user.fullName.trim(),
        'displayName': user.fullName.trim(),
        'phoneNumber': user.phoneNumber.trim(),
        'notificationEnabled': user.notificationEnabled,
        'updatedAt': Timestamp.now(),
      });
      await UserPreferencesSync.sync(
        ref.read(firestoreProvider),
        uid,
        categoryIds: user.categoryIds,
        cityIds: user.cityIds,
        brandIds: user.brandIds,
      );
      ref.invalidate(currentUserProfileProvider);
    });
    if (state.hasError) {
      final error = state.error;
      if (error is AppException) {
        _log.info('Profile update denied for uid=${user.id}: ${error.message}');
      } else {
        _log.warning('Profile update failed', error, state.stackTrace);
      }
    } else {
      _log.info('Profile update completed for uid=${user.id}');
    }
  }
}
