import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/offer_push_dispatch_service.dart';
import '../../../../core/services/push_dispatch_debug_logger.dart';
import '../../../../core/services/push_dispatch_user_messages.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_filters.dart';
import '../../domain/repositories/offer_image_repository.dart';
import '../../domain/repositories/offers_repository.dart';
import '../models/offer_model.dart';
import '../utils/offer_storage_utils.dart';

class FirebaseOffersRepository implements OffersRepository {
  FirebaseOffersRepository(
    this._firestore,
    this._currentUserId,
    this._currentUserRole,
    this._offerImageRepository,
  );

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final String _currentUserRole;
  final OfferImageRepository _offerImageRepository;
  final _log = AppLogger.get('FirebaseOffersRepository');

  CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('offers');

  bool get _isBrandScopedUser => _currentUserRole == UserRoles.brandAdmin;
  bool get _isManager => _currentUserRole == UserRoles.manager;
  bool get _isOwner => _currentUserRole == UserRoles.owner;
  bool get _hasFullAccess => _isOwner || _isManager;

  Offer _enforcePendingForManager(Offer offer) {
    if (!_isManager) {
      return offer;
    }
    return offer.copyWith(
      isPublished: false,
      status: 'pending_review',
      approvalStatus: 'pending',
      approvedBy: '',
      approvedAt: null,
    );
  }

  Offer _normalizeOfferForWrite(Offer offer) {
    final createdByUserId = offer.createdByUserId.isNotEmpty
        ? offer.createdByUserId
        : (offer.createdBy.isNotEmpty ? offer.createdBy : _currentUserId);
    final status = offer.isPublished
        ? 'published'
        : (offer.status == 'pending' ? 'pending_review' : offer.status);
    return offer.copyWith(
      createdByUserId: createdByUserId,
      createdBy: offer.createdBy.isNotEmpty ? offer.createdBy : createdByUserId,
      status: status,
      approvalStatus: offer.isPublished ? 'approved' : offer.approvalStatus,
      isVerified: offer.isPublished ? true : offer.isVerified,
    );
  }

  @override
  Stream<List<Offer>> watchOffers(OfferFilters filters) {
    if (_currentUserId.isEmpty) {
      return Stream.value(const <Offer>[]);
    }

    var query = _offers.orderBy('createdAt', descending: true);
    if (!_hasFullAccess) {
      query = query.where('createdByUserId', isEqualTo: _currentUserId);
    }

    return query.snapshots().map((snapshot) {
      final offers = snapshot.docs
          .map(OfferModel.fromSnapshot)
          .where(_canReadOffer)
          .where((offer) => filters.matchesOffer(offer))
          .toList();
      return offers;
    });
  }

  @override
  Future<Offer?> getOffer(String id) async {
    if (_currentUserId.isEmpty) {
      return null;
    }
    final snapshot = await _offers.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    final offer = OfferModel.fromSnapshot(snapshot);
    return _canReadOffer(offer) ? offer : null;
  }

  @override
  Future<String> createOffer(
    Offer offer, {
    bool sendNotification = true,
  }) async {
    final pendingOffer = _enforcePendingForManager(offer);
    final doc = pendingOffer.id.isEmpty
        ? _offers.doc()
        : _offers.doc(pendingOffer.id);
    final now = DateTime.now();
    final brandStatus = pendingOffer.isPublished
        ? 'published'
        : pendingOffer.status;
    final model = OfferModel.fromEntity(
      pendingOffer.copyWith(
        id: doc.id,
        createdAt: now,
        updatedAt: now,
        createdBy: _currentUserId,
        createdByUserId: _currentUserId,
        createdByRole: _currentUserRole,
        status: _isBrandScopedUser || _isManager
            ? brandStatus
            : pendingOffer.status,
        approvalStatus: _isBrandScopedUser || _isManager
            ? pendingOffer.isPublished
                  ? 'approved'
                  : 'pending'
            : pendingOffer.approvalStatus,
        isPublished: pendingOffer.isPublished,
        isVerified: pendingOffer.isVerified,
        approvedBy: _isBrandScopedUser || _isManager
            ? pendingOffer.isPublished
                  ? _currentUserId
                  : ''
            : pendingOffer.approvedBy,
        approvedAt: _isBrandScopedUser || _isManager
            ? pendingOffer.isPublished
                  ? now
                  : null
            : pendingOffer.approvedAt,
      ),
    );
    _log.info('Creating offer id=${doc.id} title=${pendingOffer.title}');
    final data = model.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    if (sendNotification && pendingOffer.isPublished) {
      await _scheduleOfferPush(doc.id);
    }
    _log.info('Created offer id=${doc.id}');
    return doc.id;
  }

