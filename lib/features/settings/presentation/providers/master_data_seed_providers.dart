import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/firebase_master_data_seed_repository.dart';
import '../../domain/repositories/master_data_seed_repository.dart';

final masterDataSeedRepositoryProvider = Provider<MasterDataSeedRepository>((
  ref,
) {
  return FirebaseMasterDataSeedRepository(ref.watch(firestoreProvider));
});

final masterDataSeedActionsProvider =
    AsyncNotifierProvider<MasterDataSeedActionsController, String?>(
      MasterDataSeedActionsController.new,
    );

class MasterDataSeedActionsController extends AsyncNotifier<String?> {
  final _log = AppLogger.get('MasterDataSeedActionsController');

  @override
  FutureOr<String?> build() => null;

  Future<void> seedCities() => _seed(
    label: 'Cities',
    action: ref.read(masterDataSeedRepositoryProvider).seedCities,
  );

  Future<void> seedCategories() => _seed(
    label: 'Categories',
    action: ref.read(masterDataSeedRepositoryProvider).seedCategories,
  );

  Future<void> seedBrands() => _seed(
    label: 'Brands',
    action: ref.read(masterDataSeedRepositoryProvider).seedBrands,
  );

  Future<void> seedRoles() => _seed(
    label: 'Roles',
    action: ref.read(masterDataSeedRepositoryProvider).seedRoles,
  );

  Future<void> seedAppFeatures() => _seed(
    label: 'App features',
    action: ref.read(masterDataSeedRepositoryProvider).seedAppFeatures,
  );

  Future<void> _seed({
    required String label,
    required Future<int> Function() action,
  }) async {
    _log.info('Seed $label started');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final count = await action();
      _log.info('Seed $label completed count=$count');
      return '$label seeded successfully ($count records).';
    });
    if (state.hasError) {
      _log.severe('Seed $label failed', state.error, state.stackTrace);
    }
  }
}
