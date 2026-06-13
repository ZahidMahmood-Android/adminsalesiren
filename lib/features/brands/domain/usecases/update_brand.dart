import '../entities/brand.dart';
import '../repositories/brands_repository.dart';

class UpdateBrand {
  const UpdateBrand(this._repository);

  final BrandsRepository _repository;

  Future<void> call(Brand brand) => _repository.updateBrand(brand);
}
