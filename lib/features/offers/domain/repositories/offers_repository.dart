import '../entities/offer.dart';
import '../entities/offer_filters.dart';

abstract class OffersRepository {
  Stream<List<Offer>> watchOffers(OfferFilters filters);
  Future<Offer?> getOffer(String id);
  Future<String> createOffer(Offer offer);
  Future<void> updateOffer(Offer offer);
  Future<void> deleteOffer(String id);
  Future<void> publishOffer(String id, bool isPublished);
  Future<void> expireOffer(String id);
  Future<void> verifyOffer(String id, bool isVerified);
  Future<void> featureOffer(String id, bool isFeatured);
  Future<void> approveOffer(String id, String approvedBy);
  Future<void> rejectOffer(String id, String notes, String approvedBy);
}
