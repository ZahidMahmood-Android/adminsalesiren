import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/brand.dart';
import '../../domain/repositories/brands_repository.dart';
import '../models/brand_model.dart';

class FirebaseBrandsRepository implements BrandsRepository {
  FirebaseBrandsRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseBrandsRepository');

  CollectionReference<Map<String, dynamic>> get _brands =>
      _firestore.collection('brands');

  @override
  Stream<List<Brand>> watchBrands() {
    return _brands
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BrandModel.fromSnapshot).toList());
  }

  @override
  Future<Brand?> getBrand(String id) async {
    final snapshot = await _brands.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    return BrandModel.fromSnapshot(snapshot);
  }

  @override
  Future<String> createBrand(Brand brand) async {
    final doc = brand.id.isEmpty ? _brands.doc() : _brands.doc(brand.id);
    final now = DateTime.now();
    final model = BrandModel.fromEntity(
      brand.copyWith(id: doc.id, createdAt: now, updatedAt: now),
    );
    _log.info('Creating brand id=${doc.id} name=${brand.name}');
    await doc.set(model.toFirestore());
    _log.info('Created brand id=${doc.id}');
    return doc.id;
  }

  @override
  Future<void> updateBrand(Brand brand) {
    final model = BrandModel.fromEntity(
      brand.copyWith(updatedAt: DateTime.now()),
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
