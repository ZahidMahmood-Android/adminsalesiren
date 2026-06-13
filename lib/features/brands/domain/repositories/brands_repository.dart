import '../entities/brand.dart';

abstract class BrandsRepository {
  Stream<List<Brand>> watchBrands();
  Future<Brand?> getBrand(String id);
  Future<String> createBrand(Brand brand);
  Future<void> updateBrand(Brand brand);
  Future<void> deleteBrand(String id);
}
