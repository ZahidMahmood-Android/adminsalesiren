class ErrorMessages {
  const ErrorMessages._();

  static String friendly(Object? error) {
    final rawText = error.toString();
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
    if (text.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (text.contains('firebase auth is not configured') ||
        text.contains('configuration-not-found')) {
      return 'Firebase Auth is not configured for this app.';
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
    if (!rawText.contains('Exception') &&
        !rawText.contains('Firebase') &&
        !rawText.contains(']') &&
        rawText.trim().isNotEmpty) {
      return rawText;
    }

    return 'Something went wrong. Please try again.';
  }
}
