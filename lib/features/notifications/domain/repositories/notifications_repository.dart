import '../entities/notification_request.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationRequest>> watchRequests();
  Future<String> createBroadcastRequest(NotificationRequest request);
  Future<void> updateRequest(NotificationRequest request);
  Future<void> updateRequestStatus(
    String id,
    String status, {
    String adminNotes,
    String approvedBy,
  });
  Future<void> deleteRequest(String id);
  Future<void> deleteRequestsForOffer(String offerId);
}
