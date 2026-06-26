import '../entities/offer.dart';
import '../entities/offer_filters.dart';
import '../../../../core/services/offer_push_dispatch_service.dart';

abstract class OffersRepository {
  Stream<List<Offer>> watchOffers(OfferFilters filters);
  Future<Offer?> getOffer(String id);
  Future<String> createOffer(Offer offer, {bool sendNotification = true});
  Future<String> duplicateOffer(String id);
  Future<void> updateOffer(Offer offer, {bool sendNotification = false});
  Future<void> deleteOffer(String id);
  Future<void> publishOffer(
    String id,
    bool isPublished, {
    String? requestId,
    bool sendNotification = true,
  });
  Future<void> publishOfferLine(
    String offerId,
    String lineId, {
    required String requestId,
    bool sendNotification = true,
  });
  Future<void> expireOffer(String id);
  Future<void> verifyOffer(String id, bool isVerified);
  Future<void> featureOffer(String id, bool isFeatured);
  Future<void> approveOffer(String id, String approvedBy);
  Future<void> rejectOffer(String id, String notes, String approvedBy);
  Future<OfferPushDispatchResult> resendOfferNotification({
    required String offerId,
    String offerLineId = '',
    String requestId = '',
  });
}
