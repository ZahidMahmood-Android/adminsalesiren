abstract class OfferImageRepository {
  Future<String> uploadOfferImage({
    required String offerId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  });

  Future<void> deleteImagesForOffer({
    required String offerId,
    Iterable<String> imageUrls = const [],
  });
}
