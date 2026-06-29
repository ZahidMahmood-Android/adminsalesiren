import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../widgets/app_error_dialog.dart';
import 'offer_push_dispatch_service.dart';

/// User-facing copy for offer push / FCM dispatch outcomes.
class PushDispatchUserMessages {
  const PushDispatchUserMessages._();

  static const noMatchingAudienceCode = 'push-dispatch-no-audience';
  static const noFcmTokensCode = 'push-dispatch-no-fcm-tokens';

  static void ensureDelivered(OfferPushDispatchResult? result) {
    if (result == null) {
      throw const AppException(
        'We could not confirm whether the push notification was sent. '
        'Make sure Cloud Functions are deployed, wait a minute, and try again.',
        code: 'push-dispatch-timeout',
      );
    }
    if (result.skipped) {
      throw AppException(
        skippedMessage(result.reason),
        code: 'push-dispatch-skipped',
      );
    }
    if (result.successCount > 0) {
      return;
    }
    throw AppException(
      failureMessage(result),
      code: failureCode(result),
    );
  }

  static String failureCode(OfferPushDispatchResult result) {
    if (result.dispatchReason == 'no_matching_audience') {
      return noMatchingAudienceCode;
    }
    if (result.dispatchReason == 'no_fcm_tokens') {
      return noFcmTokensCode;
    }
    if (result.matchedUserCount == 0 &&
        result.recipientCount == 0 &&
        result.tokenCount == 0) {
      return noMatchingAudienceCode;
    }
    return 'push-dispatch-failed';
  }

  static String successMessage(OfferPushDispatchResult result) {
    final count = result.successCount;
    if (count == 1) {
      return 'Push notification sent to 1 mobile device.';
    }
    return 'Push notification sent to $count mobile devices.';
  }

  static String failureMessage(OfferPushDispatchResult result) {
    final reason = result.reason?.trim();
    if (reason != null && reason.isNotEmpty) {
      if (result.dispatchReason == 'no_matching_audience' ||
          result.dispatchReason == 'no_fcm_tokens') {
        return reason;
      }
    }

    if (result.dispatchReason == 'no_matching_audience' ||
        (result.matchedUserCount == 0 &&
            result.recipientCount == 0 &&
            result.tokenCount == 0)) {
      return reason ??
          'No notification was sent because no mobile users follow this category or brand. '
              'Users must select matching categories or save the brand in the app first.';
    }

    if (result.dispatchReason == 'no_fcm_tokens' ||
        (result.matchedUserCount > 0 && result.tokenCount == 0)) {
      return reason ??
          'Matching mobile users were found, but none have a notification token yet. '
              'Ask them to sign in on the mobile app, turn notifications on, '
              'and open the app once before you resend.';
    }

    if (result.tokenCount == 0) {
      return 'No mobile users have a notification token yet. '
          'Ask users to sign in on the mobile app, turn notifications on, '
          'and open the app once before you resend.';
    }

    final technical = reason;
    if (technical != null && technical.isNotEmpty) {
      return friendlyTechnicalError(technical);
    }

    if (result.invalidTokenCount >= result.tokenCount) {
      return 'The stored notification tokens look outdated. '
          'Open the mobile app while signed in, then resend.';
    }

    return 'The push notification could not be delivered. '
        'Check Firebase Cloud Functions logs or try again in a minute.';
  }

  static String skippedMessage(String? reason) {
    final normalized = reason?.trim().toLowerCase() ?? '';
    if (normalized == 'already_dispatched') {
      return 'This notification was already sent recently. Wait a moment, then resend if needed.';
    }
    if (normalized == 'in_progress') {
      return 'A push for this request is already in progress. Please wait and try again.';
    }
    if (normalized == 'missing') {
      return 'The push job was not found. Try publishing or resending again.';
    }
    return 'Push dispatch was skipped. Please try again.';
  }

  static String friendlyTechnicalError(String raw) {
    final text = raw.toLowerCase();

    if (text.contains('cloudmessaging.messages.create') ||
        text.contains('firebasemessaging.admin') ||
        (text.contains('permission denied') &&
            text.contains('cloudmessaging'))) {
      return 'Cloud Functions cannot send push notifications yet. '
          'Redeploy functions (they must run as salesiren-5539c@appspot.gserviceaccount.com), '
          'then ask a project admin to grant that account Firebase Admin '
          '(`roles/firebase.admin`) in Google Cloud IAM. '
          'See docs/firebase-functions-deployment.md.';
    }

    if (text.contains('third-party-auth-error') ||
        text.contains('apns') ||
        text.contains('auth error from apn')) {
      return 'iOS push is not configured in Firebase. Upload your APNs key under '
          'Firebase Console → Project settings → Cloud Messaging, then resend.';
    }

    if (text.contains('sender-id-mismatch')) {
      return 'The mobile app notification token does not match this Firebase project. '
          'Reopen the mobile app while signed in, then resend.';
    }

    if (text.contains('invalid-registration-token') ||
        text.contains('registration-token-not-registered')) {
      return 'The mobile notification token is no longer valid. '
          'Open the mobile app while signed in, then resend.';
    }

    if (text.contains('not-found') && text.contains('sendofferpush')) {
      return 'The sendOfferPush Cloud Function is not deployed. '
          'Deploy functions for project salesiren-5539c, then try again.';
    }

    if (text.contains('unauthenticated')) {
      return 'Your admin session expired. Sign in again, then resend the notification.';
    }

    if (text.contains('permission-denied')) {
      return 'Your account is not allowed to send push notifications.';
    }

    return 'Push delivery failed: ${_shortTechnicalDetail(raw)}';
  }

  static String _shortTechnicalDetail(String raw) {
    final cleaned = raw
        .replaceFirst(RegExp(r'^messaging/'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= 160) {
      return cleaned;
    }
    return '${cleaned.substring(0, 157)}…';
  }
}

Future<void> showNotificationDispatchError(
  BuildContext context,
  Object? error,
) {
  if (error is AppException &&
      error.code == PushDispatchUserMessages.noMatchingAudienceCode) {
    showAppSuccess(context, error.message);
    return Future.value();
  }
  return showAppError(context, error, title: 'Notification not sent');
}

void showNotificationDispatchSuccess(
  BuildContext context,
  OfferPushDispatchResult result,
) {
  showAppSuccess(context, PushDispatchUserMessages.successMessage(result));
}
