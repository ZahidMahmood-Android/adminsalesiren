import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

class OfferPushDispatchResult {
  const OfferPushDispatchResult({
    required this.skipped,
    required this.successCount,
    required this.recipientCount,
    required this.tokenCount,
    required this.invalidTokenCount,
    this.reason,
    this.requestId,
  });

  final bool skipped;
  final int successCount;
  final int recipientCount;
  final int tokenCount;
  final int invalidTokenCount;
  final String? reason;
  final String? requestId;

  factory OfferPushDispatchResult.fromMap(Map<String, dynamic> data) {
    return OfferPushDispatchResult(
      skipped: data['skipped'] == true || data['skipped'] == 'true',
      successCount: _readInt(data['successCount']),
      recipientCount: _readInt(data['recipientCount']),
      tokenCount: _readInt(data['tokenCount']),
      invalidTokenCount: _readInt(data['invalidTokenCount']),
      reason: data['reason']?.toString(),
      requestId: data['requestId']?.toString(),
    );
  }

  static int _readInt(Object? value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Walks callable payloads without [jsonEncode] (avoids Int64 on web).
  static Map<String, dynamic> normalizeCallableData(dynamic data) {
    final converted = _deepConvertValue(data);
    if (converted is Map<String, dynamic>) {
      return converted;
    }
    if (converted is Map) {
      return Map<String, dynamic>.from(converted);
    }
    return {};
  }

  static dynamic _deepConvertValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), _deepConvertValue(nested)),
      );
    }
    if (value is Iterable && value is! String) {
      return value.map(_deepConvertValue).toList();
    }
    if (value is bool || value is String) {
      return value;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value;
    }
    final text = value.toString();
    return int.tryParse(text) ?? double.tryParse(text) ?? text;
  }
}

/// Invokes the `sendOfferPush` Cloud Function for immediate FCM delivery.
class OfferPushDispatchService {
  OfferPushDispatchService(this._functions);

  static const _region = 'us-central1';
  static final _log = AppLogger.get('PushDispatch');

  final FirebaseFunctions _functions;

  Future<OfferPushDispatchResult?> dispatchNow({
    required FirebaseFirestore firestore,
    required String offerId,
    required String jobId,
    String? offerLineId,
    String? requestId,
  }) async {
    if (kIsWeb) {
      _log.info(
        'Skipping sendOfferPush callable on web; waiting for offer_push_jobs trigger jobId=$jobId',
      );
    } else {
      try {
        await _invokeSendOfferPush(
          offerId: offerId,
          jobId: jobId,
          offerLineId: offerLineId,
          requestId: requestId,
        );
      } on FirebaseFunctionsException catch (error, stackTrace) {
        if (error.code == 'not-found') {
          _log.warning(
            'sendOfferPush Cloud Function is not deployed. '
            'Run: firebase deploy --only functions:sendOfferPush,functions:dispatchOfferPushOnJob '
            '--project salesiren-5539c',
            error,
            stackTrace,
          );
        } else {
          _log.warning(
            'sendOfferPush callable failed code=${error.code} message=${error.message}',
            error,
            stackTrace,
          );
        }
      } catch (error, stackTrace) {
        if (!_isCallableResponseParseError(error)) {
          _log.warning('sendOfferPush callable failed', error, stackTrace);
        }
      }
    }

    final result = await _readJobResult(firestore, jobId);
    _logDispatchResult(offerId: offerId, jobId: jobId, result: result);
    return result;
  }

