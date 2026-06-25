import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/data/firebase/selected_categories_sync.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../../access/presentation/providers/app_feature_providers.dart';
import '../../domain/entities/user_role_utils.dart';
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
    final authUser = ref.read(firebaseAuthProvider).currentUser;
    if (authUser != null) {
      await authUser.getIdToken();
    }
    final firestore = ref.watch(firestoreProvider);
    DocumentSnapshot<Map<String, dynamic>>? profile;
    try {
      profile = await firestore.collection('users').doc(user.id).get();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
      log.fine(
        'User profile self-read denied for uid=${user.id}; trying admin reference',
      );
    }
    if (profile != null && profile.exists) {
      final data = profile.data() ?? <String, dynamic>{};
      var categoryIds = _readStringList(data['categoryIds']);
      if (categoryIds.isEmpty) {
        try {
          categoryIds = await SelectedCategoriesSync.fetch(firestore, user.id);
        } on FirebaseException catch (error) {
          if (error.code != 'permission-denied') {
            rethrow;
          }
          log.fine(
            'Selected categories read denied for uid=${user.id}; using profile categories only',
          );
        }
      }
      return user.copyWith(
        fullName: data['fullName'] as String? ?? user.displayName,
        phoneNumber: data['phoneNumber'] as String? ?? '',
        roles: UserRoleUtils.readRoles(data),
        brandId: data['brandId'] as String? ?? '',
        categoryIds: categoryIds,
        cityIds: _readStringList(data['cityIds']),
        brandIds: _readStringList(data['brandIds']),
        isActive: data['isActive'] as bool? ?? true,
        notificationEnabled: data['notificationEnabled'] as bool? ?? true,
        isAdminEnabled: _readAdminEnabled(data),
        isMobileAppEnabled: _readMobileAppEnabled(data),
        mustChangePassword: data['mustChangePassword'] as bool? ?? false,
        featureIds: readFeatureIds(data),
      );
    }

    try {
      final admin = await firestore.collection('admins').doc(user.id).get();
      if (admin.exists) {
        final adminRole = admin.data()?['role'] as String? ?? '';
        if (_isOwnerAdminReference(adminRole)) {
          return user.copyWith(
            roles: const [UserRoles.owner],
            isActive: true,
            isAdminEnabled: true,
            isMobileAppEnabled: true,
          );
        }
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
      log.fine('Admin reference self-read denied for uid=${user.id}');
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
  return user?.canAccessAdminPanel ?? false;
});

final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.hasRole(UserRoles.owner) ?? false;
});

final isSuperAdminProvider = isOwnerProvider;

final isBrandAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.hasRole(UserRoles.brandAdmin) ?? false;
});

final isManagerProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.hasRole(UserRoles.manager) ?? false;
});

final isBrandScopedUserProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.hasRole(UserRoles.brandAdmin) ?? false;
});

final passwordChangeSkippedProvider = StateProvider<bool>((ref) => false);

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
      // After successful Firebase login, check profile access in Firestore.
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid != null) {
        final authUser = ref.read(firebaseAuthProvider).currentUser;
        if (authUser != null) {
          await authUser.getIdToken();
        }
        final firestore = ref.read(firestoreProvider);
        DocumentSnapshot<Map<String, dynamic>>? doc;
        try {
          doc = await firestore.collection('users').doc(uid).get();
        } on FirebaseException catch (error) {
          if (error.code != 'permission-denied') {
            rethrow;
          }
        }
        if (doc != null && doc.exists) {
          final data = doc.data() ?? <String, dynamic>{};
          final roles = UserRoleUtils.readRoles(data);
          final isActive = data['isActive'] as bool? ?? true;
          if (!isActive) {
            await ref.read(authRepositoryProvider).signOut();
            throw AppException(
              'Your account has been deactivated. '
              'Contact customer support to request reactivation.',
            );
          }

          if (UserRoleUtils.isMobileUserOnly(roles)) {
            await ref.read(authRepositoryProvider).signOut();
            throw AppException(
              'Mobile app users cannot access the admin panel.',
            );
          }

          final isAdminEnabled = UserRoleUtils.resolvesAdminEnabled(
            roles,
            _readAdminEnabled(data),
          );
          if (!isAdminEnabled ||
              !UserRoleUtils.hasAnyRole(roles, [
                UserRoles.owner,
                UserRoles.brandAdmin,
                UserRoles.manager,
              ])) {
            await ref.read(authRepositoryProvider).signOut();
            throw AppException(
              'You do not have permission to access the admin panel.',
            );
          }
        } else {
          try {
            final admin = await firestore.collection('admins').doc(uid).get();
            final adminRole = admin.data()?['role'] as String? ?? '';
            if (!admin.exists || !_isOwnerAdminReference(adminRole)) {
              await ref.read(authRepositoryProvider).signOut();
              throw AppException(
                'You do not have permission to access the admin panel.',
              );
            }
          } on FirebaseException catch (error) {
            if (error.code == 'permission-denied') {
              await ref.read(authRepositoryProvider).signOut();
              throw const AppException(
                'Unable to verify admin access. Deploy Firestore rules or contact support.',
              );
            }
            rethrow;
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

final changePasswordControllerProvider =
    AsyncNotifierProvider.autoDispose<ChangePasswordController, void>(
      ChangePasswordController.new,
    );

class ChangePasswordController extends AsyncNotifier<void> {
  final _log = AppLogger.get('ChangePasswordController');

  @override
  FutureOr<void> build() {}

  Future<void> changePassword(String newPassword) async {
    _log.info('Password change action submitted');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid != null) {
        await ref.read(firestoreProvider).collection('users').doc(uid).update({
          'mustChangePassword': false,
          'updatedAt': Timestamp.now(),
        });
      }
      ref.read(passwordChangeSkippedProvider.notifier).state = false;
      ref.invalidate(currentUserProfileProvider);
    });
    if (state.hasError) {
      _log.warning('Password change failed', state.error, state.stackTrace);
    } else {
      _log.info('Password change completed');
    }
  }
}

bool _isOwnerAdminReference(String? role) {
  return UserRoleUtils.normalizeRole(role ?? '') == UserRoles.owner;
}

bool _readAdminEnabled(Map<String, dynamic> data) {
  final roles = UserRoleUtils.readRoles(data);
  final stored = data['isAdminEnabled'];
  if (stored is bool) {
    return UserRoleUtils.resolvesAdminEnabled(roles, stored);
  }
  return UserRoleUtils.defaultIsAdminEnabled(roles);
}

bool _readMobileAppEnabled(Map<String, dynamic> data) {
  final roles = UserRoleUtils.readRoles(data);
  final stored = data['isMobileAppEnabled'];
  if (stored is bool) {
    return UserRoleUtils.resolvesMobileAppEnabled(roles, stored);
  }
  return UserRoleUtils.defaultIsMobileAppEnabled(roles);
}

List<String> _readStringList(dynamic raw) {
  if (raw is! Iterable) {
    return const [];
  }
  return raw.whereType<String>().where((value) => value.isNotEmpty).toList();
}
