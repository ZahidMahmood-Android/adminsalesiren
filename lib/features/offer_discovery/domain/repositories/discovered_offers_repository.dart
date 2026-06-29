import '../entities/discovered_offer.dart';
import '../../../offers/domain/entities/offer.dart';

class OfferDiscoveryRunResult {
  const OfferDiscoveryRunResult({
    required this.checkedBrands,
    required this.discoveredCount,
    required this.duplicateCount,
    required this.errorCount,
  });

  final int checkedBrands;
  final int discoveredCount;
  final int duplicateCount;
  final int errorCount;

  factory OfferDiscoveryRunResult.fromMap(Map<String, dynamic> data) {
    int readInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return OfferDiscoveryRunResult(
      checkedBrands: readInt(data['checkedBrands']),
      discoveredCount: readInt(data['discoveredCount']),
      duplicateCount: readInt(data['duplicateCount']),
      errorCount: readInt(data['errorCount']),
    );
  }
}

abstract class DiscoveredOffersRepository {
  Stream<List<DiscoveredOffer>> watchByStatus(String status);

  Future<DiscoveredOffer?> getById(String id);

  Future<String> convertToOfficialOffer({
    required DiscoveredOffer discovered,
    required Offer draftOffer,
  });

  Future<void> reject({
    required String id,
    String rejectionReason,
  });

  Future<void> markDuplicate({
    required String id,
    String duplicateOfOfferId,
  });

  Future<void> reactivateForPendingReview(String id);

  Future<void> reactivateByConvertedOfferId(String offerId);

  /// Deletes all discovery suggestions. Does not delete official offers.
  Future<int> clearAll();
}
