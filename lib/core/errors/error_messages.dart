import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

class ErrorMessages {
  const ErrorMessages._();

  static String friendly(Object? error) {
    if (error == null) {
      return 'Something went wrong. Please try again.';
    }
    if (error is AppException) {
      return error.message;
    }
    if (error is StateError) {
      final message = error.message.trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    if (error is FirebaseAuthException) {
      return _authCodeMessage(error.code) ??
          _cleanOrNull(error.message) ??
          'Unable to complete this sign-in action. Please try again.';
    }
    if (error is FirebaseException) {
      return _firestoreCodeMessage(error.code) ??
          _cleanOrNull(error.message) ??
          'Unable to complete this request. Please try again.';
    }

    final rawText = error.toString();

    // AppException used to format as "code: message" — strip the code prefix.
    final codePrefix = RegExp(r'^[a-z0-9-]+:\s+(.+)$', caseSensitive: false);
    final codeMatch = codePrefix.firstMatch(rawText.trim());
    if (codeMatch != null) {
      return codeMatch.group(1)!.trim();
    }

    // Firebase exceptions are formatted as "[plugin/code] Human message".
    final extractedMessage = _extractFirebaseMessage(rawText);
    if (extractedMessage != null) {
      return extractedMessage;
    }

    final text = rawText.toLowerCase();

    if (text.contains('the email or password is incorrect') ||
        text.contains('invalid-credential') ||
        text.contains('wrong-password')) {
      return 'The email or password is incorrect.';
    }
    if (text.contains('no admin account exists') ||
        text.contains('user-not-found')) {
      return 'No admin account exists for this email.';
    }
    if (text.contains('enter a valid admin email') ||
        text.contains('invalid-email')) {
      return 'Enter a valid admin email address.';
    }
    if (text.contains('admin account is disabled') ||
        text.contains('user-disabled')) {
      return 'This admin account is disabled.';
    }
    if (text.contains('email-already-in-use') ||
        text.contains('already registered')) {
      return 'This email is already registered. Use a different email address.';
    }
    if (text.contains('weak-password')) {
      return 'The password is too weak. Use at least 6 characters.';
    }
    if (text.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (text.contains('firebase auth is not configured') ||
        text.contains('configuration-not-found')) {
      return 'Sign-in is not available right now. Please contact support.';
    }

    if (text.contains('permission-denied') || text.contains('permission')) {
      return 'You do not have permission to perform this action.';
    }
    if (text.contains('unavailable') ||
        text.contains('network') ||
        text.contains('socket') ||
        text.contains('timeout')) {
      return 'We could not connect right now. Please check your internet and try again.';
    }
    if (text.contains('not-found')) {
      return 'The requested record could not be found.';
    }
    if (text.contains('already-exists') || text.contains('duplicate')) {
      return 'A record with this information already exists.';
    }
    if (text.contains('invalid-argument') ||
        text.contains('failed-precondition')) {
      return 'This request could not be completed. Please review the information and try again.';
    }
    if (text.startsWith('bad state:')) {
      return rawText
          .replaceFirst(RegExp(r'^bad state:\s*', caseSensitive: false), '')
          .trim();
    }
    if (!rawText.contains('Exception') &&
        !rawText.contains('Firebase') &&
        !rawText.contains(']') &&
        rawText.trim().isNotEmpty) {
      return rawText.trim();
    }

    return 'Something went wrong. Please try again.';
  }

  static String? _cleanOrNull(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    if (cleaned.startsWith('[')) {
      return _extractFirebaseMessage(cleaned);
    }
    return cleaned;
  }

  static String? _authCodeMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account is disabled.',
      'user-not-found' => 'No account exists for this email.',
      'wrong-password' => 'The password is incorrect.',
      'invalid-credential' => 'The email or password is incorrect.',
      'email-already-in-use' =>
        'This email is already registered. Use a different email address.',
      'weak-password' => 'The password is too weak. Use at least 6 characters.',
      'operation-not-allowed' =>
        'Email sign-in is not enabled. Please contact support.',
      'network-request-failed' =>
        'We could not connect right now. Please check your internet and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'requires-recent-login' =>
        'Please sign out, sign in again, and retry this action.',
      'configuration-not-found' =>
        'Sign-in is not available right now. Please contact support.',
      _ => null,
    };
  }

  static String? _firestoreCodeMessage(String code) {
    return switch (code) {
      'permission-denied' =>
        'You do not have permission to perform this action.',
      'unavailable' =>
        'We could not connect right now. Please check your internet and try again.',
      'not-found' => 'The requested record could not be found.',
      'already-exists' => 'A record with this information already exists.',
      'failed-precondition' =>
        'This request could not be completed. Please review the information and try again.',
      'invalid-argument' =>
        'Some information looks invalid. Please review and try again.',
      _ => null,
    };
  }

  /// Extracts the human-readable message from Firebase-style error strings
  /// formatted as "[plugin/code] Some message here.".
  static String? _extractFirebaseMessage(String raw) {
    final match = RegExp(
      r'^\[[\w/.-]+\]\s+(.+)$',
      dotAll: true,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final msg = match.group(1)?.trim() ?? '';
    if (msg.isEmpty) return null;
    if (msg.startsWith('[')) return null;
    return msg;
  }
}
