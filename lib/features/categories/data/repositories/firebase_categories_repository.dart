import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../models/category_model.dart';

class FirebaseCategoriesRepository implements CategoriesRepository {
  FirebaseCategoriesRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseCategoriesRepository');

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  @override
  Stream<List<Category>> watchCategories() {
    return _categories.snapshots().map((snapshot) {
      final categories = snapshot.docs.map(CategoryModel.fromSnapshot).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    });
  }

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _categories.get();
    return snapshot.docs.map(CategoryModel.fromSnapshot).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<Category?> getCategory(String id) async {
    final snapshot = await _categories.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    return CategoryModel.fromSnapshot(snapshot);
  }

  @override
  Future<String> createCategory(Category category) async {
    final safeId = _safeId(category.id.isEmpty ? category.name : category.id);
    final doc = _categories.doc(safeId);
    final now = DateTime.now();
    final model = CategoryModel.fromEntity(
      category.copyWith(id: safeId, createdAt: now, updatedAt: now),
    );
    _log.info('Creating category id=$safeId name=${category.name}');
    await doc.set(model.toFirestore());
    return safeId;
  }

  @override
  Future<void> updateCategory(Category category) {
    final model = CategoryModel.fromEntity(
      category.copyWith(updatedAt: DateTime.now()),
    );
    _log.info('Updating category id=${category.id} name=${category.name}');
    return _categories
        .doc(category.id)
        .update(model.toFirestore(includeCreatedAt: false));
  }

  @override
  Future<void> deleteCategory(String id) {
    _log.warning('Deleting category id=$id');
    return _categories.doc(id).delete();
  }

  String _safeId(String value) {
    final id = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return id.replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
