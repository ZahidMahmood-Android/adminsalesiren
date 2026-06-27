import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/notification_request.dart';
import '../../domain/repositories/notifications_repository.dart';

class FirebaseNotificationsRepository implements NotificationsRepository {
  FirebaseNotificationsRepository(
    this._firestore,
    this._currentUserId, {
    required this.canSeeAllRequests,
  });

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final bool canSeeAllRequests;
  final _log = AppLogger.get('FirebaseNotificationsRepository');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('notification_requests');

  @override
  Stream<List<NotificationRequest>> watchRequests() {
    if (_currentUserId.isEmpty) {
      return Stream.value(const <NotificationRequest>[]);
    }
    final query = canSeeAllRequests
        ? _requests
        : _requests.where('requestedByUserId', isEqualTo: _currentUserId);
    return query.snapshots().map((snapshot) {
      final requests =
          snapshot.docs
              .map(_fromSnapshot)
              .where((request) => request.offerId.isNotEmpty)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  @override
  Future<String> createBroadcastRequest(NotificationRequest request) async {
    final doc = request.id.isEmpty
        ? _requests.doc()
        : _requests.doc(request.id);
    _log.info(
      'Creating notification request id=${doc.id} type=${request.type}',
    );
    await doc.set({
      'id': doc.id,
      'title': request.title,
      'body': request.body,
      'brandId': request.brandId,
      'brandName': request.brandName,
      'offerId': request.offerId,
      'requestedByUserId': request.requestedByUserId,
      'targetCityIds': request.targetCityIds,
      'targetCategoryIds': request.targetCategoryIds,
      'targetTopics': request.targetTopics,
      'topic': request.topic,
      'type': request.type,
      'data': request.data,
      'status': request.status,
      'adminNotes': request.adminNotes,
      'approvedBy': request.approvedBy,
      'approvedAt': request.approvedAt == null
          ? null
          : Timestamp.fromDate(request.approvedAt!),
      'sentAt': request.sentAt == null
          ? null
          : Timestamp.fromDate(request.sentAt!),
      'sentCount': request.sentCount,
      'openCount': request.openCount,
      'offerLineId': request.offerLineId,
      'groupTitle': request.groupTitle,
      'includeImage': request.includeImage,
      'createdAt': Timestamp.fromDate(request.createdAt),
      'updatedAt': Timestamp.now(),
    });
    return doc.id;
  }

  @override
  Future<void> updateRequest(NotificationRequest request) {
    return _requests.doc(request.id).update({
      'title': request.title,
      'body': request.body,
      'type': request.type,
      'data': request.data,
      'targetCityIds': request.targetCityIds,
      'targetCategoryIds': request.targetCategoryIds,
      'targetTopics': request.targetTopics,
      'includeImage': request.includeImage,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> updateRequestStatus(
    String id,
    String status, {
    String adminNotes = '',
    String approvedBy = '',
  }) {
    return _requests.doc(id).update({
      'status': status,
      'adminNotes': adminNotes,
      'approvedBy': approvedBy,
      'approvedAt': status == 'approved' ? Timestamp.now() : null,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> deleteRequest(String id) {
    return _requests.doc(id).delete();
  }

  @override
  Future<void> deleteRequestsForOffer(String offerId) async {
    if (offerId.isEmpty) {
      return;
    }
    _log.warning('Deleting notification requests for offerId=$offerId');
    final snapshot = await _requests.where('offerId', isEqualTo: offerId).get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _log.info(
      'Deleted ${snapshot.docs.length} notification requests for offerId=$offerId',
    );
  }

  NotificationRequest _fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return NotificationRequest(
      id: data['id'] as String? ?? doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      topic: data['topic'] as String? ?? '',
      type: data['type'] as String? ?? 'new_offer',
      data:
          (data['data'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
      status: data['status'] as String? ?? 'pending',
      createdAt: _readDate(data['createdAt']),
      brandId: data['brandId'] as String? ?? '',
      brandName:
          data['brandName'] as String? ??
          (data['data'] as Map?)?['brandName']?.toString() ??
          '',
      offerId: data['offerId'] as String? ?? '',
      requestedByUserId: data['requestedByUserId'] as String? ?? '',
      targetCityIds: _readStringList(data['targetCityIds']),
      targetCategoryIds: _readStringList(data['targetCategoryIds']),
      targetTopics: _readStringList(data['targetTopics']),
      adminNotes: data['adminNotes'] as String? ?? '',
      approvedBy: data['approvedBy'] as String? ?? '',
      approvedAt: _readOptionalDate(data['approvedAt']),
      sentAt: _readOptionalDate(data['sentAt']),
      sentCount: data['sentCount'] as int? ?? 0,
      openCount: data['openCount'] as int? ?? 0,
      offerLineId: data['offerLineId'] as String? ?? '',
      groupTitle: data['groupTitle'] as String? ?? '',
      includeImage: data['includeImage'] as bool? ?? true,
    );
  }

  DateTime _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _readOptionalDate(Object? value) {
    if (value == null) {
      return null;
    }
    return _readDate(value);
  }

  List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}
