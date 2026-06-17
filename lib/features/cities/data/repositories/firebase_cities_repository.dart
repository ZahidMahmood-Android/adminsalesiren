import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/cities_repository.dart';
import '../models/city_model.dart';

class FirebaseCitiesRepository implements CitiesRepository {
  FirebaseCitiesRepository(this._firestore, this._currentUserId);

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final _log = AppLogger.get('FirebaseCitiesRepository');

  CollectionReference<Map<String, dynamic>> get _cities =>
      _firestore.collection('cities');

  @override
  Stream<List<City>> watchCities() {
    return _cities.orderBy('sortOrder').snapshots().map((snapshot) {
      final cities = snapshot.docs.map(CityModel.fromSnapshot).toList();
      return cities;
    });
  }

  @override
  Future<List<City>> getCities() async {
    final snapshot = await _cities.orderBy('sortOrder').get();
    return snapshot.docs.map(CityModel.fromSnapshot).toList();
  }

  @override
  Future<City?> getCity(String id) async {
    if (_currentUserId.isEmpty) {
      return null;
    }
    final snapshot = await _cities.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    return CityModel.fromSnapshot(snapshot);
  }

  @override
  Future<String> createCity(City city) async {
    final safeId = _safeId(city.id.isEmpty ? city.name : city.id);
    final doc = _cities.doc(safeId);
    final now = DateTime.now();
    final model = CityModel.fromEntity(
      city.copyWith(
        id: safeId,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      ),
    );
    _log.info('Creating city id=$safeId name=${city.name}');
    final data = model.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    return safeId;
  }

  @override
  Future<void> updateCity(City city) {
    final model = CityModel.fromEntity(
      city.copyWith(updatedAt: DateTime.now(), userId: _currentUserId),
    );
    _log.info('Updating city id=${city.id} name=${city.name}');
    final data = model.toFirestore(includeCreatedAt: false)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    return _cities.doc(city.id).update(data);
  }

  @override
  Future<void> deleteCity(String id) {
    _log.warning('Deleting city id=$id');
    return _cities.doc(id).delete();
  }

  String _safeId(String value) {
    final id = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return id.replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
