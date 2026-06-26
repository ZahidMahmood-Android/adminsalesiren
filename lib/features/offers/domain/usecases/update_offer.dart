import '../entities/offer.dart';
import '../repositories/offers_repository.dart';

class UpdateOffer {
  const UpdateOffer(this._repository);

  final OffersRepository _repository;

  Future<void> call(Offer offer, {bool sendNotification = false}) =>
      _repository.updateOffer(offer, sendNotification: sendNotification);
}
