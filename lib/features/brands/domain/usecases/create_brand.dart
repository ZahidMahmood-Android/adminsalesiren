import '../entities/brand.dart';
import '../repositories/brands_repository.dart';

class CreateBrand {
  const CreateBrand(this._repository);

  final BrandsRepository _repository;

  Future<String> call(Brand brand) => _repository.createBrand(brand);
}
