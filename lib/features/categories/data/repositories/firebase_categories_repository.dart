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
    return _categories.orderBy('sortOrder').snapshots().map((snapshot) {
      final categories = snapshot.docs.map(CategoryModel.fromSnapshot).toList();
      return categories;
    });
  }

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _categories.orderBy('sortOrder').get();
    return snapshot.docs.map(CategoryModel.fromSnapshot).toList();
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
    return CategoryModel.fromSnapshot(snapshot);
  }

  @override
  Future<String> createCategory(Category category) async {
    final doc = _categories.doc();
    final id = doc.id;
    final now = DateTime.now();
    final slug = category.slug.isEmpty ? _safeId(category.name) : category.slug;
    final model = CategoryModel.fromEntity(
      category.copyWith(
        id: id,
        slug: slug,
        topic: category.topic.isEmpty
            ? _topicFor(category.name, id)
            : category.topic,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      ),
    );
    _log.info('Creating category id=$id name=${category.name}');
    final data = model.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    return id;
  }

  @override
  Future<void> updateCategory(Category category) {
    final model = CategoryModel.fromEntity(
      category.copyWith(
        topic: category.topic.isEmpty
            ? _topicFor(category.name, category.id)
            : category.topic,
        updatedAt: DateTime.now(),
        userId: _currentUserId,
      ),
    );
    _log.info('Updating category id=${category.id} name=${category.name}');
    final data = model.toFirestore(includeCreatedAt: false)
      ..['updatedAt'] = FieldValue.serverTimestamp();
    return _categories.doc(category.id).update(data);
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

  String _topicFor(String name, String id) {
    final base = _safeId(name).replaceAll('-', '');
    final prefix = base.length <= 8 ? base : base.substring(0, 8);
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
