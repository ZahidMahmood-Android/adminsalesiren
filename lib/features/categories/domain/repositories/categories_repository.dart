import '../entities/category.dart';

abstract class CategoriesRepository {
  Stream<List<Category>> watchCategories();
  Future<List<Category>> getCategories();
  Future<Category?> getCategory(String id);
  Future<String> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
}
