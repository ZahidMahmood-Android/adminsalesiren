import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/app_logger.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

final adminAccessProvider = FutureProvider<bool>((ref) async {
  final log = AppLogger.get('AdminAccessProvider');
  final user =
      ref.watch(authStateProvider).value ??
      ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    log.fine('No user signed in');
    return false;
  }

  log.info('Checking admin access for uid=${user.id}');

  try {
    // Use a timeout to prevent hanging if Firestore is slow
    final snapshot = await ref
        .watch(firestoreProvider)
        .collection('admins')
        .doc(user.id)
        .get()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            log.warning('Admin access check timeout for uid=${user.id}');
            // Return empty snapshot instead of timing out
            throw TimeoutException(
              'Admin check timeout',
              const Duration(seconds: 5),
            );
          },
        );

    final exists = snapshot.exists;
    log.fine('Admin document exists: $exists for uid=${user.id}');
    return exists;
  } catch (error, stack) {
    log.warning('Admin access check failed for uid=${user.id}', error, stack);
    // Return false if check fails (safe fallback)
    return false;
  }
});

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );

class LoginController extends AsyncNotifier<void> {
  final _log = AppLogger.get('LoginController');

  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    _log.info('Login action submitted');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email, password),
    );
    if (state.hasError) {
      _log.warning('Login action failed', state.error, state.stackTrace);
    } else {
      _log.info('Login action completed');
    }
  }
}
