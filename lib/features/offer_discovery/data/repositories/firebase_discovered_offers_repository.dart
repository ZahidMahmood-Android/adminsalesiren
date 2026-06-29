import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../offers/data/models/offer_model.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../domain/entities/discovered_offer.dart';
import '../../domain/entities/discovered_offer_status.dart';
import '../../domain/repositories/discovered_offers_repository.dart';
import '../models/discovered_offer_model.dart';

class FirebaseDiscoveredOffersRepository implements DiscoveredOffersRepository {
  FirebaseDiscoveredOffersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('discovered_offers');

  @override
  Stream<List<DiscoveredOffer>> watchByStatus(String status) {
    return _collection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(DiscoveredOfferModel.fromSnapshot).toList(),
        );
  }

  @override
  Future<DiscoveredOffer?> getById(String id) async {
    final snapshot = await _collection.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    return DiscoveredOfferModel.fromSnapshot(snapshot);
  }

  @override
  Future<String> convertToOfficialOffer({
    required DiscoveredOffer discovered,
    required Offer draftOffer,
  }) async {
    final offerRef = draftOffer.id.isEmpty
        ? _firestore.collection('offers').doc()
        : _firestore.collection('offers').doc(draftOffer.id);
    final now = DateTime.now();
    final offer = draftOffer.copyWith(
      id: offerRef.id,
      createdAt: now,
      updatedAt: now,
      status: 'draft',
      isPublished: false,
      isVerified: false,
      approvalStatus: 'pending',
    );
    final offerModel = OfferModel.fromEntity(offer);

    await _firestore.runTransaction((transaction) async {
      transaction.set(offerRef, offerModel.toFirestore());
      transaction.update(_collection.doc(discovered.id), {
        'status': DiscoveredOfferStatuses.converted,
        'convertedOfferId': offerRef.id,
        'updatedAt': Timestamp.fromDate(now),
      });
    });

    return offerRef.id;
  }

  @override
  Future<void> reject({
    required String id,
    String rejectionReason = '',
  }) async {
    await _collection.doc(id).update({
      'status': DiscoveredOfferStatuses.rejected,
      'rejectionReason': rejectionReason.trim(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> markDuplicate({
    required String id,
    String duplicateOfOfferId = '',
  }) async {
    await _collection.doc(id).update({
      'status': DiscoveredOfferStatuses.duplicate,
      'duplicateOfOfferId': duplicateOfOfferId.trim(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> reactivateForPendingReview(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await _collection.doc(trimmed).update({
      'status': DiscoveredOfferStatuses.pendingReview,
      'convertedOfferId': '',
      'rejectionReason': '',
      'duplicateOfOfferId': '',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> reactivateByConvertedOfferId(String offerId) async {
    final trimmed = offerId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final snapshot = await _collection
        .where('convertedOfferId', isEqualTo: trimmed)
        .where('status', isEqualTo: DiscoveredOfferStatuses.converted)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    await reactivateForPendingReview(snapshot.docs.first.id);
  }

  @override
  Future<int> clearAll() async {
    const pageSize = 500;
    var totalDeleted = 0;
    while (true) {
      final snapshot = await _collection.limit(pageSize).get();
      if (snapshot.docs.isEmpty) {
        break;
      }
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      totalDeleted += snapshot.docs.length;
      if (snapshot.docs.length < pageSize) {
        break;
      }
    }
    return totalDeleted;
  }
}
