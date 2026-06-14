import '../entities/notification_request.dart';

abstract class NotificationsRepository {
  Future<String> createBroadcastRequest(NotificationRequest request);
}
