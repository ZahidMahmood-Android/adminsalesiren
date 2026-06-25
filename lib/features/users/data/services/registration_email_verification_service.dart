import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../firebase_options.dart';

enum RegistrationEmailVerificationPhase { idle, sending, pending, verified }

class RegistrationEmailVerificationSnapshot {
  const RegistrationEmailVerificationSnapshot({
    this.email = '',
    this.uid = '',
    this.phase = RegistrationEmailVerificationPhase.idle,
    this.errorMessage,
  });

  final String email;
  final String uid;
  final RegistrationEmailVerificationPhase phase;
  final String? errorMessage;

  bool get isVerified =>
      phase == RegistrationEmailVerificationPhase.verified &&
      email.isNotEmpty &&
      uid.isNotEmpty;

  bool matchesEmail(String value) =>
      email.trim().toLowerCase() == value.trim().toLowerCase();

  RegistrationEmailVerificationSnapshot copyWith({
    String? email,
    String? uid,
    RegistrationEmailVerificationPhase? phase,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegistrationEmailVerificationSnapshot(
      email: email ?? this.email,
      uid: uid ?? this.uid,
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class RegistrationEmailVerificationService {
  RegistrationEmailVerificationService(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  FirebaseApp? _app;
  FirebaseAuth? _auth;
  Timer? _pollTimer;
  final _controller =
      StreamController<RegistrationEmailVerificationSnapshot>.broadcast();

  Stream<RegistrationEmailVerificationSnapshot> get stream =>
      _controller.stream;

  RegistrationEmailVerificationSnapshot _snapshot =
      const RegistrationEmailVerificationSnapshot();

  RegistrationEmailVerificationSnapshot get snapshot => _snapshot;

  Future<void> dispose() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    final app = _app;
    _app = null;
    _auth = null;
    if (app != null) {
      try {
        await FirebaseAuth.instanceFor(app: app).signOut();
      } catch (_) {}
      await app.delete();
    }
  }

  void _emit(RegistrationEmailVerificationSnapshot next) {
    _snapshot = next;
    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  Future<void> reset() async {
    await dispose();
    _emit(const RegistrationEmailVerificationSnapshot());
  }

  Future<void> startVerification(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw const AppException('Enter a valid email address.');
    }

    _emit(
      _snapshot.copyWith(
        email: normalized,
        phase: RegistrationEmailVerificationPhase.sending,
        clearError: true,
      ),
    );

    await dispose();

    try {
      final data = kIsWeb
          ? await _runRegistrationJob(action: 'start', email: normalized)
          : await _invokeStartCallable(normalized);
      final uid = data['uid'] as String? ?? '';
      final alreadyVerified = data['alreadyVerified'] == true;
      if (alreadyVerified && uid.isNotEmpty) {
        _emit(
          RegistrationEmailVerificationSnapshot(
            email: normalized,
            uid: uid,
            phase: RegistrationEmailVerificationPhase.verified,
          ),
        );
        return;
      }

      final customToken = data['customToken'] as String? ?? '';
      if (uid.isEmpty || customToken.isEmpty) {
        throw const AppException(
          'Could not start email verification. Please try again.',
        );
      }

      _app = await Firebase.initializeApp(
        name: 'registration-email-${DateTime.now().microsecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instanceFor(app: _app!);
      await _auth!.signInWithCustomToken(customToken);
      await _auth!.currentUser?.sendEmailVerification();

      _emit(
        RegistrationEmailVerificationSnapshot(
          email: normalized,
          uid: uid,
          phase: RegistrationEmailVerificationPhase.pending,
        ),
      );
      _startPolling();
      await _pollOnce();
    } on FirebaseFunctionsException catch (error) {
      final message = error.message?.trim();
      _emit(
        _snapshot.copyWith(
          phase: RegistrationEmailVerificationPhase.idle,
          errorMessage: message?.isNotEmpty == true
              ? message
              : 'Could not start email verification.',
        ),
      );
      rethrow;
    } on AppException catch (error) {
      _emit(
        _snapshot.copyWith(
          phase: RegistrationEmailVerificationPhase.idle,
          errorMessage: error.message,
        ),
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _invokeStartCallable(String email) async {
    final response = await _functions
        .httpsCallable('adminStartRegistrationEmailVerification')
        .call<Map<String, dynamic>>({'email': email});
    return response.data;
  }

  Future<void> resendVerification() async {
    final user = _auth?.currentUser;
    if (user == null) {
      throw const AppException('Send a verification email first.');
    }
    await user.sendEmailVerification();
  }

  Future<void> refreshStatus({String? email}) async {
    final normalized = (email ?? _snapshot.email).trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }

    if (_auth?.currentUser != null) {
      await _pollOnce();
      return;
    }

    final data = kIsWeb
        ? await _runRegistrationJob(action: 'check_status', email: normalized)
        : await _invokeCheckStatusCallable(normalized);
    _applyStatusCheck(normalized, data);
  }

  Future<Map<String, dynamic>> _invokeCheckStatusCallable(String email) async {
    final response = await _functions
        .httpsCallable('adminCheckRegistrationEmailStatus')
        .call<Map<String, dynamic>>({'email': email});
    return response.data;
  }

  void _applyStatusCheck(String normalized, Map<String, dynamic> data) {
    final verified = data['verified'] == true;
    final canRegister = data['canRegister'] == true;
    final uid = data['uid'] as String? ?? '';

    if (verified && canRegister && uid.isNotEmpty) {
      _emit(
        RegistrationEmailVerificationSnapshot(
          email: normalized,
          uid: uid,
          phase: RegistrationEmailVerificationPhase.verified,
        ),
      );
      return;
    }

    if (verified && data['hasProfile'] == true) {
      throw const AppException(
        'A user profile with this email already exists.',
      );
    }
  }

  Future<void> cancelPending(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    try {
      if (kIsWeb) {
        await _runRegistrationJob(action: 'cancel', email: normalized);
      } else {
        await _functions
            .httpsCallable('adminCancelRegistrationEmailVerification')
            .call<Map<String, dynamic>>({'email': normalized});
      }
    } catch (_) {}
    await reset();
  }

  Future<void> finalizePassword(String password) async {
    final user = _auth?.currentUser;
    if (user == null) {
      throw const AppException('Email verification session expired.');
    }
    await user.updatePassword(password);
  }

  Future<Map<String, dynamic>> _runRegistrationJob({
    required String action,
    required String email,
  }) async {
    final callerUid = FirebaseAuth.instance.currentUser?.uid;
    if (callerUid == null || callerUid.isEmpty) {
      throw const AppException('Sign in again to verify registration emails.');
    }

    final ref = _firestore
        .collection('registration_email_verification_jobs')
        .doc();
    await ref.set({
      'action': action,
      'email': email,
      'requestedByUid': callerUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    const attempts = 45;
    const delay = Duration(seconds: 1);
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(delay);
      }
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) {
        continue;
      }
      final status = data['status']?.toString();
      if (status == 'ready') {
        return Map<String, dynamic>.from(data);
      }
      if (status == 'failed') {
        throw AppException(
          registrationJobErrorMessage(
            data['errorCode']?.toString(),
            data['errorMessage']?.toString(),
          ),
        );
      }
    }

    throw const AppException(
      'Verification service timed out. Deploy '
      'dispatchRegistrationEmailVerificationJob and Firestore rules, then try again.',
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_pollOnce());
    });
  }

  Future<void> _pollOnce() async {
    final user = _auth?.currentUser;
    if (user == null) {
      return;
    }
    await user.reload();
    final refreshed = _auth?.currentUser;
    if (refreshed?.emailVerified == true) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _emit(
        _snapshot.copyWith(
          uid: refreshed!.uid,
          phase: RegistrationEmailVerificationPhase.verified,
          clearError: true,
        ),
      );
    }
  }
}

String registrationFunctionsErrorMessage(FirebaseFunctionsException error) {
  final message = error.message?.trim();
  if (message != null && message.isNotEmpty) {
    return message;
  }
  return registrationJobErrorMessage(error.code, message);
}

String registrationJobErrorMessage(String? code, String? message) {
  final combined = '${code ?? ''} ${message ?? ''}'.toLowerCase();
  if (combined.contains('signblob') ||
      combined.contains('serviceaccounts.signblob') ||
      combined.contains('token creator')) {
    return 'Cloud Functions cannot create a verification session (missing '
        'Service Account Token Creator on the function runtime account). '
        'In Google Cloud IAM, grant roles/iam.serviceAccountTokenCreator to '
        'salesiren-5539c@appspot.gserviceaccount.com — see '
        'docs/firebase-functions-deployment.md.';
  }
  final trimmed = message?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return switch (code) {
    'unauthenticated' => 'Sign in again to verify registration emails.',
    'permission-denied' => 'Only owners can verify registration emails.',
    'already-exists' => 'This email is already registered or verified.',
    'invalid-argument' => 'Enter a valid email address.',
    _ => 'Could not verify this email right now. Please try again.',
  };
}

String registrationVerificationNetworkMessage(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('cors') ||
      text.contains('failed to fetch') ||
      text.contains('network') ||
      text.contains('xmlhttprequest')) {
    return 'Could not reach the verification service from this browser. '
        'On web, registration email verification uses Firestore jobs instead of '
        'direct callables. Deploy dispatchRegistrationEmailVerificationJob and '
        'Firestore rules, then try again.';
  }
  return 'Could not verify this email right now. Please try again.';
}