  Future<void> _invokeSendOfferPush({
    required String offerId,
    required String jobId,
    String? offerLineId,
    String? requestId,
  }) async {
    final callable = _functions.httpsCallable(
      'sendOfferPush',
      options: HttpsCallableOptions(limitedUseAppCheckToken: true),
    );
    try {
      await callable.call({
        'offerId': offerId,
        'jobId': jobId,
        'offerLineId': offerLineId ?? '',
        'requestId': requestId ?? '',
      });
    } on UnsupportedError {
      // Web dart2js: cloud_functions fails parsing the response after the function runs.
      if (kIsWeb) {
        _log.fine(
          'sendOfferPush response parse skipped on web; reading Firestore job $jobId',
        );
        return;
      }
      rethrow;
    } catch (error) {
      if (_isCallableResponseParseError(error)) {
        if (kIsWeb) {
          _log.fine(
            'sendOfferPush response parse skipped on web; reading Firestore job $jobId',
          );
          return;
        }
      }
      rethrow;
    }
  }

  static bool _isCallableResponseParseError(Object error) {
    return error is UnsupportedError ||
        error.toString().contains('Int64 accessor not supported');
  }

  static Future<OfferPushDispatchResult?> _readJobResult(
    FirebaseFirestore firestore,
    String jobId,
  ) async {
    const attempts = 90;
    const delay = Duration(seconds: 1);
    for (var i = 0; i < attempts; i++) {
      final snapshot = await firestore
          .collection('offer_push_jobs')
          .doc(jobId)
          .get();
      final data = snapshot.data();
      if (data == null) {
        await Future<void>.delayed(delay);
        continue;
      }
      if (_isJobDispatchFinished(data)) {
        return OfferPushDispatchResult.fromMap({
          'skipped': false,
          'successCount': data['sentCount'],
          'recipientCount': data['recipientCount'],
          'tokenCount': data['tokenCount'],
          'invalidTokenCount': data['invalidTokenCount'],
          'reason': data['lastFcmError'] ?? data['lastError'],
        });
      }
      await Future<void>.delayed(delay);
    }
    return null;
  }

  static bool _isJobDispatchFinished(Map<String, dynamic> data) {
    if (data['dispatchCompletedAt'] != null || data['lastError'] != null) {
      return true;
    }
    if (data['dispatchInProgress'] != true && data['sentCount'] != null) {
      return true;
    }
    return false;
  }

  void _logDispatchResult({
    required String offerId,
    required String jobId,
    required OfferPushDispatchResult? result,
  }) {
    if (result == null) {
      _log.warning(
        'FCM dispatch finished with no job result offerId=$offerId jobId=$jobId. '
        'Check offer_push_jobs/$jobId and Firebase Function logs for dispatchOfferPushOnJob.',
      );
      return;
    }
    _log.info(
      'FCM dispatch finished offerId=$offerId jobId=$jobId '
      'successCount=${result.successCount} '
      'recipientCount=${result.recipientCount} '
      'tokenCount=${result.tokenCount} '
      'invalidTokenCount=${result.invalidTokenCount}',
    );
    if (result.successCount == 0) {
      final fcmDetail = result.reason?.trim();
      if (result.tokenCount == 0) {
        _log.warning(
          'FCM dispatch sent 0 notifications: no mobile users with FCM tokens. '
          'Sign in on the mobile app, enable notifications, then resend.',
        );
      } else if (fcmDetail != null && fcmDetail.isNotEmpty) {
        _log.warning(
          'FCM dispatch sent 0 notifications (${result.tokenCount} token(s) tried). '
          'FCM error: $fcmDetail',
        );
      } else if (result.invalidTokenCount >= result.tokenCount) {
        _log.warning(
          'FCM dispatch sent 0 notifications: all ${result.tokenCount} token(s) '
          'were rejected as invalid. Reopen the mobile app to register a fresh token, '
          'then resend.',
        );
      } else {
        _log.warning(
          'FCM dispatch sent 0 notifications: ${result.tokenCount} token(s) tried, '
          '${result.invalidTokenCount} invalid. Redeploy Cloud Functions and check '
          'Firebase Functions logs for FCM errors.',
        );
      }
    }
  }

  static OfferPushDispatchService create() {
    return OfferPushDispatchService(
      FirebaseFunctions.instanceFor(region: _region),
    );
  }
}
