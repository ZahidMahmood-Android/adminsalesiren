import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/offer_push_dispatch_service.dart';
import '../../../offers/presentation/providers/offer_providers.dart';
import '../../data/repositories/firebase_notifications_repository.dart';
import '../../domain/entities/notification_request.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  final isOwner = ref.watch(isOwnerProvider);
  final isManager = ref.watch(isManagerProvider);
  return FirebaseNotificationsRepository(
    ref.watch(firestoreProvider),
    user?.id ?? '',
    canSeeAllRequests: isOwner || isManager,
  );
});

final notificationRequestsProvider =
    StreamProvider.autoDispose<List<NotificationRequest>>((ref) {
      final offersAsync = ref.watch(offersProvider);
      return ref.watch(notificationsRepositoryProvider).watchRequests().map((
        requests,
      ) {
        final offers = offersAsync.value;
        if (offers == null || offers.isEmpty) {
          return requests;
        }
        final expiredOfferIds = offers
            .where((offer) => offer.isExpired)
            .map((offer) => offer.id)
            .toSet();
        if (expiredOfferIds.isEmpty) {
          return requests;
        }
        return requests
            .where(
              (request) =>
                  request.offerId.isEmpty ||
                  !expiredOfferIds.contains(request.offerId),
            )
            .toList();
      });
    });

final notificationRequestsListSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

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
  static final _log = AppLogger.get('NotificationRequestActions');

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
    String offerLineId = '',
    bool sendNotification = true,
  }) async {
    final user = ref.read(currentUserProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _log.info(
        'Publishing notification request requestId=$requestId '
        'offerId=$offerId offerLineId=${offerLineId.isEmpty ? '' : offerLineId} '
        'sendNotification=$sendNotification',
      );
      await ref
          .read(notificationsRepositoryProvider)
          .updateRequestStatus(
            requestId,
            'approved',
            approvedBy: user?.id ?? '',
            adminNotes: sendNotification
                ? ''
                : 'Published without push notification.',
          );
      if (offerLineId.isNotEmpty) {
        await ref
            .read(offersRepositoryProvider)
            .publishOfferLine(
              offerId,
              offerLineId,
              requestId: requestId,
              sendNotification: sendNotification,
            );
      } else {
        await ref
            .read(offersRepositoryProvider)
            .publishOffer(
              offerId,
              true,
              requestId: requestId,
              sendNotification: sendNotification,
            );
      }
      _log.info(
        'Notification request publish finished requestId=$requestId offerId=$offerId',
      );
    });
  }

  Future<void> publishAllForOffer(
    String offerId, {
    bool sendNotification = true,
  }) async {
    final requests = await ref.read(notificationRequestsProvider.future);
    final pending = requests
        .where(
          (request) =>
              request.offerId == offerId &&
              request.status == 'pending' &&
              request.offerId.isNotEmpty,
        )
        .toList();
    for (final request in pending) {
      await publishRequest(
        requestId: request.id,
        offerId: request.offerId,
        offerLineId: request.offerLineId,
        sendNotification: sendNotification,
      );
    }
  }

  Future<void> publishAllPending({bool sendNotification = true}) async {
    final requests = await ref.read(notificationRequestsProvider.future);
    final pending = requests
        .where(
          (request) =>
              request.status == 'pending' && request.offerId.isNotEmpty,
        )
        .toList();
    for (final request in pending) {
      await publishRequest(
        requestId: request.id,
        offerId: request.offerId,
        offerLineId: request.offerLineId,
        sendNotification: sendNotification,
      );
    }
  }

  Future<void> publishPendingRequests(
    Iterable<NotificationRequest> requests, {
    bool sendNotification = true,
  }) async {
    for (final request in requests) {
      if (request.status != 'pending' || request.offerId.isEmpty) {
        continue;
      }
      await publishRequest(
        requestId: request.id,
        offerId: request.offerId,
        offerLineId: request.offerLineId,
        sendNotification: sendNotification,
      );
      if (state.hasError) {
        return;
      }
    }
  }

  Future<void> saveRequest(NotificationRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).updateRequest(request),
    );
  }

  Future<void> deleteRequest(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).deleteRequest(id),
    );
  }

  Future<OfferPushDispatchResult> resendNotification(
    NotificationRequest request,
  ) async {
    if (request.offerId.isEmpty) {
      throw const AppException(
        'This request is not linked to an offer.',
        code: 'notification-request-missing-offer',
      );
    }
    state = const AsyncLoading();
    try {
      _log.info(
        'Resend notification requestId=${request.id} offerId=${request.offerId}',
      );
      final result = await ref
          .read(offersRepositoryProvider)
          .resendOfferNotification(
            offerId: request.offerId,
            offerLineId: request.offerLineId,
            requestId: request.id,
          );
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
