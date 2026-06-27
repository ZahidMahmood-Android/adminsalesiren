import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/repositories/firebase_offer_image_repository.dart';
import '../../data/repositories/firebase_offers_repository.dart';
import '../../presentation/widgets/offer_lines_editor.dart'
    show kWholeBrandCategoryLabel;
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_line.dart';
import '../../domain/entities/offer_filters.dart';
import '../../domain/repositories/offer_image_repository.dart';
import '../../domain/repositories/offers_repository.dart';
import '../../domain/usecases/create_offer.dart';
import '../../domain/usecases/delete_offer.dart';
import '../../domain/usecases/update_offer.dart';
import '../../../notifications/domain/offer_alert_input_mapper.dart';
import '../../../notifications/domain/entities/notification_request.dart';
import '../../../notifications/domain/entities/offer_notification_draft.dart';
import '../../../notifications/domain/entities/offer_notification_content_utils.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../../settings/presentation/providers/app_settings_providers.dart';

import 'package:sale_siren_models/sale_siren_models.dart'
    show OfferNotificationSnapshot;

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return FirebaseOffersRepository(
    ref.watch(firestoreProvider),
    user?.id ?? ref.watch(firebaseAuthProvider).currentUser?.uid ?? '',
    user?.role ?? 'owner',
    ref.watch(offerImageRepositoryProvider),
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

final offersListSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
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

final offersStreamProvider = StreamProvider.autoDispose<List<Offer>>((ref) {
  return ref.watch(offersRepositoryProvider).watchOffers(const OfferFilters());
});

final offersProvider = Provider.autoDispose<AsyncValue<List<Offer>>>((ref) {
  final filters = ref.watch(offerFiltersProvider);
  return ref.watch(offersStreamProvider).whenData(filters.applyTo);
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

  Future<String?> create(
    Offer offer, {
    Map<String, OfferNotificationDraft>? notificationDrafts,
  }) async {
    _log.info('Create offer action started title=${offer.title}');
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      final dispatchAfterSave = notificationDrafts != null && offer.isPublished;
      id = await ref
          .read(createOfferProvider)
          .call(
            offer,
            sendNotification: !dispatchAfterSave && offer.isPublished,
          );
      final user = ref.read(currentUserProvider);
      final savedOffer = offer.copyWith(
        id: id,
        createdByUserId: user?.id ?? '',
        createdByRole: user?.role ?? 'owner',
      );
      if (dispatchAfterSave) {
        await ref
            .read(notificationsRepositoryProvider)
            .deleteRequestsForOffer(id!);
        final requestIds = await _createOfferNotifications(
          savedOffer,
          notificationDrafts: notificationDrafts,
        );
        await _dispatchOfferNotifications(offerId: id!, requestIds: requestIds);
        ref.invalidate(notificationRequestsProvider);
      } else {
        await _createOfferNotifications(
          savedOffer,
          notificationDrafts: notificationDrafts,
        );
      }
    });
    _refreshOffers(id: id);
    _logActionResult('Create offer action', id: id);
    return id;
  }

  Future<void> saveChanges(
    Offer offer, {
    Map<String, OfferNotificationDraft>? notificationDrafts,
  }) async {
    _log.info('Update offer action started id=${offer.id}');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dispatchAfterSave = notificationDrafts != null && offer.isPublished;
      await ref.read(updateOfferProvider).call(offer, sendNotification: false);
      if (offer.isExpired) {
        ref.invalidate(notificationRequestsProvider);
      }
      if (dispatchAfterSave) {
        await ref
            .read(notificationsRepositoryProvider)
            .deleteRequestsForOffer(offer.id);
        final requestIds = await _createOfferNotifications(
          offer.copyWith(isPublished: true),
          notificationDrafts: notificationDrafts,
        );
        await _dispatchOfferNotifications(
          offerId: offer.id,
          requestIds: requestIds,
        );
        ref.invalidate(notificationRequestsProvider);
      } else if (!offer.isPublished) {
        try {
          await ref
              .read(notificationsRepositoryProvider)
              .deleteRequestsForOffer(offer.id);
          await _createOfferNotifications(offer);
          ref.invalidate(notificationRequestsProvider);
        } catch (error, stackTrace) {
          _log.warning(
            'Notification request sync failed after offer update id=${offer.id}',
            error,
            stackTrace,
          );
        }
      }
    });
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

  Future<void> publish(
    String id,
    bool isPublished, {
    Map<String, OfferNotificationDraft>? notificationDrafts,
  }) async {
    _log.info('Publish offer action started id=$id value=$isPublished');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (isPublished) {
        final offer = await ref.read(offersRepositoryProvider).getOffer(id);
        if (offer != null) {
          await _createOfferNotifications(
            offer.copyWith(isPublished: true),
            notificationDrafts: notificationDrafts,
          );
        }
      }
      await ref.read(offersRepositoryProvider).publishOffer(id, isPublished);
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
    ref.invalidate(notificationRequestsProvider);
    _refreshOffers(id: id);
    _logActionResult('Expire offer action', id: id);
  }

  Future<String?> duplicate(String id) async {
    _log.info('Duplicate offer action started id=$id');
    state = const AsyncLoading();
    String? duplicateId;
    state = await AsyncValue.guard(() async {
      duplicateId = await ref.read(offersRepositoryProvider).duplicateOffer(id);
    });
    _refreshOffers(id: duplicateId ?? id);
    _logActionResult('Duplicate offer action', id: duplicateId ?? id);
    return duplicateId;
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
    ref.invalidate(offersStreamProvider);
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

  Future<void> _dispatchOfferNotifications({
    required String offerId,
    required Map<String, String> requestIds,
  }) async {
    for (final entry in requestIds.entries) {
      try {
        await ref
            .read(offersRepositoryProvider)
            .resendOfferNotification(
              offerId: offerId,
              offerLineId: entry.key,
              requestId: entry.value,
            );
      } catch (error, stackTrace) {
        _log.warning(
          'Offer notification dispatch failed offerId=$offerId line=${entry.key}',
          error,
          stackTrace,
        );
      }
    }
  }

  Future<Map<String, String>> _createOfferNotifications(
    Offer offer, {
    Map<String, OfferNotificationDraft>? notificationDrafts,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user?.hasRole(UserRoles.brandAdmin) == true &&
        offer.brandId.isNotEmpty) {
      final limitMessage = await ref
          .read(subscriptionActionsProvider.notifier)
          .checkPushNotificationLimits(offer.brandId);
      if (limitMessage != null) {
        _log.warning(
          'Notification requests blocked for offer id=${offer.id}: $limitMessage',
        );
        return const {};
      }
    }
    final lines = offer.resolvedLines;
    final requestIds = <String, String>{};
    for (final line in lines) {
      final requestId = await _createLineNotification(
        offer,
        line,
        checkLimits: false,
        notificationDrafts: notificationDrafts,
      );
      if (requestId != null && requestId.isNotEmpty) {
        requestIds[line.id] = requestId;
      }
    }
    if (user?.hasRole(UserRoles.brandAdmin) == true &&
        offer.brandId.isNotEmpty &&
        lines.isNotEmpty) {
      await ref
          .read(subscriptionActionsProvider.notifier)
          .recordPushRequested(offer.brandId);
    }
    return requestIds;
  }

  Future<String?> _createLineNotification(
    Offer offer,
    OfferLine line, {
    bool checkLimits = true,
    Map<String, OfferNotificationDraft>? notificationDrafts,
  }) async {
    try {
      final user = ref.read(currentUserProvider);
      if (checkLimits &&
          user?.hasRole(UserRoles.brandAdmin) == true &&
          offer.brandId.isNotEmpty) {
        final limitMessage = await ref
            .read(subscriptionActionsProvider.notifier)
            .checkPushNotificationLimits(offer.brandId);
        if (limitMessage != null) {
          _log.warning(
            'Notification request blocked for offer id=${offer.id}: $limitMessage',
          );
          return null;
        }
      }
      final draft = OfferNotificationDraftUtils.draftForLine(
        line,
        notificationDrafts,
      );
      final storedOffer = offer.id.isNotEmpty
          ? await ref.read(offersRepositoryProvider).getOffer(offer.id)
          : null;
      final storedSnapshot = OfferNotificationSnapshot.fromMap(
        storedOffer?.notificationSnapshot,
      );
      final enabledSlugs = ref.read(selectableAlertTypeSlugsProvider);
      final alertType =
          draft?.alertType ??
          OfferAlertInputMapper.resolveAlertType(
            offer: offer,
            line: line,
            previousOffer: storedOffer,
            storedSnapshot: storedSnapshot,
            enabledSlugs: enabledSlugs,
          );
      final title = draft?.title.trim().isNotEmpty == true
          ? draft!.title.trim()
          : OfferNotificationContentUtils.suggestedTitle(
              offer,
              line,
              alertType: alertType,
            );
      final body = draft?.body.trim().isNotEmpty == true
          ? draft!.body.trim()
          : OfferNotificationContentUtils.suggestedBody(
              offer,
              alertType: alertType,
            );
      final includeImage =
          draft?.includeImage ??
          OfferNotificationDraftUtils.primaryImageUrlForLine(
            offer,
            line,
          ).isNotEmpty;
      final categoryIds = _notificationCategoryIds(offer: offer, line: line);
      final categoryTopics = await _topicsForCategoryIds(categoryIds);
      final imageUrl = draft?.imageUrl.trim().isNotEmpty == true
          ? draft!.imageUrl.trim()
          : OfferNotificationDraftUtils.primaryImageUrlForLine(offer, line);
      final primaryCategoryId =
          categoryIds.isNotEmpty ? categoryIds.first : line.categoryId;
      final requestId = await ref
          .read(createNotificationRequestProvider)
          .call(
            NotificationRequest(
              id: '',
              title: title.isEmpty ? 'New offer' : title,
              body: body,
              topic: categoryTopics.isEmpty ? '' : categoryTopics.first,
              type: alertType,
              data: {
                'offerId': offer.id,
                'offerLineId': line.id,
                'brandId': offer.brandId,
                'brandName': offer.brandName,
                'categoryId': primaryCategoryId,
                'categoryIds': categoryIds.join(','),
                'categoryTopics': categoryTopics.join(','),
                'cityId': offer.cityId,
                'cityIds': offer.cityIds.join(','),
                'imageUrl': imageUrl,
                'includeImage': includeImage ? 'true' : 'false',
                'type': alertType,
                'alertType': alertType,
              },
              brandId: offer.brandId,
              brandName: offer.brandName,
              offerId: offer.id,
              offerLineId: line.id,
              groupTitle: offer.isGroupOffer ? offer.title : '',
              requestedByUserId: offer.createdByUserId,
              targetCityIds: offer.cityIds.isEmpty
                  ? [offer.cityId]
                  : offer.cityIds,
              targetCategoryIds: categoryIds,
              targetTopics: categoryTopics,
              status: offer.isPublished ? 'approved' : 'pending',
              includeImage: includeImage,
              createdAt: DateTime.now(),
            ),
          );
      if (offer.id.isNotEmpty) {
        await ref
            .read(offersRepositoryProvider)
            .updateOfferNotificationState(
              offerId: offer.id,
              alertType: alertType,
              notificationSnapshot: OfferAlertInputMapper.snapshotFromOffer(
                offer,
              ).toMap(),
            );
      }
      return requestId;
    } catch (error, stackTrace) {
      _log.warning(
        'Notification request skipped for offer id=${offer.id} line=${line.id}',
        error,
        stackTrace,
      );
      return null;
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

List<String> _notificationCategoryIds({
  required Offer offer,
  required OfferLine line,
}) {
  final isWholeBrand =
      line.categoryName.trim().toLowerCase() ==
          kWholeBrandCategoryLabel.toLowerCase() ||
      offer.categoryName.trim().toLowerCase() ==
          kWholeBrandCategoryLabel.toLowerCase();
  if (isWholeBrand) {
    final fromOffer = offer.categoryIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (fromOffer.isNotEmpty) {
      return fromOffer;
    }
  }
  final lineId = line.categoryId.trim();
  if (lineId.isNotEmpty) {
    return [lineId];
  }
  return offer.categoryIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList();
}
