import '../entities/city.dart';

abstract class CitiesRepository {
  Stream<List<City>> watchCities();
  Future<List<City>> getCities();
  Future<City?> getCity(String id);
  Future<String> createCity(City city);
  Future<void> updateCity(City city);
  Future<void> deleteCity(String id);
}
