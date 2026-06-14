import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_providers.dart';
import '../../data/repositories/firebase_notifications_repository.dart';
import '../../domain/entities/notification_request.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return FirebaseNotificationsRepository(ref.watch(firestoreProvider));
});

final createNotificationRequestProvider =
    Provider<Future<String> Function(NotificationRequest)>((ref) {
      return ref
          .watch(notificationsRepositoryProvider)
          .createBroadcastRequest;
    });
