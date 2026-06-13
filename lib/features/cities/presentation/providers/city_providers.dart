import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/repositories/firebase_cities_repository.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/cities_repository.dart';

final citiesRepositoryProvider = Provider<CitiesRepository>((ref) {
  return FirebaseCitiesRepository(ref.watch(firestoreProvider));
});

final citiesProvider = StreamProvider.autoDispose<List<City>>((ref) async* {
  yield const <City>[];
  yield* ref.watch(citiesRepositoryProvider).watchCities();
});

final activeCitiesProvider = StreamProvider.autoDispose<List<City>>((
  ref,
) async* {
  yield const <City>[];
  yield* ref
      .watch(citiesRepositoryProvider)
      .watchCities()
      .map((cities) => cities.where((city) => city.isActive).toList());
});

final cityProvider = FutureProvider.autoDispose.family<City?, String>(
  (ref, id) => ref.watch(citiesRepositoryProvider).getCity(id),
);

final cityActionsProvider =
    AsyncNotifierProvider.autoDispose<CityActionsController, void>(
      CityActionsController.new,
    );

class CityActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('CityActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> save(City city) async {
    final creating = city.id.isEmpty;
    _log.info('${creating ? 'Create' : 'Update'} city action started');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      if (creating) {
        return ref.read(citiesRepositoryProvider).createCity(city);
      }
      return ref.read(citiesRepositoryProvider).updateCity(city);
    });
    _logResult('${creating ? 'Create' : 'Update'} city action');
  }

  Future<void> delete(String id) async {
    _log.warning('Delete city action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(citiesRepositoryProvider).deleteCity(id),
    );
    _logResult('Delete city action');
  }

  void _logResult(String label) {
    if (state.hasError) {
      _log.severe('$label failed', state.error, state.stackTrace);
    } else {
      _log.info('$label completed');
    }
  }
}
