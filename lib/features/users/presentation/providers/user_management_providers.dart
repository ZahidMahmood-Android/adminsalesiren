import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/data/firebase/selected_categories_sync.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../access/domain/app_feature_seed_data.dart';
import '../../../access/presentation/providers/app_feature_providers.dart';
import '../../data/admin_reference_sync.dart';

final managedUsersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final uid = ref.watch(
    authStateProvider.select((asyncUser) => asyncUser.value?.id),
  );
  if (uid == null) {
    return Stream.value(const <AppUser>[]);
  }

  final roleScope = ref.watch(
    currentUserProfileProvider.select((asyncProfile) {
      final profile = asyncProfile.value;
      if (profile == null) {
        return null;
      }
      return UserRoleUtils.primaryRole(profile.roles);
    }),
  );
  if (roleScope == null) {
    return Stream.value(const <AppUser>[]);
  }

  final isOwner = UserRoleUtils.hasRole([roleScope], UserRoles.owner);
  final isManager = UserRoleUtils.hasRole([roleScope], UserRoles.manager);
  final firestore = ref.read(firestoreProvider);
  final query = isManager && !isOwner
      ? firestore
            .collection('users')
            .where(
              'role',
              whereIn: const [
                UserRoles.manager,
                UserRoles.brandAdmin,
                UserRoles.mobileUser,
              ],
            )
      : firestore.collection('users');

  return query.snapshots().map((snapshot) {
    final users =
        snapshot.docs
            .map(_appUserFromSnapshot)
            .where((user) => isOwner || !user.hasRole(UserRoles.owner))
            .toList()
          ..sort((a, b) => a.email.compareTo(b.email));
    return users;
  });
});

final usersListSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final managedUserByIdProvider = FutureProvider.autoDispose
    .family<AppUser?, String>((ref, userId) async {
      final firestore = ref.read(firestoreProvider);
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      var user = _appUserFromSnapshot(doc);
      if (user.categoryIds.isEmpty) {
        final fromSub = await SelectedCategoriesSync.fetch(firestore, userId);
        user = user.copyWith(categoryIds: fromSub);
      }
      return user;
    });

final userManagementActionsProvider =
    AsyncNotifierProvider.autoDispose<UserManagementActionsController, void>(
      UserManagementActionsController.new,
    );

class UserManagementActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('UserManagementActionsController');

  @override
  FutureOr<void> build() {}

  void _assertUserOwner() {
    if (!ref.read(isOwnerProvider)) {
      throw AppException('Only owners can manage users.');
    }
  }

  Future<void> setActive(String userId, bool isActive) async {
    _log.info('Updating user active state id=$userId active=$isActive');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _assertUserOwner();
      await ref.read(firestoreProvider).collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    });
    _logResult('Update user active state', userId);
  }

  Future<void> setNotificationEnabled(String userId, bool enabled) async {
    _log.info('Updating user notification state id=$userId enabled=$enabled');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _assertUserOwner();
      await ref.read(firestoreProvider).collection('users').doc(userId).update({
        'notificationEnabled': enabled,
        'updatedAt': Timestamp.now(),
      });
    });
    _logResult('Update user notification state', userId);
  }

  Future<void> updateUser(AppUser user) async {
    _log.info('Updating user profile id=${user.id}');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _assertUserOwner();
      if (UserRoleUtils.isMobileUserOnly(user.roles) && user.isAdminEnabled) {
        throw AppException('Mobile users cannot have admin panel access.');
      }

      final resolvedFeatureIds = UserRoleUtils.isMobileUserOnly(user.roles)
          ? AppFeatureIds.allMobile
          : user.featureIds;
      if (resolvedFeatureIds.isEmpty) {
        throw AppException('Select at least one feature for this user.');
      }

      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(user.id).update({
        'fullName': user.fullName,
        'displayName': user.displayName,
        'phoneNumber': user.phoneNumber,
        'roles': UserRoleUtils.normalizeRoles(user.roles),
        'role': UserRoleUtils.primaryRole(user.roles),
        'brandId': user.brandId,
        'categoryIds': user.categoryIds,
        'cityIds': user.cityIds,
        'brandIds': user.brandIds,
        'isActive': user.isActive,
        'notificationEnabled': user.notificationEnabled,
        'isAdminEnabled': user.effectiveIsAdminEnabled,
        'isMobileAppEnabled': user.effectiveIsMobileAppEnabled,
        'featureIds': resolvedFeatureIds,
        'updatedAt': Timestamp.now(),
      });
      await SelectedCategoriesSync.sync(firestore, user.id, user.categoryIds);
      await AdminReferenceSync.syncForRoles(firestore, user.id, user.roles);
    });
    _logResult('Update user profile', user.id);
  }

  Future<void> deleteUserProfile(String userId) async {
    _log.warning('Deleting user profile id=$userId');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _assertUserOwner();
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(userId).delete();
      await AdminReferenceSync.deleteReference(firestore, userId);
    });
    _logResult('Delete user profile', userId);
  }

  void _logResult(String label, String userId) {
    if (state.hasError) {
      final error = state.error;
      if (error is AppException) {
        _log.info('$label denied id=$userId: ${error.message}');
      } else {
        _log.severe('$label failed id=$userId', error, state.stackTrace);
      }
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
    roles: UserRoleUtils.readRoles(data),
    brandId: data['brandId'] as String? ?? '',
    categoryIds: _readCategoryIds(data),
    cityIds: _readStringList(data['cityIds']),
    brandIds: _readStringList(data['brandIds']),
    isActive: data['isActive'] as bool? ?? true,
    notificationEnabled: _readNotificationEnabled(data),
    isAdminEnabled: _readAdminEnabled(data),
    isMobileAppEnabled: _readMobileAppEnabled(data),
    featureIds: readFeatureIds(data),
  );
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

bool _readNotificationEnabled(Map<String, dynamic> data) {
  final value = data['notificationEnabled'];
  if (value is bool) {
    return value;
  }
  return true;
}

List<String> _readStringList(dynamic raw) {
  if (raw is! Iterable) {
    return const [];
  }
  return raw.whereType<String>().where((value) => value.isNotEmpty).toList();
}

List<String> _readCategoryIds(Map<String, dynamic> data) {
  return _readStringList(data['categoryIds']);
}
