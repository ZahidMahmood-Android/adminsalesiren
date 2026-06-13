import '../repositories/brands_repository.dart';

class DeleteBrand {
  const DeleteBrand(this._repository);

  final BrandsRepository _repository;

  Future<void> call(String id) => _repository.deleteBrand(id);
}
