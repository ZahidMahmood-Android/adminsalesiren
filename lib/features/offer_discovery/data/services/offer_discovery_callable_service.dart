import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/discovered_offers_repository.dart';

class OfferDiscoveryCallableService {
  OfferDiscoveryCallableService(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<OfferDiscoveryRunResult> runDiscoveryNow() async {
    if (kIsWeb) {
      return _runDiscoveryJob();
    }
    final callable = _functions.httpsCallable('runDiscoverBrandOffers');
    final response = await callable.call<Map<String, dynamic>>({});
    return OfferDiscoveryRunResult.fromMap(response.data);
  }

  Future<OfferDiscoveryRunResult> _runDiscoveryJob() async {
    final callerUid = FirebaseAuth.instance.currentUser?.uid;
    if (callerUid == null || callerUid.isEmpty) {
      throw const AppException('Sign in again to run offer discovery.');
    }

    final ref = _firestore.collection('offer_discovery_jobs').doc();
    await ref.set({
      'requestedByUid': callerUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    const attempts = 180;
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
        return OfferDiscoveryRunResult.fromMap(Map<String, dynamic>.from(data));
      }
      if (status == 'failed') {
        throw AppException(
          _jobErrorMessage(
            data['errorCode']?.toString(),
            data['errorMessage']?.toString(),
          ),
        );
      }
    }

    throw const AppException(
      'Offer discovery timed out. Deploy dispatchOfferDiscoveryJob and '
      'Firestore rules, then try again.',
    );
  }
}

String _jobErrorMessage(String? code, String? message) {
  final trimmed = message?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return switch (code) {
    'unauthenticated' => 'Sign in again to run offer discovery.',
    'permission-denied' => 'You do not have permission to run offer discovery.',
    _ => 'Could not run offer discovery right now. Please try again.',
  };
}
