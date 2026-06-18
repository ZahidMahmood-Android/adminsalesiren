import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
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
import '../../../subscriptions/presentation/providers/subscription_providers.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return FirebaseOffersRepository(
    ref.watch(firestoreProvider),
    user?.id ?? ref.watch(firebaseAuthProvider).currentUser?.uid ?? '',
    user?.role ?? 'super_admin',
    user?.brandId ?? '',
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

final offersProvider = StreamProvider.autoDispose<List<Offer>>((ref) {
  final filters = ref.watch(offerFiltersProvider);
  return ref.watch(offersRepositoryProvider).watchOffers(filters);
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

  bool _isBrandScopedRole(String? role) =>
      role == UserRoles.brandAdmin || role == UserRoles.manager;

  @override
  FutureOr<void> build() {}

  Future<String?> create(Offer offer) async {
    _log.info('Create offer action started title=${offer.title}');
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      id = await ref.read(createOfferProvider).call(offer);
      final user = ref.read(currentUserProvider);
      await _createOfferNotification(
        offer.copyWith(
          id: id,
          createdByUserId: user?.id ?? '',
          createdByRole: user?.role ?? 'super_admin',
        ),
      );
    });
    _refreshOffers(id: id);
    _logActionResult('Create offer action', id: id);
    return id;
  }

  Future<void> saveChanges(Offer offer) async {
    _log.info('Update offer action started id=${offer.id}');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(updateOfferProvider).call(offer),
    );
    _refreshOffers(id: offer.id);
    _logActionResult('Update offer action', id: offer.id);
  }

  Future<void> delete(String id) async {
    _log.warning('Delete offer action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Before deleting, check if this was an unpublished brand-admin offer
      // so we can give back the quota that was consumed when it was created.
      try {
        final offer = await ref.read(offersRepositoryProvider).getOffer(id);
        if (offer != null &&
            !offer.isPublished &&
            _isBrandScopedRole(offer.createdByRole) &&
            offer.brandId.isNotEmpty) {
          await ref
              .read(subscriptionsRepositoryProvider)
              .incrementUsage(offer.brandId, offersCreated: -1);
          _log.info(
            'Decremented offersCreated usage for brandId=${offer.brandId}',
          );
        }
      } catch (e) {
        // Usage decrement is best-effort; don't block the delete.
        _log.warning('Could not decrement usage before delete: $e');
      }
      await ref
          .read(notificationsRepositoryProvider)
          .deleteRequestsForOffer(id);
      await ref.read(deleteOfferProvider).call(id);
    });
    ref.invalidate(notificationRequestsProvider);
    _refreshOffers(id: id);
    _logActionResult('Delete offer action', id: id);
  }

  Future<void> publish(String id, bool isPublished) async {
    _log.info('Publish offer action started id=$id value=$isPublished');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(offersRepositoryProvider).publishOffer(id, isPublished);
      if (isPublished) {
        final offer = await ref.read(offersRepositoryProvider).getOffer(id);
        if (offer != null) {
          await _createOfferNotification(offer.copyWith(isPublished: true));
        }
      }
    });
    _refreshOffers(id: id);
    _logActionResult('Publish offer action', id: id);
  }

  Future<void> expire(String id) async {
    _log.info('Expire offer action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(offersRepositoryProvider).expireOffer(id),
    );
    _refreshOffers(id: id);
    _logActionResult('Expire offer action', id: id);
  }

  Future<void> verify(String id, bool isVerified) async {
    _log.info('Verify offer action started id=$id value=$isVerified');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(offersRepositoryProvider).verifyOffer(id, isVerified),
    );
    _refreshOffers(id: id);
    _logActionResult('Verify offer action', id: id);
  }

  Future<void> feature(String id, bool isFeatured) async {
    _log.info('Feature offer action started id=$id value=$isFeatured');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (isFeatured) {
        final offer = await ref.read(offersRepositoryProvider).getOffer(id);
        if (offer == null || !offer.isVerified) {
          throw StateError('Only verified offers can be featured.');
        }
      }
      await ref.read(offersRepositoryProvider).featureOffer(id, isFeatured);
    });
    _refreshOffers(id: id);
    _logActionResult('Feature offer action', id: id);
  }

  Future<void> approve(String id) async {
    final user = ref.read(currentUserProvider);
    _log.info('Approve offer action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(offersRepositoryProvider).approveOffer(id, user?.id ?? ''),
    );
    _refreshOffers(id: id);
    _logActionResult('Approve offer action', id: id);
  }

  Future<void> reject(String id, String notes) async {
    final user = ref.read(currentUserProvider);
    _log.info('Reject offer action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(offersRepositoryProvider)
          .rejectOffer(id, notes, user?.id ?? ''),
    );
    _refreshOffers(id: id);
    _logActionResult('Reject offer action', id: id);
  }

  void _refreshOffers({String? id}) {
    if (state.hasError) {
      return;
    }
    ref.invalidate(offersProvider);
    if (id != null && id.isNotEmpty) {
      ref.invalidate(offerProvider(id));
    }
  }

  void _logActionResult(String label, {String? id}) {
    if (state.hasError) {
      _log.severe('$label failed id=$id', state.error, state.stackTrace);
    } else {
      _log.info('$label completed id=$id');
    }
  }

  Future<void> _createOfferNotification(Offer offer) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user?.role == UserRoles.brandAdmin && offer.brandId.isNotEmpty) {
        final limitMessage = await ref
            .read(subscriptionActionsProvider.notifier)
            .checkPushNotificationLimits(offer.brandId);
        if (limitMessage != null) {
          _log.warning(
            'Notification request blocked for offer id=${offer.id}: $limitMessage',
          );
          return;
        }
      }
      final categoryIds = offer.categoryIds.isEmpty
          ? [offer.categoryId]
          : offer.categoryIds;
      final categoryTopics = await _topicsForCategoryIds(categoryIds);
      await ref
          .read(createNotificationRequestProvider)
          .call(
            NotificationRequest(
              id: '',
              title: 'New offer available',
              body: '${offer.brandName}: ${offer.discountText}',
              topic: categoryTopics.isEmpty ? '' : categoryTopics.first,
              type: 'new_offer',
              data: {
                'offerId': offer.id,
                'brandId': offer.brandId,
                'categoryId': offer.categoryId,
                'categoryIds': categoryIds.join(','),
                'categoryTopics': categoryTopics.join(','),
                'cityId': offer.cityId,
                'cityIds': offer.cityIds.join(','),
              },
              brandId: offer.brandId,
              offerId: offer.id,
              requestedByUserId: offer.createdByUserId,
              targetCityIds: offer.cityIds.isEmpty
                  ? [offer.cityId]
                  : offer.cityIds,
              targetCategoryIds: categoryIds,
              targetTopics: categoryTopics,
              status: offer.isPublished ? 'approved' : 'pending',
              createdAt: DateTime.now(),
            ),
          );
      if (user?.role == UserRoles.brandAdmin && offer.brandId.isNotEmpty) {
        await ref
            .read(subscriptionActionsProvider.notifier)
            .recordPushRequested(offer.brandId);
      }
    } catch (error, stackTrace) {
      _log.warning(
        'Notification request skipped for offer id=${offer.id}',
        error,
        stackTrace,
      );
    }
  }

  Future<List<String>> _topicsForCategoryIds(List<String> categoryIds) async {
    final ids = categoryIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.isEmpty) {
      return const [];
    }
    final categories = await ref.read(categoriesProvider.future);
    return categories
        .where((category) => ids.contains(category.id))
        .map((category) => category.topic.trim())
        .where((topic) => topic.isNotEmpty)
        .toSet()
        .toList();
  }
}
