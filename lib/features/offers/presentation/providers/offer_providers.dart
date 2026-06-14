import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/repositories/firebase_offer_image_repository.dart';
import '../../data/repositories/firebase_offers_repository.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_filters.dart';
import '../../domain/repositories/offer_image_repository.dart';
import '../../domain/repositories/offers_repository.dart';
import '../../domain/usecases/create_offer.dart';
import '../../domain/usecases/delete_offer.dart';
import '../../domain/usecases/update_offer.dart';
import '../../../notifications/domain/entities/notification_request.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return FirebaseOffersRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider).currentUser?.uid ?? '',
  );
});

final offerImageRepositoryProvider = Provider<OfferImageRepository>((ref) {
  return FirebaseOfferImageRepository(ref.watch(firebaseStorageProvider));
});

final createOfferProvider = Provider<CreateOffer>((ref) {
  return CreateOffer(ref.watch(offersRepositoryProvider));
});

final updateOfferProvider = Provider<UpdateOffer>((ref) {
  return UpdateOffer(ref.watch(offersRepositoryProvider));
});

final deleteOfferProvider = Provider<DeleteOffer>((ref) {
  return DeleteOffer(ref.watch(offersRepositoryProvider));
});

final offerFiltersProvider =
    NotifierProvider<OfferFiltersController, OfferFilters>(
      OfferFiltersController.new,
    );

class OfferFiltersController extends Notifier<OfferFilters> {
  final _log = AppLogger.get('OfferFiltersController');

  @override
  OfferFilters build() => const OfferFilters();

  void update(OfferFilters filters) {
    _log.fine(
      'Offer filters updated city=${filters.cityId} category=${filters.categoryId} brand=${filters.brandId} published=${filters.isPublished} verified=${filters.isVerified}',
    );
    state = filters;
  }

  void clear() {
    _log.fine('Offer filters cleared');
    state = const OfferFilters();
  }
}

final offersProvider = StreamProvider.autoDispose<List<Offer>>((ref) async* {
  final filters = ref.watch(offerFiltersProvider);
  yield const <Offer>[];
  yield* ref.watch(offersRepositoryProvider).watchOffers(filters);
});

final offerProvider = FutureProvider.autoDispose.family<Offer?, String>(
  (ref, id) => ref.watch(offersRepositoryProvider).getOffer(id),
);

final offerActionsProvider =
    AsyncNotifierProvider.autoDispose<OfferActionsController, void>(
      OfferActionsController.new,
    );

class OfferActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('OfferActionsController');

  @override
  FutureOr<void> build() {}

  Future<String?> create(Offer offer) async {
    _log.info('Create offer action started title=${offer.title}');
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      id = await ref.read(createOfferProvider).call(offer);
      await ref.read(createNotificationRequestProvider).call(
            NotificationRequest(
              id: '',
              title: 'New offer available',
              body: '${offer.brandName}: ${offer.discountText}',
              topic: 'all_users',
              type: 'new_offer',
              data: {
                'offerId': id ?? '',
                'brandId': offer.brandId,
                'categoryId': offer.categoryId,
                'cityId': offer.cityId,
              },
              status: 'pending',
              createdAt: DateTime.now(),
            ),
          );
    });
    _logActionResult('Create offer action', id: id);
    return id;
  }

  Future<void> saveChanges(Offer offer) async {
    _log.info('Update offer action started id=${offer.id}');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(updateOfferProvider).call(offer),
    );
    _logActionResult('Update offer action', id: offer.id);
  }

  Future<void> delete(String id) async {
    _log.warning('Delete offer action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(deleteOfferProvider).call(id),
    );
    _logActionResult('Delete offer action', id: id);
  }

  Future<void> publish(String id, bool isPublished) async {
    _log.info('Publish offer action started id=$id value=$isPublished');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(offersRepositoryProvider).publishOffer(id, isPublished),
    );
    _logActionResult('Publish offer action', id: id);
  }

  Future<void> verify(String id, bool isVerified) async {
    _log.info('Verify offer action started id=$id value=$isVerified');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(offersRepositoryProvider).verifyOffer(id, isVerified),
    );
    _logActionResult('Verify offer action', id: id);
  }

  Future<void> feature(String id, bool isFeatured) async {
    _log.info('Feature offer action started id=$id value=$isFeatured');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(offersRepositoryProvider).featureOffer(id, isFeatured),
    );
    _logActionResult('Feature offer action', id: id);
  }

  void _logActionResult(String label, {String? id}) {
    if (state.hasError) {
      _log.severe('$label failed id=$id', state.error, state.stackTrace);
    } else {
      _log.info('$label completed id=$id');
    }
  }
}
