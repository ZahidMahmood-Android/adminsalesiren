import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_dialog.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../../categories/domain/entities/category.dart' as app_category;
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../cities/domain/entities/city.dart';
import '../../../cities/presentation/providers/city_providers.dart';
import '../../domain/entities/offer.dart';
import '../providers/offer_providers.dart';
import '../widgets/offer_form_controls.dart';
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountTextController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  final _onlineUrlController = TextEditingController();

  String? _brandId;
  String? _categoryId;
  final _selectedCategoryIds = <String>{};
  final _selectedCityIds = <String>{};
  String _discountType = 'percentage';
  String _status = 'pending_review';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublished = false;
  bool _isVerified = false;
  bool _isFeatured = false;
  String _imageUrl = '';
  XFile? _pickedImage;
  var _hydrated = false;
  var _isSubmitting = false;
  Offer? _loadedOffer;

  bool get _isEditing => widget.offerId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountTextController.dispose();
    _discountValueController.dispose();
    _sourceUrlController.dispose();
    _onlineUrlController.dispose();
    super.dispose();
  }

  void _hydrate(Offer offer) {
    if (_hydrated) {
      return;
    }
    _loadedOffer = offer;
    _titleController.text = offer.title;
    _descriptionController.text = offer.description;
    _discountTextController.text = offer.discountText;
    _discountValueController.text = offer.discountValue?.toString() ?? '';
    _sourceUrlController.text = offer.sourceUrl;
    _onlineUrlController.text = offer.onlineUrl;
    _brandId = offer.brandId;
    _categoryId = offer.categoryId;
    _selectedCategoryIds
      ..clear()
      ..addAll(
        offer.categoryIds.isEmpty ? [offer.categoryId] : offer.categoryIds,
      );
    _selectedCityIds
      ..clear()
      ..addAll(offer.cityIds.isEmpty ? [offer.cityId] : offer.cityIds);
    _discountType = offer.discountType;
    _status = offer.isPublished ? 'published' : offer.status;
    if (_status == 'pending') {
      _status = 'pending_review';
    }
    _startDate = offer.startDate;
    _endDate = offer.endDate;
    _isPublished = offer.isPublished;
    _isVerified = offer.isVerified;
    _isFeatured = offer.isFeatured;
    _imageUrl = offer.imageUrl;
    _hydrated = true;
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final initialDate = start
        ? _startDate ?? DateTime.now()
        : _endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 7));
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
        _startDate = picked;
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = picked.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
    });
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
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (mounted) setState(() => _isSubmitting = true);
    try {
      await _doSubmit(brands: brands, categories: categories, cities: cities);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _doSubmit({
    required List<Brand> brands,
    required List<app_category.Category> categories,
    required List<City> cities,
  }) async {
    if (_startDate == null || _endDate == null) {
      if (mounted) {
        showAppError(
          context,
          null,
          message: 'Please select start and end dates.',
        );
      }
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      if (mounted) {
        showAppError(
          context,
          null,
          message: 'End date must be after start date.',
        );
      }
      return;
    }
    if (_selectedCityIds.isEmpty) {
      if (mounted) {
        showAppError(
          context,
          null,
          message: 'Please select at least one city.',
        );
      }
      return;
    }
    if (_selectedCategoryIds.isEmpty && _categoryId == null) {
      if (mounted) {
        showAppError(
          context,
          null,
          message: 'Please select at least one category.',
        );
      }
      return;
    }

    final brand = brands.firstWhere((item) => item.id == _brandId);
    final selectedCategories = categories
        .where(
          (item) =>
              _selectedCategoryIds.contains(item.id) || item.id == _categoryId,
        )
        .toList();
    if (selectedCategories.isEmpty) {
      if (mounted) {
        showAppError(
          context,
          null,
          message:
              'The selected category is not available. Please choose another.',
        );
      }
      return;
    }
    final category = selectedCategories.first;
    final selectedCities = cities
        .where((item) => _selectedCityIds.contains(item.id))
        .toList();
    if (selectedCities.isEmpty) {
      if (mounted) {
        showAppError(
          context,
          null,
          message: 'The selected city is not available. Please choose another.',
        );
      }
      return;
    }
    final city = selectedCities.first;
    final user = ref.read(currentUserProvider);
    final isBrandAdminUser = user?.role == 'brand_admin';
    final now = DateTime.now();
    final discountValue = num.tryParse(_discountValueController.text.trim());

    if (isBrandAdminUser && !_isEditing) {
      try {
        final limitMessage = await ref
            .read(subscriptionActionsProvider.notifier)
            .checkOfferCreationLimits(brand.id);
        if (limitMessage != null) {
          if (mounted) _showLimitDialog(context, limitMessage);
          return;
        }
      } catch (_) {
        // If quota check fails (e.g. usage record not yet created), allow save to proceed.
      }
    }
    if (isBrandAdminUser && _isFeatured) {
      try {
        final featuredMessage = await ref
            .read(subscriptionActionsProvider.notifier)
            .checkFeaturedOfferLimits(brand.id);
        if (featuredMessage != null) {
          if (mounted) _showLimitDialog(context, featuredMessage);
          return;
        }
      } catch (_) {
        // If featured-offer quota check fails, allow save to proceed.
      }
    }

    final baseOffer = _isEditing && _loadedOffer != null
        ? _loadedOffer!
        : Offer(
            id: widget.offerId ?? '',
            title: '',
            description: '',
            brandId: '',
            brandName: '',
            categoryId: '',
            categoryName: '',
            cityId: '',
            cityName: '',
            discountText: '',
            discountType: _discountType,
            discountValue: null,
            imageUrl: '',
            sourceUrl: '',
            onlineUrl: '',
            startDate: _startDate!,
            endDate: _endDate!,
            isVerified: false,
            isPublished: false,
            isFeatured: false,
            aiConfidence: null,
            createdBy: user?.id ?? '',
            createdAt: now,
            updatedAt: now,
          );
    final selectedStatus = isBrandAdminUser ? _status : baseOffer.status;
    final selectedPublished = isBrandAdminUser
        ? selectedStatus == 'published'
        : _isPublished;
    var offer = baseOffer.copyWith(
      id: widget.offerId ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      brandId: brand.id,
      brandName: brand.name,
      categoryId: category.id,
      categoryName: category.name,
      categoryIds: selectedCategories.map((item) => item.id).toList(),
      categoryNames: selectedCategories.map((item) => item.name).toList(),
      cityId: city.id,
      cityName: city.name,
      cityIds: selectedCities.map((item) => item.id).toList(),
      cityNames: selectedCities.map((item) => item.name).toList(),
      discountText: _discountTextController.text.trim(),
      discountType: _discountType,
      discountValue: discountValue,
      imageUrl: _imageUrl,
      sourceUrl: _sourceUrlController.text.trim(),
      onlineUrl: _onlineUrlController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      isVerified: _isVerified,
      isPublished: selectedPublished,
      isFeatured: _isFeatured,
      status: isBrandAdminUser ? selectedStatus : baseOffer.status,
      approvalStatus: isBrandAdminUser
          ? selectedStatus == 'published'
                ? 'approved'
                : 'pending'
          : baseOffer.approvalStatus,
      approvedBy: isBrandAdminUser
          ? selectedStatus == 'published'
                ? user?.id ?? ''
                : ''
          : baseOffer.approvedBy,
      approvedAt: isBrandAdminUser
          ? selectedStatus == 'published'
                ? now
                : null
          : baseOffer.approvedAt,
      updatedAt: now,
    );

    final actions = ref.read(offerActionsProvider.notifier);
    var offerId = widget.offerId;
    if (_isEditing) {
      await actions.saveChanges(offer);
    } else {
      offerId = await actions.create(offer);
    }

    final actionState = ref.read(offerActionsProvider);
    if (actionState.hasError || offerId == null) {
      if (mounted) {
        await showAppError(
          context,
          actionState.error,
          title: 'Could Not Save Offer',
        );
      }
      return;
    }
    if (isBrandAdminUser && !_isEditing) {
      try {
        await ref
            .read(subscriptionActionsProvider.notifier)
            .recordOfferCreated(brand.id);
        if (_isFeatured) {
          await ref
              .read(subscriptionActionsProvider.notifier)
              .recordFeaturedUsed(brand.id);
        }
      } catch (_) {
        // Usage tracking is best-effort; don't block navigation after a successful save.
      }
    }
    offer = offer.copyWith(
      id: offerId,
      createdByUserId: user?.id ?? '',
      createdByRole: user?.role ?? 'super_admin',
      status: user?.role == 'brand_admin' ? selectedStatus : offer.status,
      approvalStatus: user?.role == 'brand_admin'
          ? selectedStatus == 'published'
                ? 'approved'
                : 'pending'
          : offer.approvalStatus,
      isPublished: user?.role == 'brand_admin'
          ? selectedPublished
          : offer.isPublished,
      approvedBy: user?.role == 'brand_admin'
          ? selectedStatus == 'published'
                ? user?.id ?? ''
                : ''
          : offer.approvedBy,
      approvedAt: user?.role == 'brand_admin'
          ? selectedStatus == 'published'
                ? now
                : null
          : offer.approvedAt,
    );

    if (_pickedImage != null) {
      final bytes = await _pickedImage!.readAsBytes();
      final imageUrl = await ref
          .read(offerImageRepositoryProvider)
          .uploadOfferImage(
            offerId: offerId,
            fileName: _pickedImage!.name,
            bytes: bytes,
            contentType:
                _pickedImage!.mimeType ?? _contentTypeFor(_pickedImage!.name),
          );
      offer = offer.copyWith(imageUrl: imageUrl);
      await actions.saveChanges(offer);
    }

    if (mounted) {
      context.go('/offers/$offerId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerAsync = _isEditing
        ? ref.watch(offerProvider(widget.offerId!))
        : const AsyncValue<Offer?>.data(null);
    final brands = ref.watch(brandsProvider);
    final categories = ref.watch(visibleCategoriesProvider);
    final cities = ref.watch(visibleCitiesProvider);
    final actionState = ref.watch(offerActionsProvider);
    final isBrandAdmin = ref.watch(isBrandAdminProvider);
    final user = ref.watch(currentUserProvider);

    return offerAsync.when(
      data: (offer) {
        if (_isEditing && offer == null) {
          return const AppErrorView(message: 'Offer not found.');
        }
        if (offer != null) {
          _hydrate(offer);
        }
        final publishedBrandOffer =
            isBrandAdmin && offer != null && offer.isPublished;

        final brandItems = brands.value ?? const <Brand>[];
        final categoryItems =
            categories.value ?? const <app_category.Category>[];
        final cityItems = cities.value ?? const <City>[];
        if (!_hydrated && isBrandAdmin && (user?.brandId.isNotEmpty ?? false)) {
          _brandId = user!.brandId;
        }
        final selectedBrand = _brandById(brandItems, _brandId);
        final loadingLookups =
            brands.isLoading || categories.isLoading || cities.isLoading;
        if (publishedBrandOffer) {
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
                        'This offer is already published and cannot be edited.',
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

        return SingleChildScrollView(
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
                      Text(
                        _isEditing ? 'Edit offer' : 'New offer',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 22),
                      DropdownBox(
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'pending_review',
                              child: Text('Pending Review'),
                            ),
                            DropdownMenuItem(
                              value: 'published',
                              child: Text('Published'),
                            ),
                          ],
                          onChanged: publishedBrandOffer
                              ? null
                              : (value) => setState(
                                  () => _status = value ?? 'pending_review',
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (loadingLookups)
                        const LinearProgressIndicator()
                      else
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            if (isBrandAdmin)
                              DropdownBox(
                                child: TextFormField(
                                  initialValue: selectedBrand?.name ?? '',
                                  enabled: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Brand',
                                    prefixIcon: Icon(Icons.storefront_outlined),
                                  ),
                                  validator: (_) =>
                                      (_brandId == null || _brandId!.isEmpty)
                                      ? 'Brand required'
                                      : null,
                                ),
                              )
                            else
                              DropdownBox(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _brandId,
                                  decoration: const InputDecoration(
                                    labelText: 'Brand',
                                  ),
                                  items: brandItems
                                      .map(
                                        (brand) => DropdownMenuItem(
                                          value: brand.id,
                                          child: Text(brand.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _brandId = value),
                                  validator: (value) =>
                                      value == null ? 'Brand required' : null,
                                ),
                              ),
                            DropdownBox(
                              child: isBrandAdmin
                                  ? InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Categories',
                                        prefixIcon: Icon(
                                          Icons.category_outlined,
                                        ),
                                      ),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: categoryItems.map((category) {
                                          final selected = _selectedCategoryIds
                                              .contains(category.id);
                                          return FilterChip(
                                            label: Text(category.name),
                                            selected: selected,
                                            onSelected: (value) {
                                              setState(() {
                                                if (value) {
                                                  _selectedCategoryIds.add(
                                                    category.id,
                                                  );
                                                } else {
                                                  _selectedCategoryIds.remove(
                                                    category.id,
                                                  );
                                                }
                                                _categoryId =
                                                    _selectedCategoryIds.isEmpty
                                                    ? null
                                                    : _selectedCategoryIds
                                                          .first;
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      initialValue: _categoryId,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                      ),
                                      items: categoryItems
                                          .map(
                                            (category) => DropdownMenuItem(
                                              value: category.id,
                                              child: Text(category.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) =>
                                          setState(() => _categoryId = value),
                                      validator: (value) => value == null
                                          ? 'Category required'
                                          : null,
                                    ),
                            ),
                            SizedBox(
                              width: 360,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Cities',
                                  prefixIcon: Icon(
                                    Icons.location_city_outlined,
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: cityItems.map((city) {
                                    final selected = _selectedCityIds.contains(
                                      city.id,
                                    );
                                    return FilterChip(
                                      label: Text(city.name),
                                      selected: selected,
                                      onSelected: (value) {
                                        setState(() {
                                          if (value) {
                                            _selectedCityIds.add(city.id);
                                          } else {
                                            _selectedCityIds.remove(city.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          DropdownBox(
                            child: TextFormField(
                              controller: _discountTextController,
                              decoration: const InputDecoration(
                                labelText: 'Discount text',
                                prefixIcon: Icon(Icons.percent),
                              ),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Discount text is required'
                                  : null,
                            ),
                          ),
                          DropdownBox(
                            child: DropdownButtonFormField<String>(
                              initialValue: _discountType,
                              decoration: const InputDecoration(
                                labelText: 'Discount type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'percentage',
                                  child: Text('Percentage'),
                                ),
                                DropdownMenuItem(
                                  value: 'flat',
                                  child: Text('Flat amount'),
                                ),
                                DropdownMenuItem(
                                  value: 'bundle',
                                  child: Text('Bundle'),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _discountType = value ?? 'percentage',
                              ),
                            ),
                          ),
                          DropdownBox(
                            child: TextFormField(
                              controller: _discountValueController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Discount value',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          DateButton(
                            label: 'Start date',
                            value: _startDate?.shortDate,
                            onPressed: () => _pickDate(start: true),
                          ),
                          DateButton(
                            label: 'End date',
                            value: _endDate?.shortDate,
                            onPressed: () => _pickDate(start: false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          DropdownBox(
                            child: TextFormField(
                              controller: _sourceUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Source URL',
                                prefixIcon: Icon(Icons.link),
                              ),
                            ),
                          ),
                          DropdownBox(
                            child: TextFormField(
                              controller: _onlineUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Online URL',
                                prefixIcon: Icon(Icons.shopping_bag_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ImagePickerPanel(
                        imageUrl: _imageUrl,
                        pickedImageName: _pickedImage?.name,
                        onPick: _pickImage,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Verified'),
                            selected: _isVerified,
                            onSelected: (value) =>
                                setState(() => _isVerified = value),
                          ),
                          FilterChip(
                            label: const Text('Featured'),
                            selected: _isFeatured,
                            onSelected: (value) =>
                                setState(() => _isFeatured = value),
                          ),
                        ],
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
                            onPressed:
                                _isSubmitting ||
                                    actionState.isLoading ||
                                    loadingLookups
                                ? null
                                : () => _submit(
                                    brands: brandItems,
                                    categories: categoryItems,
                                    cities: cityItems,
                                  ),
                            icon: _isSubmitting || actionState.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save offer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const AppLoadingView(label: 'Loading offer'),
      error: (error, _) => AppErrorView(message: error.toString()),
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

Brand? _brandById(List<Brand> brands, String? id) {
  for (final brand in brands) {
    if (brand.id == id) {
      return brand;
    }
  }
  return null;
}
