import 'package:cloud_firestore/cloud_firestore.dart';

import 'saved_brands_sync.dart';
import 'selected_categories_sync.dart';
import 'selected_cities_sync.dart';

class UserPreferencesSync {
  const UserPreferencesSync._();

  static Future<({
    List<String> categoryIds,
    List<String> cityIds,
    List<String> brandIds,
  })> fetch(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    final results = await Future.wait([
      SelectedCategoriesSync.fetch(firestore, userId),
      SelectedCitiesSync.fetch(firestore, userId),
      SavedBrandsSync.fetch(firestore, userId),
    ]);
    return (
      categoryIds: results[0],
      cityIds: results[1],
      brandIds: results[2],
    );
  }

  static Future<void> sync(
    FirebaseFirestore firestore,
    String userId, {
    required List<String> categoryIds,
    required List<String> cityIds,
    required List<String> brandIds,
  }) async {
    await SelectedCategoriesSync.sync(firestore, userId, categoryIds);
    await SelectedCitiesSync.sync(firestore, userId, cityIds);
    await SavedBrandsSync.sync(firestore, userId, brandIds);
  }
}