  @override
  Future<String> duplicateOffer(String id) async {
    final snapshot = await _offers.doc(id).get();
    if (!snapshot.exists) {
      throw StateError('Offer not found.');
    }
    final source = OfferModel.fromSnapshot(snapshot);
    if (!_canReadOffer(source)) {
      throw StateError('Offer not found.');
    }
    final now = DateTime.now();
    final duplicate = source.copyWith(
      id: '',
      title: '${source.title} Copy',
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      imageUrl: '',
      imageUrls: const [],
      isPublished: false,
      isVerified: false,
      isFeatured: false,
      status: _isBrandScopedUser || _isManager ? 'pending_review' : 'draft',
      approvalStatus: _isBrandScopedUser || _isManager ? 'pending' : 'draft',
      approvalNotes: '',
      approvedBy: '',
      approvedAt: null,
      viewCount: 0,
      saveCount: 0,
      shareCount: 0,
      clickCount: 0,
      reportCount: 0,
      createdBy: _currentUserId,
      createdByUserId: _currentUserId,
      createdByRole: _currentUserRole,
      createdAt: now,
      updatedAt: now,
      offerLines: source.offerLines
          .map(
            (line) => line.copyWith(
              imageUrl: '',
              imageUrls: const [],
              notificationRequestId: '',
              published: false,
            ),
          )
          .toList(),
    );
    final duplicateId = await createOffer(duplicate);
    await _offers.doc(duplicateId).update({
      'approvedAt': null,
      'approvedBy': '',
      'approvalNotes': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return duplicateId;
  }

  @override
  Future<void> updateOffer(Offer offer, {bool sendNotification = false}) async {
    final pendingOffer = _enforcePendingForManager(offer);
    final existingSnapshot = await _offers.doc(pendingOffer.id).get();
    if (!existingSnapshot.exists) {
      throw StateError('Offer not found.');
    }
    final existing = OfferModel.fromSnapshot(existingSnapshot);
    final createdByUserId = existing.createdByUserId.isNotEmpty
        ? existing.createdByUserId
        : existing.createdBy;
    final identityLocked = pendingOffer.copyWith(
      brandId: existing.brandId,
      createdBy: existing.createdBy.isNotEmpty
          ? existing.createdBy
          : createdByUserId,
      createdByUserId: createdByUserId,
      createdByRole: existing.createdByRole,
      createdAt: existing.createdAt,
    );
    final normalizedOffer = _normalizeOfferForWrite(identityLocked);
    final model = OfferModel.fromEntity(
      normalizedOffer.copyWith(updatedAt: DateTime.now()),
    );
    _log.info(
      'Updating offer id=${pendingOffer.id} title=${pendingOffer.title}',
    );
    final data = model.toFirestore(includeCreatedAt: false)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _offers.doc(pendingOffer.id).update(data);
    if (normalizedOffer.isExpired) {
      await _cleanupOfferNotificationArtifacts(pendingOffer.id);
    }
    if (sendNotification && pendingOffer.isPublished) {
      await _scheduleOfferPush(pendingOffer.id);
    }
  }

  Future<OfferPushDispatchResult> _scheduleOfferPush(
    String offerId, {
    String? lineId,
    String? requestId,
  }) async {
    final jobId = lineId != null && lineId.isNotEmpty
        ? '$offerId-$lineId'
        : offerId;
    try {
      await _firestore.collection('offer_push_jobs').doc(jobId).set({
        'offerId': offerId,
        if (lineId != null && lineId.isNotEmpty) 'offerLineId': lineId,
        if (requestId != null && requestId.isNotEmpty) 'requestId': requestId,
        'requestedByUserId': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'pushNonce': FieldValue.serverTimestamp(),
        'dispatchInProgress': FieldValue.delete(),
        'dispatchCompletedAt': FieldValue.delete(),
        'lastError': FieldValue.delete(),
      }, SetOptions(merge: true));
      PushDispatchDebugLogger.logScheduledJob(
        jobId: jobId,
        offerId: offerId,
        offerLineId: lineId,
        requestId: requestId,
        requestedByUserId: _currentUserId,
      );
      await PushDispatchDebugLogger.logMobileRecipients(_firestore);
      final result = await OfferPushDispatchService.create().dispatchNow(
        firestore: _firestore,
        offerId: offerId,
        jobId: jobId,
        offerLineId: lineId,
        requestId: requestId,
      );
      PushDispatchUserMessages.ensureDelivered(result);
      return result!;
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to schedule offer_push_jobs/$jobId for offerId=$offerId',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteOffer(String id) async {
    _log.warning('Deleting offer id=$id');
    Offer? offer;
    try {
      final snapshot = await _offers.doc(id).get();
      if (snapshot.exists) {
        offer = OfferModel.fromSnapshot(snapshot);
        await _offerImageRepository.deleteImagesForOffer(
          offerId: id,
          imageUrls: OfferStorageUtils.collectImageUrls(offer),
          additionalFolderIds: OfferStorageUtils.storageFolderIds(offer),
        );
      }
    } catch (error, stackTrace) {
      _log.warning(
        'Offer image cleanup failed for id=$id; continuing delete',
        error,
        stackTrace,
      );
    }

    try {
      await _cleanupOfferNotificationArtifacts(id);
    } catch (error, stackTrace) {
      _log.warning(
        'Offer notification cleanup failed for id=$id; continuing delete',
        error,
        stackTrace,
      );
    }

    await _offers.doc(id).delete();
    _log.info('Deleted offer id=$id');
  }

  Future<void> _cleanupOfferNotificationArtifacts(String offerId) async {
    if (offerId.isEmpty) {
      return;
    }
    await _deletePushJobsForOffer(offerId);
    await _deleteNotificationRequestsForOffer(offerId);
  }

  Future<void> _deleteNotificationRequestsForOffer(String offerId) async {
    final snapshot = await _firestore
        .collection('notification_requests')
        .where('offerId', isEqualTo: offerId)
        .get();
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

  Future<void> _deletePushJobsForOffer(String offerId) async {
    final snapshot = await _firestore
        .collection('offer_push_jobs')
        .where('offerId', isEqualTo: offerId)
        .get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> publishOfferLine(
    String offerId,
    String lineId, {
    required String requestId,
    bool sendNotification = true,
  }) async {
    _log.info(
      'Publishing offer line offerId=$offerId lineId=$lineId requestId=$requestId',
    );
    final snapshot = await _offers.doc(offerId).get();
    if (!snapshot.exists) {
      _log.warning(
        'Publish offer line aborted: offer not found offerId=$offerId',
      );
      return;
    }
    final offer = OfferModel.fromSnapshot(snapshot);
    final lines = offer.offerLines.isEmpty
        ? offer.resolvedLines
        : offer.offerLines;
    final updatedLines = lines
        .map(
          (line) => line.id == lineId ? line.copyWith(published: true) : line,
        )
        .map((line) => line.toMap())
        .toList();
    await _offers.doc(offerId).update({
      'offerLines': updatedLines,
      'isPublished': true,
      'isVerified': true,
      'status': 'published',
      'approvalStatus': 'approved',
      'approvedBy': _currentUserId,
      'approvedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    if (sendNotification) {
      await _scheduleOfferPush(offerId, lineId: lineId, requestId: requestId);
    }
    _log.info(
      'Published offer line offerId=$offerId lineId=$lineId requestId=$requestId '
      'sendNotification=$sendNotification',
    );
  }

  @override
  Future<void> publishOffer(
    String id,
    bool isPublished, {
    String? requestId,
    bool sendNotification = true,
  }) async {
    _log.info(
      'Setting offer published id=$id value=$isPublished requestId=${requestId ?? ''} '
      'sendNotification=$sendNotification',
    );
    await _offers.doc(id).update({
      'isPublished': isPublished,
      'status': isPublished ? 'published' : 'approved',
      'approvalStatus': 'approved',
      if (isPublished) 'isVerified': true,
      'approvedBy': isPublished ? _currentUserId : '',
      'approvedAt': isPublished ? Timestamp.now() : null,
      'updatedAt': Timestamp.now(),
    });
    if (isPublished && sendNotification) {
      await _scheduleOfferPush(id, requestId: requestId);
    }
  }

  @override
  Future<void> expireOffer(String id) async {
    _log.info('Expiring offer id=$id');
    await _offers.doc(id).update({
      'isPublished': false,
      'isVerified': false,
      'isFeatured': false,
      'status': 'expired',
      'approvalStatus': 'expired',
      'updatedAt': Timestamp.now(),
    });
    await _cleanupOfferNotificationArtifacts(id);
  }

  @override
  Future<void> verifyOffer(String id, bool isVerified) {
    _log.info('Setting offer verified id=$id value=$isVerified');
    return _offers.doc(id).update({
      'isVerified': isVerified,
      if (!isVerified) 'isFeatured': false,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> featureOffer(String id, bool isFeatured) async {
    _log.info('Setting offer featured id=$id value=$isFeatured');
    if (isFeatured) {
      final snapshot = await _offers.doc(id).get();
      final verified = snapshot.data()?['isVerified'] as bool? ?? false;
      if (!verified) {
        throw StateError('Only verified offers can be featured.');
      }
    }
    await _offers.doc(id).update({
      'isFeatured': isFeatured,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> approveOffer(String id, String approvedBy) {
    return _offers.doc(id).update({
      'status': 'approved',
      'approvalStatus': 'approved',
      'approvalNotes': '',
      'approvedBy': approvedBy,
      'approvedAt': Timestamp.now(),
      'isVerified': true,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> rejectOffer(String id, String notes, String approvedBy) {
    return _offers.doc(id).update({
      'status': 'rejected',
      'approvalStatus': 'rejected',
      'approvalNotes': notes,
      'approvedBy': approvedBy,
      'approvedAt': Timestamp.now(),
      'isPublished': false,
      'isVerified': false,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<OfferPushDispatchResult> resendOfferNotification({
    required String offerId,
    String offerLineId = '',
    String requestId = '',
  }) async {
    final snapshot = await _offers.doc(offerId).get();
    if (!snapshot.exists) {
      throw StateError('Offer not found.');
    }
    final offer = OfferModel.fromSnapshot(snapshot);
    if (!offer.isPublished) {
      throw StateError('Only published offers can resend notifications.');
    }
    if (offer.isExpired) {
      throw StateError('Expired offers cannot resend notifications.');
    }

    _log.info(
      'Resending notification offerId=$offerId '
      'offerLineId=$offerLineId requestId=$requestId',
    );
    return _scheduleOfferPush(
      offerId,
      lineId: offerLineId.isEmpty ? null : offerLineId,
      requestId: requestId.isEmpty ? null : requestId,
    );
  }

  @override
  Future<void> updateOfferNotificationState({
    required String offerId,
    required String alertType,
    required Map<String, dynamic> notificationSnapshot,
  }) {
    if (offerId.isEmpty) {
      return Future<void>.value();
    }
    return _offers.doc(offerId).update({
      'alertType': alertType,
      'notificationSnapshot': notificationSnapshot,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _canReadOffer(Offer offer) {
    if (!_hasFullAccess) {
      return offer.createdByUserId == _currentUserId ||
          offer.createdBy == _currentUserId;
    }
    return true;
  }
}
