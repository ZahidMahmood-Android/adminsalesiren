import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/notification_request.dart';
import '../../domain/repositories/notifications_repository.dart';

class FirebaseNotificationsRepository implements NotificationsRepository {
  FirebaseNotificationsRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseNotificationsRepository');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('notification_requests');

  @override
  Future<String> createBroadcastRequest(NotificationRequest request) async {
    final doc = request.id.isEmpty ? _requests.doc() : _requests.doc(request.id);
    _log.info('Creating notification request id=${doc.id} type=${request.type}');
    await doc.set({
      'id': doc.id,
      'title': request.title,
      'body': request.body,
      'topic': request.topic,
      'type': request.type,
      'data': request.data,
      'status': request.status,
      'createdAt': Timestamp.fromDate(request.createdAt),
    });
    return doc.id;
  }
}
