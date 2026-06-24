abstract class MasterDataSeedRepository {
  Future<int> seedCities();
  Future<int> seedCategories();
  Future<int> seedBrands();
  Future<int> seedRoles();
  Future<int> seedAppFeatures();
}
