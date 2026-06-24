import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/app_logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;
  final _log = AppLogger.get('FirebaseAuthRepository');

  @override
  AppUser? get currentUser => _auth.currentUser?.toAppUser();

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map((user) => user?.toAppUser());
  }

  @override
  Future<AppUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim();
    _log.info('Admin sign-in started for $normalizedEmail');
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          'Sign-in could not be completed. Please try again.',
        );
      }
      _log.info('Admin sign-in succeeded for uid=${user.uid}');
      return user.toAppUser();
    } on FirebaseAuthException catch (error) {
      _log.warning(
        'Admin sign-in failed for $normalizedEmail with code=${error.code}',
        error,
        error.stackTrace,
      );
      throw AppException(_authMessage(error.code), code: error.code);
    }
  }

  @override
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    _log.info('Admin sign-out started for uid=$uid');
    await _auth.signOut();
    _log.info('Admin sign-out completed');
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        'You must be signed in to change your password.',
      );
    }
    _log.info('Password update started for uid=${user.uid}');
    try {
      await user.updatePassword(newPassword);
      _log.info('Password update succeeded for uid=${user.uid}');
    } on FirebaseAuthException catch (error) {
      _log.warning(
        'Password update failed for uid=${user.uid} with code=${error.code}',
        error,
        error.stackTrace,
      );
      throw AppException(_passwordUpdateMessage(error.code), code: error.code);
    }
  }

  String _passwordUpdateMessage(String code) {
    return switch (code) {
      'weak-password' => 'The password is too weak. Use at least 6 characters.',
      'requires-recent-login' =>
        'Please sign out, sign in again, and retry changing your password.',
      _ => 'Unable to update password. Please try again.',
    };
  }

  String _authMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Enter a valid admin email address.',
      'user-disabled' => 'This admin account is disabled.',
      'user-not-found' => 'No admin account exists for this email.',
      'wrong-password' => 'The password is incorrect.',
      'invalid-credential' => 'The email or password is incorrect.',
      'configuration-not-found' =>
        'Sign-in is not available right now. Please contact support.',
      _ => 'Unable to sign in. Please try again.',
    };
  }
}

extension on User {
  AppUser toAppUser() {
    return AppUser(id: uid, email: email ?? '', displayName: displayName ?? '');
  }
}
