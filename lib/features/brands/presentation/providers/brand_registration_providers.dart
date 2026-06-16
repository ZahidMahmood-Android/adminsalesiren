import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../firebase_options.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final brandRegistrationProvider =
    AsyncNotifierProvider.autoDispose<BrandRegistrationController, String?>(
      BrandRegistrationController.new,
    );

class BrandRegistrationController extends AsyncNotifier<String?> {
  final _log = AppLogger.get('BrandRegistrationController');

  @override
  FutureOr<String?> build() => null;

  Future<void> register({
    String? existingBrandId,
    required String brandName,
    required String brandType,
    required String primaryCategoryId,
    required List<String> categoryIds,
    required List<String> cityIds,
    required String businessContactName,
    required String businessContactPhone,
    required String businessContactEmail,
    required String marketingEmail,
    required String loginUserId,
    required String loginEmail,
    required String loginPassword,
    required String loginFullName,
    required String loginPhone,
    required String notes,
  }) async {
    final firestore = ref.read(firestoreProvider);
    final adminId = ref.read(currentUserProvider)?.id ?? '';
    final brandId = existingBrandId?.trim().isNotEmpty == true
        ? existingBrandId!.trim()
        : _slug(brandName);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final brandRef = firestore.collection('brands').doc(brandId);
      final now = FieldValue.serverTimestamp();
      await brandRef.set({
        'id': brandId,
        'name': brandName,
        'slug': brandId,
        'description': notes,
        'type': brandType,
        'primaryCategoryId': primaryCategoryId,
        'categoryIds': categoryIds,
        'cityIds': cityIds,
        'businessContactName': businessContactName,
        'businessContactPhone': businessContactPhone,
        'businessContactEmail': businessContactEmail,
        'marketingEmail': marketingEmail,
        'approvalStatus': 'approved',
        'ownerUserIds': <String>[],
        'createdByAdminId': adminId,
        'isActive': true,
        'isVerified': true,
        'isFeatured': false,
        'searchKeywords': _keywords(brandId, brandName),
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      final linkUserId = loginUserId.trim().isNotEmpty
          ? loginUserId.trim()
          : await _createBrandAuthUser(loginEmail, loginPassword);

      if (linkUserId.isNotEmpty) {
        await firestore.collection('users').doc(linkUserId).set({
          'id': linkUserId,
          'fullName': loginFullName,
          'email': loginEmail,
          'phoneNumber': loginPhone,
          'role': 'brand_admin',
          'brandId': brandId,
          'isActive': true,
          'createdAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
        await brandRef.set({
          'ownerUserIds': FieldValue.arrayUnion([linkUserId]),
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      _log.info('Registered brand id=$brandId loginEmail=$loginEmail');
      return 'Brand registered and linked to user $loginEmail.';
    });
  }

  Future<String> _createBrandAuthUser(String email, String password) async {
    if (email.trim().isEmpty) return '';

    final appName = 'brand-reg-${DateTime.now().microsecondsSinceEpoch}';
    FirebaseApp? app;
    try {
      app = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await auth.signOut();
      return credential.user?.uid ?? '';
    } on FirebaseAuthException catch (error) {
      _log.warning('_createBrandAuthUser FirebaseAuthException', error);
      throw AppException(_authErrorMessage(error.code, error.message));
    } catch (error) {
      _log.warning('_createBrandAuthUser unexpected error', error);
      // Surface the raw message so the admin knows what happened.
      throw AppException(
        'Failed to create the brand admin account: '
        '${error.toString().replaceFirst(RegExp(r'^\[.*?\]\s*'), '')}',
      );
    } finally {
      await app?.delete();
    }
  }

  static String _authErrorMessage(String code, String? fallback) {
    return switch (code) {
      'email-already-in-use' =>
        'This email is already registered in Firebase Auth.\n'
            'Either use a different login email, or enter the existing user\'s UID '
            'directly on the "Link existing user" field.',
      'invalid-email' => 'The login email address is not valid.',
      'weak-password' =>
        'The password is too weak — Firebase requires at least 6 characters.',
      'operation-not-allowed' =>
        'Email/password sign-in is not enabled in this Firebase project. '
            'Enable it in the Firebase Console › Authentication › Sign-in methods.',
      'network-request-failed' =>
        'Network error while creating the account. Check your internet connection.',
      'too-many-requests' =>
        'Too many account-creation attempts. Please wait a moment and try again.',
      _ =>
        fallback?.isNotEmpty == true
            ? fallback!
            : 'Failed to create the brand admin account (code: $code).',
    };
  }

  String _slug(String value) {
    final slug = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return slug.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  List<String> _keywords(String id, String name) {
    return {
      id,
      name.toLowerCase(),
      ...name.toLowerCase().split(RegExp(r'[^a-z0-9]+')),
    }.where((item) => item.isNotEmpty).toList();
  }
}
