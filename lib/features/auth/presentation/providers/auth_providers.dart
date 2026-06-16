import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_roles.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(currentUserProfileProvider).value;
});

final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final log = AppLogger.get('AdminAccessProvider');
  final user =
      ref.watch(authStateProvider).value ??
      ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    log.fine('No user signed in');
    return null;
  }

  log.info('Loading admin profile for uid=${user.id}');

  try {
    final firestore = ref.watch(firestoreProvider);
    final profile = await firestore.collection('users').doc(user.id).get();
    if (profile.exists) {
      final data = profile.data() ?? <String, dynamic>{};
      return user.copyWith(
        fullName: data['fullName'] as String? ?? user.displayName,
        phoneNumber: data['phoneNumber'] as String? ?? '',
        role: data['role'] as String? ?? UserRoles.mobileUser,
        brandId: data['brandId'] as String? ?? '',
        isActive: data['isActive'] as bool? ?? true,
      );
    }

    final admin = await firestore.collection('admins').doc(user.id).get();
    if (admin.exists) {
      return user.copyWith(role: UserRoles.superAdmin, isActive: true);
    }
    return null;
  } catch (error, stack) {
    log.warning('Admin profile check failed for uid=${user.id}', error, stack);
    return null;
  }
});

final adminAccessProvider = FutureProvider<bool>((ref) async {
  final user = await ref
      .watch(currentUserProfileProvider.future)
      .timeout(const Duration(seconds: 5));
  return user != null &&
      user.isActive &&
      (user.role == UserRoles.superAdmin || user.role == UserRoles.brandAdmin);
});

final isSuperAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRoles.superAdmin;
});

final isBrandAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.role == UserRoles.brandAdmin;
});

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );

class LoginController extends AsyncNotifier<void> {
  final _log = AppLogger.get('LoginController');

  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    _log.info('Login action submitted');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email, password);
      // After successful Firebase login, check isActive in Firestore.
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid != null) {
        final doc = await ref
            .read(firestoreProvider)
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final isActive = (doc.data() ?? {})['isActive'] as bool? ?? true;
          if (!isActive) {
            await ref.read(authRepositoryProvider).signOut();
            throw AppException(
              'Your account has been deactivated. '
              'Contact customer support to request reactivation.',
            );
          }
        }
      }
    });
    if (state.hasError) {
      _log.warning('Login action failed', state.error, state.stackTrace);
    } else {
      _log.info('Login action completed');
    }
  }
}
