import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/services/registration_email_verification_service.dart';

final registrationEmailVerificationServiceProvider =
    Provider.autoDispose<RegistrationEmailVerificationService>((ref) {
      final service = RegistrationEmailVerificationService(
        ref.watch(firebaseFunctionsProvider),
        ref.watch(firestoreProvider),
      );
      ref.onDispose(service.dispose);
      return service;
    });

final registrationEmailVerificationProvider =
    NotifierProvider.autoDispose<
      RegistrationEmailVerificationNotifier,
      RegistrationEmailVerificationSnapshot
    >(RegistrationEmailVerificationNotifier.new);

class RegistrationEmailVerificationNotifier
    extends Notifier<RegistrationEmailVerificationSnapshot> {
  StreamSubscription<RegistrationEmailVerificationSnapshot>? _subscription;

  @override
  RegistrationEmailVerificationSnapshot build() {
    final service = ref.watch(registrationEmailVerificationServiceProvider);
    _subscription?.cancel();
    _subscription = service.stream.listen((next) {
      state = next;
    });
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });
    return service.snapshot;
  }

  void syncFromService() {
    state = ref.read(registrationEmailVerificationServiceProvider).snapshot;
  }
}

Future<void> startRegistrationEmailVerification(
  WidgetRef ref,
  String email,
) async {
  final service = ref.read(registrationEmailVerificationServiceProvider);
  try {
    await service.startVerification(email);
    ref.read(registrationEmailVerificationProvider.notifier).syncFromService();
  } on FirebaseFunctionsException catch (error) {
    throw AppException(registrationFunctionsErrorMessage(error));
  } catch (error) {
    throw AppException(registrationVerificationNetworkMessage(error));
  }
}

Future<void> resendRegistrationEmailVerification(WidgetRef ref) async {
  await ref
      .read(registrationEmailVerificationServiceProvider)
      .resendVerification();
}

Future<void> refreshRegistrationEmailVerification(
  WidgetRef ref,
  String email,
) async {
  final service = ref.read(registrationEmailVerificationServiceProvider);
  await service.refreshStatus(email: email);
  ref.read(registrationEmailVerificationProvider.notifier).syncFromService();
}

Future<void> resetRegistrationEmailVerification(WidgetRef ref) async {
  final service = ref.read(registrationEmailVerificationServiceProvider);
  await service.reset();
  ref.read(registrationEmailVerificationProvider.notifier).syncFromService();
}

Future<void> cancelRegistrationEmailVerification(
  WidgetRef ref,
  String email,
) async {
  final service = ref.read(registrationEmailVerificationServiceProvider);
  await service.cancelPending(email);
  ref.read(registrationEmailVerificationProvider.notifier).syncFromService();
}
