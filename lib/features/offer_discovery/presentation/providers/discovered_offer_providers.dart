import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../access/domain/app_feature_seed_data.dart';
import '../../../access/domain/feature_access_utils.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/domain/entities/category.dart' as app_category;
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/domain/entities/city.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/utils/offer_discount_parse_utils.dart';
import '../../../offers/presentation/providers/offer_providers.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/repositories/firebase_offer_discovery_settings_repository.dart';
import '../../data/repositories/firebase_discovered_offers_repository.dart';
import '../../data/services/offer_discovery_callable_service.dart';
import '../../domain/entities/offer_discovery_settings.dart';
import '../../domain/entities/discovered_offer.dart';
import '../../domain/entities/discovered_offer_status.dart';
import '../../domain/repositories/discovered_offers_repository.dart';

final offerDiscoverySettingsRepositoryProvider =
    Provider<FirebaseOfferDiscoverySettingsRepository>(
      (ref) => FirebaseOfferDiscoverySettingsRepository(
        ref.watch(firestoreProvider),
      ),
    );

final offerDiscoverySettingsProvider =
    StreamProvider.autoDispose<OfferDiscoverySettings>((ref) {
      return ref.watch(offerDiscoverySettingsRepositoryProvider).watchSettings();
    });

bool canAccessOfferDiscovery(AppUser? user) {
  if (user == null) {
    return false;
  }
  if (FeatureAccessUtils.grantsAllFeatures(user)) {
    return true;
  }
  return FeatureAccessUtils.hasFeature(user, AppFeatureIds.adminOfferDiscovery);
}

final canAccessOfferDiscoveryProvider = Provider<bool>((ref) {
  return canAccessOfferDiscovery(ref.watch(currentUserProvider));
});

final canManageOfferDiscoveryScheduleProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return false;
  }
  return canAccessOfferDiscovery(user);
});

final canRunOfferDiscoveryProvider = Provider<bool>((ref) {
  return ref.watch(canAccessOfferDiscoveryProvider);
});

final discoveredOffersRepositoryProvider = Provider<DiscoveredOffersRepository>(
  (ref) => FirebaseDiscoveredOffersRepository(ref.watch(firestoreProvider)),
);

final offerDiscoveryCallableServiceProvider =
    Provider<OfferDiscoveryCallableService>(
      (ref) => OfferDiscoveryCallableService(
        ref.watch(firebaseFunctionsProvider),
        ref.watch(firestoreProvider),
      ),
    );

final discoveredOfferStatusFilterProvider = StateProvider.autoDispose<String>(
  (ref) => DiscoveredOfferStatuses.pendingReview,
);

final discoveredOffersStreamProvider =
    StreamProvider.autoDispose<List<DiscoveredOffer>>((ref) {
      final status = ref.watch(discoveredOfferStatusFilterProvider);
      return ref.watch(discoveredOffersRepositoryProvider).watchByStatus(status);
    });

final offerDiscoveryRunProvider =
    AsyncNotifierProvider.autoDispose<OfferDiscoveryRunController, void>(
      OfferDiscoveryRunController.new,
    );

final offerDiscoveryClearProvider =
    AsyncNotifierProvider.autoDispose<OfferDiscoveryClearController, void>(
      OfferDiscoveryClearController.new,
    );

class OfferDiscoveryClearController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> clearAll() async {
    state = const AsyncLoading();
    late int deletedCount;
    state = await AsyncValue.guard(() async {
      deletedCount = await ref
          .read(discoveredOffersRepositoryProvider)
          .clearAll();
      ref.invalidate(discoveredOffersStreamProvider);
    });
    if (state.hasError) {
      throw state.error!;
    }
    return deletedCount;
  }
}

class OfferDiscoveryRunController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<OfferDiscoveryRunResult> runNow() async {
    state = const AsyncLoading();
    late OfferDiscoveryRunResult result;
    state = await AsyncValue.guard(() async {
      result = await ref
          .read(offerDiscoveryCallableServiceProvider)
          .runDiscoveryNow();
      ref.invalidate(discoveredOffersStreamProvider);
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }
}

final offerDiscoverySettingsActionsProvider =
    AsyncNotifierProvider.autoDispose<OfferDiscoverySettingsActionsController, void>(
      OfferDiscoverySettingsActionsController.new,
    );

class OfferDiscoverySettingsActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(OfferDiscoverySettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      await ref
          .read(offerDiscoverySettingsRepositoryProvider)
          .saveSettings(settings, updatedByUserId: userId);
      ref.invalidate(offerDiscoverySettingsProvider);
    });
  }
}

final discoveredOfferActionsProvider =
    AsyncNotifierProvider.autoDispose<DiscoveredOfferActionsController, void>(
      DiscoveredOfferActionsController.new,
    );

class DiscoveredOfferActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> convertToOfficialOffer(DiscoveredOffer discovered) async {
    state = const AsyncLoading();
    String? offerId;
    state = await AsyncValue.guard(() async {
      final brand = await ref
          .read(brandsRepositoryProvider)
          .getBrand(discovered.brandId);
      final categories = ref.read(categoriesProvider).value ?? const [];
      final cities = ref.read(citiesProvider).value ?? const [];
      final draft = _buildDraftOffer(
        discovered: discovered,
        brandCategoryIds: brand?.categoryIds ?? discovered.suggestedCategoryCodes,
        brandCityIds: brand?.cityIds ?? discovered.suggestedCityCodes,
        categories: categories,
        cities: cities,
        userId: ref.read(currentUserProvider)?.id ?? '',
      );
      offerId = await ref
          .read(discoveredOffersRepositoryProvider)
          .convertToOfficialOffer(
            discovered: discovered,
            draftOffer: draft,
          );
      ref.invalidate(discoveredOffersStreamProvider);
      ref.invalidate(offersStreamProvider);
    });
    return offerId;
  }

  Future<void> reject(DiscoveredOffer discovered, {String reason = ''}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(discoveredOffersRepositoryProvider)
          .reject(id: discovered.id, rejectionReason: reason);
      ref.invalidate(discoveredOffersStreamProvider);
    });
  }

  Future<void> markDuplicate(
    DiscoveredOffer discovered, {
    String duplicateOfOfferId = '',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(discoveredOffersRepositoryProvider)
          .markDuplicate(
            id: discovered.id,
            duplicateOfOfferId: duplicateOfOfferId,
          );
      ref.invalidate(discoveredOffersStreamProvider);
    });
  }
}

Offer _buildDraftOffer({
  required DiscoveredOffer discovered,
  required List<String> brandCategoryIds,
  required List<String> brandCityIds,
  required List<app_category.Category> categories,
  required List<City> cities,
  required String userId,
}) {
  final categoryIds = _resolveIds(
    codes: discovered.suggestedCategoryCodes,
    fallback: brandCategoryIds,
    lookup: {
      for (final item in categories) item.id: item.id,
      for (final item in categories)
        if (item.slug.isNotEmpty) item.slug: item.id,
    },
  );
  final cityIds = _resolveIds(
    codes: discovered.suggestedCityCodes,
    fallback: brandCityIds,
    lookup: {
      for (final item in cities) item.id: item.id,
      for (final item in cities) if (item.slug.isNotEmpty) item.slug: item.id,
    },
  );

  final categoryNames = categoryIds
      .map((id) => _nameForId(categories, id, (item) => item.id, (item) => item.name))
      .whereType<String>()
      .toList();
  final cityNames = cityIds
      .map((id) => _nameForId(cities, id, (item) => item.id, (item) => item.name))
      .whereType<String>()
      .toList();

  final primaryCategoryId = categoryIds.isNotEmpty ? categoryIds.first : '';
  final primaryCategoryName = categoryNames.isNotEmpty
      ? categoryNames.first
      : '';
  final primaryCityId = cityIds.isNotEmpty ? cityIds.first : '';
  final primaryCityName = cityNames.isNotEmpty ? cityNames.first : '';

  final now = DateTime.now();
  final discountSource = discovered.suggestedDiscountText.trim().isNotEmpty
      ? discovered.suggestedDiscountText
      : discovered.suggestedTitle;
  final discount = OfferDiscountParseUtils.resolve(
    discountText: discountSource,
    discountType: discovered.suggestedDiscountType,
    discountValue: discovered.suggestedDiscountValue,
  );
  return Offer(
    id: '',
    title: discovered.suggestedTitle,
    description: discovered.suggestedDescription,
    brandId: discovered.brandId,
    brandName: discovered.brandName,
    categoryId: primaryCategoryId,
    categoryName: primaryCategoryName,
    cityId: primaryCityId,
    cityName: primaryCityName,
    categoryIds: categoryIds,
    categoryNames: categoryNames,
    cityIds: cityIds,
    cityNames: cityNames,
    discountText: discount.discountText,
    discountType: discount.discountType,
    discountValue: discount.discountValue,
    imageUrl: discovered.imageUrl,
    imageUrls: discovered.imageUrl.isEmpty
        ? const []
        : [discovered.imageUrl],
    sourceUrl: discovered.sourceUrl,
    onlineUrl: discovered.sourceUrl,
    startDate: now,
    endDate: null,
    isVerified: false,
    isPublished: false,
    isFeatured: false,
    aiConfidence: discovered.confidenceScore,
    createdBy: userId,
    createdAt: now,
    updatedAt: now,
    createdByUserId: userId,
    createdByRole: 'owner',
    status: 'draft',
    approvalStatus: 'pending',
    sourceType: 'discovered_offer',
    discoveredOfferId: discovered.id,
  );
}

List<String> _resolveIds({
  required List<String> codes,
  required List<String> fallback,
  required Map<String, String> lookup,
}) {
  final resolved = <String>[];
  for (final code in codes) {
    final key = code.trim();
    if (key.isEmpty) {
      continue;
    }
    final id = lookup[key] ?? key;
    if (!resolved.contains(id)) {
      resolved.add(id);
    }
  }
  if (resolved.isNotEmpty) {
    return resolved;
  }
  return fallback.where((id) => id.trim().isNotEmpty).toList();
}

String? _nameForId<T>(
  List<T> items,
  String id,
  String Function(T item) idOf,
  String Function(T item) nameOf,
) {
  for (final item in items) {
    if (idOf(item) == id) {
      return nameOf(item);
    }
  }
  return null;
}

Future<void> convertDiscoveredOfferAndOpenEditor(
  WidgetRef ref,
  DiscoveredOffer discovered,
  void Function(String route) navigate,
) async {
  final offerId = await ref
      .read(discoveredOfferActionsProvider.notifier)
      .convertToOfficialOffer(discovered);
  if (offerId != null && offerId.isNotEmpty) {
    navigate('/offers/$offerId/edit');
  }
}
