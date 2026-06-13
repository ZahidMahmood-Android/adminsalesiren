import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/repositories/firebase_brands_repository.dart';
import '../../domain/entities/brand.dart';
import '../../domain/repositories/brands_repository.dart';
import '../../domain/usecases/create_brand.dart';
import '../../domain/usecases/delete_brand.dart';
import '../../domain/usecases/update_brand.dart';

final brandsRepositoryProvider = Provider<BrandsRepository>((ref) {
  return FirebaseBrandsRepository(ref.watch(firestoreProvider));
});

final createBrandProvider = Provider<CreateBrand>((ref) {
  return CreateBrand(ref.watch(brandsRepositoryProvider));
});

final updateBrandProvider = Provider<UpdateBrand>((ref) {
  return UpdateBrand(ref.watch(brandsRepositoryProvider));
});

final deleteBrandProvider = Provider<DeleteBrand>((ref) {
  return DeleteBrand(ref.watch(brandsRepositoryProvider));
});

final brandsProvider = StreamProvider.autoDispose<List<Brand>>((ref) async* {
  yield const <Brand>[];
  yield* ref.watch(brandsRepositoryProvider).watchBrands();
});

final activeBrandsProvider = StreamProvider.autoDispose<List<Brand>>((
  ref,
) async* {
  yield const <Brand>[];
  yield* ref
      .watch(brandsRepositoryProvider)
      .watchBrands()
      .map((brands) => brands.where((brand) => brand.isActive).toList());
});

final brandProvider = FutureProvider.autoDispose.family<Brand?, String>(
  (ref, id) => ref.watch(brandsRepositoryProvider).getBrand(id),
);

final brandActionsProvider =
    AsyncNotifierProvider.autoDispose<BrandActionsController, void>(
      BrandActionsController.new,
    );

class BrandActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('BrandActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> save(Brand brand) async {
    final creating = brand.id.isEmpty;
    _log.info('${creating ? 'Create' : 'Update'} brand action started');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      if (creating) {
        return ref.read(createBrandProvider).call(brand);
      }
      return ref.read(updateBrandProvider).call(brand);
    });
    if (state.hasError) {
      _log.severe('Brand save action failed', state.error, state.stackTrace);
    } else {
      _log.info('${creating ? 'Create' : 'Update'} brand action completed');
    }
  }

  Future<void> delete(String id) async {
    _log.warning('Delete brand action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(deleteBrandProvider).call(id),
    );
    if (state.hasError) {
      _log.severe(
        'Delete brand action failed id=$id',
        state.error,
        state.stackTrace,
      );
    } else {
      _log.info('Delete brand action completed id=$id');
    }
  }
}
