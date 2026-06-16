import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_logger.dart';
import '../domain/repositories/master_data_seed_repository.dart';
import 'master_seed_data.dart';

class FirebaseMasterDataSeedRepository implements MasterDataSeedRepository {
  FirebaseMasterDataSeedRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = AppLogger.get('FirebaseMasterDataSeedRepository');

  @override
  Future<int> seedCities() async {
    for (final city in MasterSeedData.cities) {
      await _upsert('cities', city['id'] as String, city);
    }
    _log.info('Seeded cities count=${MasterSeedData.cities.length}');
    return MasterSeedData.cities.length;
  }

  @override
  Future<int> seedCategories() async {
    var sortOrder = 1;
    for (final row in MasterSeedData.categories) {
      final id = row[0] as String;
      await _upsert('categories', id, {
        'name': row[1],
        'slug': id,
        'description': _categoryDescription(id),
        'iconName': row[2],
        'colorHex': row[3],
        'isActive': row[4],
        'isFeatured': row[5],
        'sortOrder': sortOrder,
        'searchKeywords': _keywords(id, row[1] as String),
      });
      sortOrder++;
    }
    _log.info('Seeded categories count=${MasterSeedData.categories.length}');
    return MasterSeedData.categories.length;
  }

  @override
  Future<int> seedBrands() async {
    // Build slug → Firestore document ID maps so brand references use
    // the correct auto-generated IDs instead of human-readable slugs.
    final citySlugToId = await _buildSlugMap('cities');
    final catSlugToId = await _buildSlugMap('categories');

    var sortOrder = 1;
    for (final row in MasterSeedData.brands) {
      final id = row[0] as String;
      final name = row[1] as String;
      final seedWebsite = row[6] as String;
      final seedLogo = row[7] as String;
      final seedEmail = row[8] as String;

      final citySlugs = _csv(row[5] as String);
      final catSlugs = _csv(row[4] as String);
      final primaryCatSlug = row[3] as String;

      // Resolve slugs → IDs; fall back to slug if not yet seeded.
      final resolvedCityIds = citySlugs
          .map((s) => citySlugToId[s] ?? s)
          .toList();
      final resolvedCatIds = catSlugs.map((s) => catSlugToId[s] ?? s).toList();
      final resolvedPrimaryId = catSlugToId[primaryCatSlug] ?? primaryCatSlug;

      await _upsert(
        'brands',
        id,
        {
          'name': name,
          'slug': id,
          'description': '',
          'logoUrl': seedLogo,
          'websiteUrl': seedWebsite,
          'instagramUrl': '',
          'facebookUrl': '',
          'businessContactEmail': seedEmail,
          'primaryCategoryId': resolvedPrimaryId,
          'categoryIds': resolvedCatIds,
          'cityIds': resolvedCityIds,
          'type': row[2],
          'isActive': true,
          'isVerified': true,
          'isFeatured': sortOrder <= 12,
          'sortOrder': sortOrder,
          'searchKeywords': _keywords(id, name),
        },
        preserveKeys: const [
          'logoUrl',
          'websiteUrl',
          'instagramUrl',
          'facebookUrl',
          'businessContactEmail',
          'businessContactName',
          'businessContactPhone',
        ],
      );
      sortOrder++;
    }
    _log.info('Seeded brands count=${MasterSeedData.brands.length}');
    return MasterSeedData.brands.length;
  }

  /// Loads all documents in [collection] and returns a map of slug → doc ID.
  Future<Map<String, String>> _buildSlugMap(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    final map = <String, String>{};
    for (final doc in snapshot.docs) {
      final slug = doc.data()['slug'] as String?;
      if (slug != null && slug.isNotEmpty) {
        map[slug] = doc.id;
      }
    }
    return map;
  }

  Future<void> _upsert(
    String collection,
    String id,
    Map<String, Object?> data, {
    List<String> preserveKeys = const [],
  }) async {
    final existingBySlug = await _firestore
        .collection(collection)
        .where('slug', isEqualTo: id)
        .limit(1)
        .get();
    final doc = existingBySlug.docs.isEmpty
        ? _firestore.collection(collection).doc()
        : existingBySlug.docs.first.reference;
    final snapshot = await doc.get();
    final existing = snapshot.data() ?? <String, dynamic>{};
    final payload = Map<String, Object?>.from(data)
      ..['updatedAt'] = FieldValue.serverTimestamp();

    payload['id'] = doc.id;
    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    for (final key in preserveKeys) {
      final value = existing[key];
      if (value is String && value.trim().isNotEmpty) {
        payload.remove(key);
      }
    }

    await doc.set(payload, SetOptions(merge: true));
  }

  List<String> _csv(String value) {
    return value.split(',').map((item) => item.trim()).toList();
  }

  List<String> _keywords(String id, String name) {
    return {
      id,
      name.toLowerCase(),
      ...name.toLowerCase().split(RegExp(r'[^a-z0-9]+')),
    }.where((item) => item.isNotEmpty).toList();
  }

  String _categoryDescription(String id) {
    return switch (id) {
      'grocery' => 'Supermarket, grocery, household and daily-use offers.',
      'fashion' => 'Clothing, apparel and fashion brand offers.',
      'restaurants' => 'Restaurant, fast food and dining offers.',
      'electronics' => 'Electronics, appliances and gadget offers.',
      _ => '',
    };
  }
}
