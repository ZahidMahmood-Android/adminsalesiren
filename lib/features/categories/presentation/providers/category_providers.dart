import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../data/repositories/firebase_categories_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return FirebaseCategoriesRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider).currentUser?.uid ?? '',
  );
});

final categoriesProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchCategories();
});

final activeCategoriesProvider = StreamProvider.autoDispose<List<Category>>((
  ref,
) {
  return ref
      .watch(categoriesRepositoryProvider)
      .watchCategories()
      .map((items) => items.where((category) => category.isActive).toList());
});

final visibleCategoriesProvider = StreamProvider.autoDispose<List<Category>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  final categories = ref.watch(categoriesProvider);
  return categories.when(
    data: (items) {
      if (!_isBrandScopedRole(user?.role)) {
        return Stream.value(items);
      }
      final brands = ref.watch(brandsProvider);
      final brandItems = brands.value ?? const <Brand>[];
      final brand = _findBrand(brandItems, user?.brandId ?? '');
      final allowed = brand?.categoryIds.toSet() ?? const <String>{};
      return Stream.value(
        items
            .where(
              (category) =>
                  allowed.contains(category.id) || category.userId == user?.id,
            )
            .toList(),
      );
    },
    loading: () => Stream.value(const <Category>[]),
    error: (error, stackTrace) => Stream.error(error, stackTrace),
  );
});

bool _isBrandScopedRole(String? role) => role == UserRoles.brandAdmin;

Brand? _findBrand(Iterable<Brand> brands, String id) {
  for (final brand in brands) {
    if (brand.id == id) {
      return brand;
    }
  }
  return null;
}

final categoryProvider = FutureProvider.autoDispose.family<Category?, String>(
  (ref, id) => ref.watch(categoriesRepositoryProvider).getCategory(id),
);

final categoryActionsProvider =
    AsyncNotifierProvider.autoDispose<CategoryActionsController, void>(
      CategoryActionsController.new,
    );

class CategoryActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('CategoryActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> save(Category category, {required bool isEditing}) async {
    final creating = !isEditing;
    _log.info('${creating ? 'Create' : 'Update'} category action started');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      if (creating) {
        return ref.read(categoriesRepositoryProvider).createCategory(category);
      }
      return ref.read(categoriesRepositoryProvider).updateCategory(category);
    });
    _logResult('${creating ? 'Create' : 'Update'} category action');
  }

  Future<void> delete(String id) async {
    _log.warning('Delete category action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(categoriesRepositoryProvider).deleteCategory(id),
    );
    _logResult('Delete category action');
  }

  void _logResult(String label) {
    if (state.hasError) {
      _log.severe('$label failed', state.error, state.stackTrace);
    } else {
      _log.info('$label completed');
    }
  }
}
