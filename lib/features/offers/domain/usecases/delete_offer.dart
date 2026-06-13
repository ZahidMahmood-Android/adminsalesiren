import '../repositories/offers_repository.dart';

class DeleteOffer {
  const DeleteOffer(this._repository);

  final OffersRepository _repository;

  Future<void> call(String id) => _repository.deleteOffer(id);
}
