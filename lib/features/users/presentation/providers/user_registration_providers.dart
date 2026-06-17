import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../firebase_options.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
    required String role,
    required String brandId,
  }) async {
    final firestore = ref.read(firestoreProvider);
    final adminId = ref.read(currentUserProvider)?.id ?? '';
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedRole = role.trim();
    final normalizedBrandId = brandId.trim();

    final needsBrand = normalizedRole == UserRoles.brandAdmin;
    if (needsBrand && normalizedBrandId.isEmpty) {
      throw AppException('Brand is required for brand admin users.');
    }
    if (!needsBrand && normalizedBrandId.isNotEmpty) {
      throw AppException('Brand can only be selected for brand admin users.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final userId = await _createAuthUser(normalizedEmail, password);
      final now = FieldValue.serverTimestamp();

      await firestore.collection('users').doc(userId).set({
        'id': userId,
        'fullName': fullName.trim(),
        'displayName': fullName.trim(),
        'email': normalizedEmail,
        'phoneNumber': phoneNumber.trim(),
        'role': normalizedRole,
        'brandId': needsBrand ? normalizedBrandId : '',
        'isActive': true,
        'createdByAdminId': adminId,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (needsBrand) {
        await firestore.collection('brands').doc(normalizedBrandId).set({
          'ownerUserIds': FieldValue.arrayUnion([userId]),
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      _log.info(
        'Registered user id=$userId role=$normalizedRole email=$normalizedEmail',
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
      throw AppException(
        'Failed to create user account: '
        '${error.toString().replaceFirst(RegExp(r'^\[.*?\]\s*'), '')}',
      );
    } finally {
      await app?.delete();
    }
  }

  static String _authErrorMessage(String code, String? fallback) {
    return switch (code) {
      'email-already-in-use' =>
        'This email is already registered in Firebase Auth.',
      'invalid-email' => 'The email address is not valid.',
      'weak-password' => 'The password is too weak. Use at least 6 characters.',
      'operation-not-allowed' =>
        'Email/password sign-in is not enabled in Firebase Authentication.',
      'network-request-failed' =>
        'Network error while creating the user account.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      _ =>
        fallback?.isNotEmpty == true
            ? fallback!
            : 'Failed to create user account (code: $code).',
    };
  }
}
