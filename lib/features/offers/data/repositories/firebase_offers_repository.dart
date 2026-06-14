import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_filters.dart';
import '../../domain/repositories/offers_repository.dart';
import '../models/offer_model.dart';

class FirebaseOffersRepository implements OffersRepository {
  FirebaseOffersRepository(this._firestore, this._currentUserId);

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final _log = AppLogger.get('FirebaseOffersRepository');

  CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('offers');

  @override
  Stream<List<Offer>> watchOffers(OfferFilters filters) {
    if (_currentUserId.isEmpty) {
      return Stream.value(const <Offer>[]);
    }

    return _offers
        .where('createdBy', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .map(OfferModel.fromSnapshot)
          .where((offer) => _matchesFilters(offer, filters))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    return offer.createdBy == _currentUserId ? offer : null;
  }

  @override
  Future<String> createOffer(Offer offer) async {
    final doc = offer.id.isEmpty ? _offers.doc() : _offers.doc(offer.id);
    final now = DateTime.now();
    final model = OfferModel.fromEntity(
      offer.copyWith(
        id: doc.id,
        createdAt: now,
        updatedAt: now,
        createdBy: _currentUserId,
      ),
    );
    _log.info('Creating offer id=${doc.id} title=${offer.title}');
    await doc.set(model.toFirestore());
    _log.info('Created offer id=${doc.id}');
    return doc.id;
  }

  @override
  Future<void> updateOffer(Offer offer) {
    final model = OfferModel.fromEntity(
      offer.copyWith(updatedAt: DateTime.now(), createdBy: _currentUserId),
    );
    _log.info('Updating offer id=${offer.id} title=${offer.title}');
    return _offers
        .doc(offer.id)
        .update(model.toFirestore(includeCreatedAt: false));
  }

  @override
  Future<void> deleteOffer(String id) {
    _log.warning('Deleting offer id=$id');
    return _offers.doc(id).delete();
  }

  @override
  Future<void> publishOffer(String id, bool isPublished) {
    _log.info('Setting offer published id=$id value=$isPublished');
    return _offers.doc(id).update({
      'isPublished': isPublished,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> verifyOffer(String id, bool isVerified) {
    _log.info('Setting offer verified id=$id value=$isVerified');
    return _offers.doc(id).update({
      'isVerified': isVerified,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> featureOffer(String id, bool isFeatured) {
    _log.info('Setting offer featured id=$id value=$isFeatured');
    return _offers.doc(id).update({
      'isFeatured': isFeatured,
      'updatedAt': Timestamp.now(),
    });
  }

  bool _matchesFilters(Offer offer, OfferFilters filters) {
    if (filters.cityId != null && offer.cityId != filters.cityId) {
      return false;
    }
    if (filters.categoryId != null && offer.categoryId != filters.categoryId) {
      return false;
    }
    if (filters.brandId != null && offer.brandId != filters.brandId) {
      return false;
    }
    if (filters.isPublished != null &&
        offer.isPublished != filters.isPublished) {
      return false;
    }
    if (filters.isVerified != null && offer.isVerified != filters.isVerified) {
      return false;
    }
    return true;
  }
}
