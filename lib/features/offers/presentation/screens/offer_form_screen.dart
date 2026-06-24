import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../auth/domain/entities/user_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/domain/entities/category.dart' as app_category;
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/domain/entities/city.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../../brands/domain/entities/brand_url_source.dart';
import '../../data/local/offer_create_draft_storage.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_line.dart';
import '../providers/offer_providers.dart';
import '../widgets/offer_lines_editor.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../../../core/widgets/screen_layout.dart';

class OfferFormScreen extends ConsumerStatefulWidget {
  const OfferFormScreen({super.key, this.offerId});

  final String? offerId;

  @override
  ConsumerState<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends ConsumerState<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  List<OfferLineDraft> _lineDrafts = [OfferLineDraft.empty()];
  var _hydrated = false;
  var _draftReady = false;
  var _draftRestored = false;
  var _draftLoadAttempted = false;
  Timer? _draftTimer;
  var _isSubmitting = false;
  Offer? _loadedOffer;

  bool get _isEditing => widget.offerId != null;

  bool get _allowsMultipleOffers =>
      !_isEditing || (_loadedOffer?.isGroupOffer ?? false);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _draftReady = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _tryLoadCreateDraft(),
      );
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (!_isEditing) {
      _persistDraft();
    }
    super.dispose();
  }

  void _tryLoadCreateDraft() {
    if (_isEditing || _draftLoadAttempted || !mounted) {
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }
    _draftLoadAttempted = true;
    final isBrandScoped = ref.read(isBrandScopedUserProvider);
    final stored = OfferCreateDraftStorage.load(user.id);
    setState(() {
      if (stored != null && stored.isNotEmpty) {
        _lineDrafts = stored;
        _draftRestored = true;
      } else if (isBrandScoped && user.brandId.isNotEmpty) {
        _lineDrafts = [OfferLineDraft.empty(brandId: user.brandId)];
      }
      _draftReady = true;
    });
  }

  void _onDraftsChanged(List<OfferLineDraft> lines) {
    setState(() => _lineDrafts = lines);
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    if (_isEditing) {
      return;
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 400), _persistDraft);
  }

  void _persistDraft() {
    if (_isEditing || !mounted) {
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }
    OfferCreateDraftStorage.save(user.id, _lineDrafts);
  }

  void _discardDraft() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      OfferCreateDraftStorage.clear(user.id);
    }
    setState(() {
      _lineDrafts = [
        OfferLineDraft.empty(
          brandId: user?.brandId.isNotEmpty == true ? user!.brandId : null,
        ),
      ];
      _draftRestored = false;
    });
  }

  void _clearDraftAfterSave() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      OfferCreateDraftStorage.clear(user.id);
    }
  }

  void _hydrate(Offer offer) {
    if (_hydrated) {
      return;
    }
    _loadedOffer = offer;
    if (_allowsMultipleOffers && offer.isGroupOffer) {
      _lineDrafts = offer.resolvedLines
          .map((line) => OfferLineDraft.fromLine(line, parent: offer))
          .toList();
    } else {
      _lineDrafts = [OfferLineDraft.fromOffer(offer)];
    }
    if (_lineDrafts.isEmpty) {
      _lineDrafts = [OfferLineDraft.empty(brandId: offer.brandId)];
    }
    _hydrated = true;
  }

  Future<void> _pickLineImages(int index) async {
    final images = await _picker.pickMultiImage(
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (images.isEmpty || index < 0 || index >= _lineDrafts.length) {
      return;
    }
    setState(() {
      _lineDrafts[index].pickedImages
        ..clear()
        ..addAll(images);
    });
    _scheduleDraftSave();
  }

  Future<void> _pickLineDate(int index, {required bool start}) async {
    if (index < 0 || index >= _lineDrafts.length) {
      return;
    }
    final draft = _lineDrafts[index];
    final initialDate = start
        ? draft.startDate ?? DateTime.now()
        : draft.endDate ??
              draft.startDate ??
              DateTime.now().add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (start) {
        draft.startDate = picked;
        if (draft.endDate != null && !draft.endDate!.isAfter(picked)) {
          draft.endDate = picked.add(const Duration(days: 1));
        }
      } else {
        draft.endDate = picked;
      }
      draft.syncLifecycleFromEndDate();
    });
    _scheduleDraftSave();
  }

  void _showLimitDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.bar_chart_outlined, size: 40),
        title: const Text('Limit Reached'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/subscriptions/my');
            },
            child: const Text('View Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/subscriptions/request');
            },
            child: const Text('Upgrade Plan'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Wait for Next Month'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit({
    required List<Brand> brands,
    required List<app_category.Category> categories,
    required List<City> cities,
    required bool isBrandScopedUser,
    required bool isManager,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (mounted) setState(() => _isSubmitting = true);
    try {
      await _doSubmit(
        brands: brands,
        categories: categories,
        cities: cities,
        isBrandScopedUser: isBrandScopedUser,
        isManager: isManager,
      );
    } catch (error) {
      if (mounted) {
        await showAppError(context, error, title: 'Could Not Save Offer');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _doSubmit({
    required List<Brand> brands,
    required List<app_category.Category> categories,
    required List<City> cities,
    required bool isBrandScopedUser,
    required bool isManager,
  }) async {
    final draftError = validateOfferDrafts(
      _lineDrafts,
      isBrandScopedUser: isBrandScopedUser,
    );
    if (draftError != null) {
      if (mounted) {
        showAppError(context, null, message: draftError);
      }
      return;
    }

    final user = ref.read(currentUserProvider);
    final enforceSubscriptionLimits =
        user?.hasRole(UserRoles.brandAdmin) ?? false;
    final actions = ref.read(offerActionsProvider.notifier);
    final offersToSave = <Offer>[];

    for (final draft in _lineDrafts) {
      final brandId = isBrandScopedUser ? user?.brandId : draft.brandId;
      if (enforceSubscriptionLimits && !_isEditing && brandId != null) {
        try {
          final limitMessage = await ref
              .read(subscriptionActionsProvider.notifier)
              .checkOfferCreationLimits(brandId);
          if (limitMessage != null) {
            if (mounted) _showLimitDialog(context, limitMessage);
            return;
          }
        } catch (_) {}
      }
      if (enforceSubscriptionLimits && draft.isFeatured && brandId != null) {
        try {
          final featuredMessage = await ref
              .read(subscriptionActionsProvider.notifier)
              .checkFeaturedOfferLimits(brandId);
          if (featuredMessage != null) {
            if (mounted) _showLimitDialog(context, featuredMessage);
            return;
          }
        } catch (_) {}
      }

      final offer = buildOfferFromDraft(
        draft: draft,
        brands: brands,
        categories: categories,
        cities: cities,
        user: user,
        isBrandScopedUser: isBrandScopedUser,
        isManager: isManager,
        baseOffer: _isEditing ? _loadedOffer : null,
        forcedId: _isEditing && !_allowsMultipleOffers ? widget.offerId : null,
      );
      if (offer == null) {
        if (mounted) {
          showAppError(
            context,
            null,
            message: 'Could not build one of the offers. Check all fields.',
          );
        }
        return;
      }
      offersToSave.add(offer);
    }

    final createdIds = <String>[];

    if (_isEditing && _allowsMultipleOffers && _loadedOffer != null) {
      final primaryDraft = _lineDrafts.first;
      final primaryOffer = buildOfferFromDraft(
        draft: primaryDraft,
        brands: brands,
        categories: categories,
        cities: cities,
        user: user,
        isBrandScopedUser: isBrandScopedUser,
        isManager: isManager,
        baseOffer: _loadedOffer,
        forcedId: _loadedOffer!.id,
      );
      if (primaryOffer == null) {
        if (mounted) {
          showAppError(
            context,
            null,
            message: 'Could not build grouped offer.',
          );
        }
        return;
      }
      final offerLines = _lineDrafts.map((draft) {
        final category = categories
            .where((item) => item.id == draft.categoryId)
            .firstOrNull;
        final images = draft.imageUrls
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
        return OfferLine(
          id: draft.id,
          title: draft.title.trim(),
          description: draft.description.trim(),
          categoryId: category?.id ?? '',
          categoryName: category?.name ?? '',
          discountText: draft.discountText.trim(),
          discountType: draft.discountType,
          discountValue: int.tryParse(draft.discountValue.trim()),
          imageUrl: images.isNotEmpty ? images.first : '',
          imageUrls: images,
          linkSources: BrandUrlSourceUtils.withStableIds(draft.linkSources),
        );
      }).toList();
      var groupedOffer = primaryOffer.copyWith(
        offerLines: offerLines,
        discountText: offerLines.length > 1
            ? '${offerLines.length} offers'
            : primaryOffer.discountText,
        categoryIds: offerLines.map((line) => line.categoryId).toList(),
        categoryNames: offerLines.map((line) => line.categoryName).toList(),
      );
      await actions.saveChanges(groupedOffer);
      for (var index = 0; index < _lineDrafts.length; index++) {
        final uploaded = await _uploadDraftImages(
          offerId: groupedOffer.id,
          draft: _lineDrafts[index],
          offer: groupedOffer,
        );
        if (uploaded != null) {
          groupedOffer = uploaded;
          offerLines[index] = offerLines[index].copyWith(
            imageUrls: uploaded.imageUrls,
            imageUrl: uploaded.imageUrl,
          );
          groupedOffer = groupedOffer.copyWith(offerLines: offerLines);
          await actions.saveChanges(groupedOffer);
        }
      }
    } else {
      for (var index = 0; index < offersToSave.length; index++) {
        final draft = _lineDrafts[index];
        var offer = offersToSave[index];
        String? offerId;

        if (_isEditing) {
          await actions.saveChanges(offer);
          offerId = offer.id;
        } else {
          final createdId = await actions.create(offer);
          if (createdId == null) {
            final actionState = ref.read(offerActionsProvider);
            if (mounted) {
              await showAppError(
                context,
                actionState.error,
                title: 'Could Not Save Offer',
              );
            }
            return;
          }
          offerId = createdId;
          offer = offer.copyWith(id: createdId);
          createdIds.add(createdId);
        }

        final uploaded = await _uploadDraftImages(
          offerId: offerId!,
          draft: draft,
          offer: offer,
        );
        if (uploaded != null) {
          await actions.saveChanges(uploaded);
        }

        if (enforceSubscriptionLimits &&
            !_isEditing &&
            offer.brandId.isNotEmpty) {
          try {
            await ref
                .read(subscriptionActionsProvider.notifier)
                .recordOfferCreated(offer.brandId);
            if (draft.isFeatured) {
              await ref
                  .read(subscriptionActionsProvider.notifier)
                  .recordFeaturedUsed(offer.brandId);
            }
          } catch (_) {}
        }
      }
    }

    final actionState = ref.read(offerActionsProvider);
    if (actionState.hasError) {
      if (mounted) {
        await showAppError(
          context,
          actionState.error,
          title: 'Could Not Save Offer',
        );
      }
      return;
    }

    if (mounted) {
      if (!_isEditing) {
        _clearDraftAfterSave();
      }
      if (_isEditing) {
        context.go('/offers/${widget.offerId}');
      } else if (createdIds.length > 1) {
        context.go('/offers');
      } else if (createdIds.isNotEmpty) {
        context.go('/offers/${createdIds.first}');
      }
    }
  }

  Future<Offer?> _uploadDraftImages({
    required String offerId,
    required OfferLineDraft draft,
    required Offer offer,
  }) async {
    if (draft.pickedImages.isEmpty) {
      return null;
    }
    final imageRepo = ref.read(offerImageRepositoryProvider);
    final nextUrls = [...offer.imageUrls];
    for (final image in draft.pickedImages) {
      final bytes = await image.readAsBytes();
      nextUrls.add(
        await imageRepo.uploadOfferImage(
          offerId: offerId,
          fileName: image.name,
          bytes: bytes,
          contentType: image.mimeType ?? _contentTypeFor(image.name),
        ),
      );
    }
    return offer.copyWith(
      imageUrls: nextUrls,
      imageUrl: nextUrls.isNotEmpty ? nextUrls.first : offer.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final offerAsync = _isEditing
        ? ref.watch(offerProvider(widget.offerId!))
        : const AsyncValue<Offer?>.data(null);
    final brands = ref.watch(brandsProvider);
    final categories = ref.watch(visibleCategoriesProvider);
    final cities = ref.watch(visibleCitiesProvider);
    final isBrandScopedUser = ref.watch(isBrandScopedUserProvider);
    final isManager = ref.watch(isManagerProvider);
    final user = ref.watch(currentUserProvider);
    final actionState = ref.watch(offerActionsProvider);
    final isSaving = _isSubmitting || actionState.isLoading;

    return offerAsync.when(
      data: (offer) {
        if (_isEditing && offer == null) {
          return const AppErrorView(message: 'Offer not found.');
        }
        if (offer != null) {
          _hydrate(offer);
        }
        final lockedOffer = offer != null && offer.isExpired;

        final brandItems = brands.value ?? const <Brand>[];
        final categoryItems = _uniqueCategories(
          categories.value ?? const <app_category.Category>[],
        );
        final cityItems = cities.value ?? const <City>[];
        if (!_isEditing && user != null && !_draftLoadAttempted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryLoadCreateDraft();
          });
        }
        final loadingLookups =
            brands.isLoading || categories.isLoading || cities.isLoading;

        if (!_isEditing && !_draftReady) {
          return const AppLoader();
        }

        if (lockedOffer) {
          return SingleChildScrollView(
            padding: screenPadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 42,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'This offer is expired and cannot be edited.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => context.go('/offers/${offer.id}'),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('View offer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return AppLoadingOverlay(
          isLoading: isSaving,
          child: SingleChildScrollView(
            padding: screenPadding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_draftRestored && !_isEditing)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.restore_page_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Draft restored',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your previous offer draft was recovered. Newly picked images must be re-selected after leaving the page.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _discardDraft,
                                  child: const Text('Discard'),
                                ),
                              ],
                            ),
                          ),
                        if (loadingLookups)
                          const SizedBox(height: 96, child: AppLoader(size: 72))
                        else
                          OfferLinesEditor(
                            lines: _lineDrafts,
                            brands: brandItems,
                            cities: cityItems,
                            categories: categoryItems,
                            allowMultiple:
                                !_isEditing ||
                                (_loadedOffer?.isGroupOffer ?? false),
                            isBrandScopedUser: isBrandScopedUser,
                            scopedBrandId: user?.brandId,
                            isManager: isManager,
                            lockedOffer: false,
                            isEditing: _isEditing,
                            onPickImages: _pickLineImages,
                            onPickDate: _pickLineDate,
                            onChanged: _onDraftsChanged,
                          ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/offers'),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: isSaving || loadingLookups
                                  ? null
                                  : () => _submit(
                                      brands: brandItems,
                                      categories: categoryItems,
                                      cities: cityItems,
                                      isBrandScopedUser: isBrandScopedUser,
                                      isManager: isManager,
                                    ),
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                !_isEditing && _lineDrafts.length > 1
                                    ? 'Save offers'
                                    : 'Save offer',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const AppLoader(),
      error: (error, _) => AppErrorView(error: error),
    );
  }
}

String _contentTypeFor(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

List<app_category.Category> _uniqueCategories(
  List<app_category.Category> categories,
) {
  final seen = <String>{};
  final unique = <app_category.Category>[];
  for (final category in categories) {
    if (seen.add(category.id)) {
      unique.add(category);
    }
  }
  return unique;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
