import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../domain/entities/brand.dart';
import '../../domain/repositories/brands_repository.dart';
import '../models/brand_model.dart';

class FirebaseBrandsRepository implements BrandsRepository {
  FirebaseBrandsRepository(
    this._firestore,
    this._currentUserId,
    this._currentUserRole,
    this._currentBrandId,
  );

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final String _currentUserRole;
  final String _currentBrandId;
  final _log = AppLogger.get('FirebaseBrandsRepository');

  CollectionReference<Map<String, dynamic>> get _brands =>
      _firestore.collection('brands');

  @override
  Stream<List<Brand>> watchBrands() {
    return _brands.snapshots().map((snapshot) {
      final brands =
          snapshot.docs
              .map(BrandModel.fromSnapshot)
              .where(_canReadBrand)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
    return _canReadBrand(brand) ? brand : null;
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
        topic: brand.topic.isEmpty
            ? _topicFor(brand.name, doc.id)
            : brand.topic,
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
      brand.copyWith(
        updatedAt: DateTime.now(),
        userId: _currentUserId,
        topic: brand.topic.isEmpty
            ? _topicFor(brand.name, brand.id)
            : brand.topic,
      ),
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

  bool _canReadBrand(Brand brand) {
    if (_currentUserRole == UserRoles.brandAdmin) {
      return brand.id == _currentBrandId ||
          brand.ownerUserIds.contains(_currentUserId);
    }
    return true;
  }

  String _topicFor(String name, String id) {
    final compactName = name.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    final prefix = compactName.length <= 8
        ? compactName
        : compactName.substring(0, 8);
    return '${prefix}_${_shortCode('$id-$name')}';
  }

  String _shortCode(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final code = hash.toRadixString(36).padLeft(4, '0');
    return code.substring(code.length - 4);
  }
}
