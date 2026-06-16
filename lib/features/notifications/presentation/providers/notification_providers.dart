import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../offers/presentation/providers/offer_providers.dart';
import '../../data/repositories/firebase_notifications_repository.dart';
import '../../domain/entities/notification_request.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  return FirebaseNotificationsRepository(
    ref.watch(firestoreProvider),
    user?.id ?? '',
    user?.role ?? 'super_admin',
    user?.brandId ?? '',
  );
});

final notificationRequestsProvider =
    StreamProvider.autoDispose<List<NotificationRequest>>((ref) {
      return ref.watch(notificationsRepositoryProvider).watchRequests();
    });

final createNotificationRequestProvider =
    Provider<Future<String> Function(NotificationRequest)>((ref) {
      return ref.watch(notificationsRepositoryProvider).createBroadcastRequest;
    });

final notificationRequestActionsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationRequestActionsController,
      void
    >(NotificationRequestActionsController.new);

class NotificationRequestActionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateStatus(
    String id,
    String status, {
    String notes = '',
  }) async {
    final user = ref.read(currentUserProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(notificationsRepositoryProvider)
          .updateRequestStatus(
            id,
            status,
            adminNotes: notes,
            approvedBy: user?.id ?? '',
          ),
    );
  }

  Future<void> publishRequest({
    required String requestId,
    required String offerId,
  }) async {
    final user = ref.read(currentUserProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(offersRepositoryProvider).publishOffer(offerId, true);
      await ref
          .read(notificationsRepositoryProvider)
          .updateRequestStatus(
            requestId,
            'approved',
            approvedBy: user?.id ?? '',
          );
    });
  }
}
