import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/brand.dart';
import '../../domain/repositories/brands_repository.dart';
import '../models/brand_model.dart';

class FirebaseBrandsRepository implements BrandsRepository {
  FirebaseBrandsRepository(this._firestore, this._currentUserId);

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final _log = AppLogger.get('FirebaseBrandsRepository');

  CollectionReference<Map<String, dynamic>> get _brands =>
      _firestore.collection('brands');

  @override
  Stream<List<Brand>> watchBrands() {
    if (_currentUserId.isEmpty) {
      return Stream.value(const <Brand>[]);
    }
    return _brands.where('userId', isEqualTo: _currentUserId).snapshots().map((
      snapshot,
    ) {
      final brands = snapshot.docs.map(BrandModel.fromSnapshot).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return brands;
    });
  }

  @override
  Future<Brand?> getBrand(String id) async {
    if (_currentUserId.isEmpty) {
      return null;
    }
    final snapshot = await _brands.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    final brand = BrandModel.fromSnapshot(snapshot);
    return brand.userId == _currentUserId ? brand : null;
  }

  @override
  Future<String> createBrand(Brand brand) async {
    final doc = brand.id.isEmpty ? _brands.doc() : _brands.doc(brand.id);
    final now = DateTime.now();
    final model = BrandModel.fromEntity(
      brand.copyWith(
        id: doc.id,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      ),
    );
    _log.info('Creating brand id=${doc.id} name=${brand.name}');
    await doc.set(model.toFirestore());
    _log.info('Created brand id=${doc.id}');
    return doc.id;
  }

  @override
  Future<void> updateBrand(Brand brand) {
    final model = BrandModel.fromEntity(
      brand.copyWith(updatedAt: DateTime.now(), userId: _currentUserId),
    );
    _log.info('Updating brand id=${brand.id} name=${brand.name}');
    return _brands
        .doc(brand.id)
        .update(model.toFirestore(includeCreatedAt: false));
  }

  @override
  Future<void> deleteBrand(String id) {
    _log.warning('Deleting brand id=$id');
    return _brands.doc(id).delete();
  }
}
