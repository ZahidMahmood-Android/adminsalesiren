import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_logger.dart';

/// Debug logging when the admin panel schedules FCM dispatch via [offer_push_jobs].
class PushDispatchDebugLogger {
  PushDispatchDebugLogger._();

  static final _log = AppLogger.get('PushDispatch');

  static String _maskToken(String token) {
    final trimmed = token.trim();
    if (trimmed.length <= 16) {
      return trimmed;
    }
    return '${trimmed.substring(0, 8)}…${trimmed.substring(trimmed.length - 6)}';
  }

  static List<String> _readFcmTokens(Map<String, dynamic> data) {
    final tokens = <String>{};
    final rawTokens = data['fcmTokens'];
    if (rawTokens is Iterable) {
      for (final value in rawTokens) {
        if (value is String && value.trim().isNotEmpty) {
          tokens.add(value.trim());
        }
      }
    }
    final legacy = data['fcmToken'];
    if (legacy is String && legacy.trim().isNotEmpty) {
      tokens.add(legacy.trim());
    }
    return tokens.toList();
  }

  static bool _isMobileRecipient(Map<String, dynamic> data) {
    if (data['notificationEnabled'] == false || data['isActive'] == false) {
      return false;
    }
    const privileged = {'owner', 'admin', 'brand_admin', 'manager'};
    final roles = <String>[];
    final rawRoles = data['roles'];
    if (rawRoles is Iterable) {
      for (final role in rawRoles) {
        if (role is String && role.trim().isNotEmpty) {
          roles.add(role.trim());
        }
      }
    }
    final singleRole = data['role'];
    if (singleRole is String && singleRole.trim().isNotEmpty) {
      roles.add(singleRole.trim());
    }
    for (final role in roles) {
      if (privileged.contains(role)) {
        return false;
      }
    }
    if (roles.isEmpty) {
      return true;
    }
    return roles.contains('mobile_user');
  }

  static void logScheduledJob({
    required String jobId,
    required String offerId,
    String? offerLineId,
    String? requestId,
    required String requestedByUserId,
  }) {
    _log.info(
      'Scheduled offer_push_jobs/$jobId '
      'offerId=$offerId '
      'offerLineId=${offerLineId ?? ''} '
      'requestId=${requestId ?? ''} '
      'requestedBy=$requestedByUserId '
      '(Cloud Function dispatchOfferPushOnJob must be deployed)',
    );
  }

  /// Lists mobile users with FCM tokens — mirrors Cloud Function recipient rules.
  static Future<void> logMobileRecipients(FirebaseFirestore firestore) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'mobile_user')
          .limit(200)
          .get();

      final recipients = <Map<String, Object?>>[];
      var skippedNoTokens = 0;
      var skippedNotEligible = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!_isMobileRecipient(data)) {
          skippedNotEligible++;
          continue;
        }
        final tokens = _readFcmTokens(data);
        if (tokens.isEmpty) {
          skippedNoTokens++;
          _log.info(
            'Push recipient skipped (no fcmTokens): '
            'userId=${doc.id} '
            'email=${data['email'] ?? ''} '
            'notificationEnabled=${data['notificationEnabled']}',
          );
          continue;
        }
        recipients.add({
          'userId': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? data['fullName'] ?? '',
          'notificationEnabled': data['notificationEnabled'] ?? true,
          'tokenCount': tokens.length,
          'tokens': tokens.map(_maskToken).join(', '),
        });
      }

      _log.info(
        'Push dispatch preview: ${recipients.length} mobile user(s) with FCM tokens '
        '(queried=${snapshot.size}, skippedNoTokens=$skippedNoTokens, '
        'skippedNotEligible=$skippedNotEligible)',
      );
      for (final recipient in recipients) {
        _log.info(
          'Push recipient userId=${recipient['userId']} '
          'email=${recipient['email']} '
          'displayName=${recipient['displayName']} '
          'notificationEnabled=${recipient['notificationEnabled']} '
          'tokenCount=${recipient['tokenCount']} '
          'tokens=${recipient['tokens']}',
        );
      }

      if (recipients.isEmpty) {
        _log.warning(
          'No mobile users with fcmTokens found. '
          'Ensure the mobile app is signed in, notifications are enabled, '
          'and users/{uid}.fcmTokens is populated.',
        );
      }
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to load mobile FCM recipients for push debug',
        error,
        stackTrace,
      );
    }
  }
}
