import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../models/category_model.dart';

class FirebaseCategoriesRepository implements CategoriesRepository {
  FirebaseCategoriesRepository(this._firestore, this._currentUserId);

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final _log = AppLogger.get('FirebaseCategoriesRepository');

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  @override
  Stream<List<Category>> watchCategories() {
    if (_currentUserId.isEmpty) {
      return Stream.value(const <Category>[]);
    }
    return _categories.where('userId', isEqualTo: _currentUserId).snapshots().map((snapshot) {
      final categories = snapshot.docs.map(CategoryModel.fromSnapshot).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    });
  }

  @override
  Future<List<Category>> getCategories() async {
    if (_currentUserId.isEmpty) {
      return const <Category>[];
    }
    final snapshot = await _categories.where('userId', isEqualTo: _currentUserId).get();
    return snapshot.docs.map(CategoryModel.fromSnapshot).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<Category?> getCategory(String id) async {
    if (_currentUserId.isEmpty) {
      return null;
    }
    final snapshot = await _categories.doc(id).get();
    if (!snapshot.exists) {
      return null;
    }
    final category = CategoryModel.fromSnapshot(snapshot);
    return category.userId == _currentUserId ? category : null;
  }

  @override
  Future<String> createCategory(Category category) async {
    final safeId = _safeId(category.id.isEmpty ? category.name : category.id);
    final doc = _categories.doc(safeId);
    final now = DateTime.now();
    final model = CategoryModel.fromEntity(
      category.copyWith(
        id: safeId,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      ),
    );
    _log.info('Creating category id=$safeId name=${category.name}');
    await doc.set(model.toFirestore());
    return safeId;
  }

  @override
  Future<void> updateCategory(Category category) {
    final model = CategoryModel.fromEntity(
      category.copyWith(updatedAt: DateTime.now(), userId: _currentUserId),
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
