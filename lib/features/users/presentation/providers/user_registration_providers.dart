import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/firebase/selected_categories_sync.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../firebase_options.dart';
import '../../../auth/domain/entities/user_role_utils.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../access/domain/app_feature_seed_data.dart';
import '../../../access/domain/feature_access_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/admin_reference_sync.dart';

final userRegistrationProvider =
    AsyncNotifierProvider.autoDispose<UserRegistrationController, String?>(
      UserRegistrationController.new,
    );

class UserRegistrationController extends AsyncNotifier<String?> {
  final _log = AppLogger.get('UserRegistrationController');

  @override
  FutureOr<String?> build() => null;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required List<String> roles,
    required String brandId,
    required List<String> categoryIds,
    required List<String> cityIds,
    required List<String> brandIds,
    required bool notificationEnabled,
    required bool isAdminEnabled,
    required bool isMobileAppEnabled,
    required List<String> featureIds,
  }) async {
    final firestore = ref.read(firestoreProvider);
    final adminId = ref.read(currentUserProvider)?.id ?? '';

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!ref.read(isOwnerProvider)) {
        throw AppException('Only owners can register users.');
      }

      final normalizedEmail = email.trim().toLowerCase();
      final normalizedRoles = roles.toSet().toList();
      final normalizedBrandId = brandId.trim();

      if (normalizedRoles.isEmpty) {
        throw AppException('Select at least one role.');
      }

      final needsBrand = UserRoleUtils.requiresBrand(normalizedRoles);
      if (needsBrand && normalizedBrandId.isEmpty) {
        throw AppException('Brand is required for brand admin users.');
      }
      if (!needsBrand && normalizedBrandId.isNotEmpty) {
        throw AppException('Brand can only be selected for brand admin users.');
      }
      if (UserRoleUtils.isMobileUserOnly(normalizedRoles) && isAdminEnabled) {
        throw AppException('Mobile users cannot have admin panel access.');
      }

      final resolvedFeatureIds = UserRoleUtils.isMobileUserOnly(normalizedRoles)
          ? AppFeatureIds.allMobile
          : featureIds.isNotEmpty
          ? featureIds
          : FeatureAccessUtils.defaultFeatureIdsForRoles(normalizedRoles);
      if (resolvedFeatureIds.isEmpty) {
        throw AppException('Select at least one feature for this user.');
      }

      final resolvedAdminEnabled = UserRoleUtils.resolvesAdminEnabled(
        normalizedRoles,
        isAdminEnabled,
      );
      final resolvedMobileAppEnabled = UserRoleUtils.resolvesMobileAppEnabled(
        normalizedRoles,
        isMobileAppEnabled,
      );

      final existingUser = await firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (existingUser.docs.isNotEmpty) {
        throw AppException('A user profile with this email already exists.');
      }

      final userId = await _createAuthUser(normalizedEmail, password);
      final now = FieldValue.serverTimestamp();
      final primaryRole = UserRoleUtils.primaryRole(normalizedRoles);

      await firestore.collection('users').doc(userId).set({
        'id': userId,
        'fullName': fullName.trim(),
        'displayName': fullName.trim(),
        'email': normalizedEmail,
        'phoneNumber': phoneNumber.trim(),
        'roles': normalizedRoles,
        'role': primaryRole,
        'brandId': needsBrand ? normalizedBrandId : '',
        'categoryIds': categoryIds,
        'cityIds': cityIds,
        'brandIds': brandIds,
        'isActive': true,
        'notificationEnabled': notificationEnabled,
        'isAdminEnabled': resolvedAdminEnabled,
        'isMobileAppEnabled': resolvedMobileAppEnabled,
        'featureIds': resolvedFeatureIds,
        'mustChangePassword': true,
        'createdByAdminId': adminId,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      await SelectedCategoriesSync.sync(firestore, userId, categoryIds);

      await AdminReferenceSync.syncForRoles(firestore, userId, normalizedRoles);

      if (needsBrand) {
        await firestore.collection('brands').doc(normalizedBrandId).set({
          'ownerUserIds': FieldValue.arrayUnion([userId]),
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      _log.info(
        'Registered user id=$userId roles=$normalizedRoles email=$normalizedEmail',
      );
      return 'User registered successfully.';
    });
  }

  Future<String> _createAuthUser(String email, String password) async {
    final appName = 'user-reg-${DateTime.now().microsecondsSinceEpoch}';
    FirebaseApp? app;
    try {
      app = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await auth.signOut();
      return credential.user?.uid ?? '';
    } on FirebaseAuthException catch (error) {
      _log.warning('_createAuthUser FirebaseAuthException', error);
      throw AppException(_authErrorMessage(error.code, error.message));
    } catch (error) {
      _log.warning('_createAuthUser unexpected error', error);
      throw AppException(ErrorMessages.friendly(error));
    } finally {
      await app?.delete();
    }
  }

  static String _authErrorMessage(String code, String? fallback) {
    return switch (code) {
      'email-already-in-use' =>
        'This email is already registered. Use a different email address.',
      'invalid-email' => 'The email address is not valid.',
      'weak-password' => 'The password is too weak. Use at least 6 characters.',
      'operation-not-allowed' =>
        'Email sign-in is not enabled. Please contact support.',
      'network-request-failed' =>
        'We could not connect right now. Please check your internet and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      _ =>
        fallback?.trim().isNotEmpty == true
            ? ErrorMessages.friendly(fallback)
            : 'Unable to create the user account. Please try again.',
    };
  }
}
