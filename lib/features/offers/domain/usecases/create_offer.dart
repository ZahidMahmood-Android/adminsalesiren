import '../entities/offer.dart';
import '../repositories/offers_repository.dart';

class CreateOffer {
  const CreateOffer(this._repository);

  final OffersRepository _repository;

  Future<String> call(Offer offer) => _repository.createOffer(offer);
}
