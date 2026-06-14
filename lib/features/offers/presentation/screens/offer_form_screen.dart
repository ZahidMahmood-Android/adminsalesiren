import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/widgets/app_card.dart';
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
  String? _cityId;
  String _discountType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublished = false;
  bool _isVerified = false;
  bool _isFeatured = false;
  String _imageUrl = '';
  XFile? _pickedImage;
  var _hydrated = false;

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
    _titleController.text = offer.title;
    _descriptionController.text = offer.description;
    _discountTextController.text = offer.discountText;
    _discountValueController.text = offer.discountValue?.toString() ?? '';
    _sourceUrlController.text = offer.sourceUrl;
    _onlineUrlController.text = offer.onlineUrl;
    _brandId = offer.brandId;
    _categoryId = offer.categoryId;
    _cityId = offer.cityId;
    _discountType = offer.discountType;
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

  Future<void> _submit({
    required List<Brand> brands,
    required List<app_category.Category> categories,
    required List<City> cities,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select start and end dates.')),
      );
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }

    final brand = brands.firstWhere((item) => item.id == _brandId);
    final category = categories.firstWhere((item) => item.id == _categoryId);
    final city = cities.firstWhere((item) => item.id == _cityId);
    final user = ref.read(currentUserProvider);
    final now = DateTime.now();
    final discountValue = num.tryParse(_discountValueController.text.trim());

    var offer = Offer(
      id: widget.offerId ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      brandId: brand.id,
      brandName: brand.name,
      categoryId: category.id,
      categoryName: category.name,
      cityId: city.id,
      cityName: city.name,
      discountText: _discountTextController.text.trim(),
      discountType: _discountType,
      discountValue: discountValue,
      imageUrl: _imageUrl,
      sourceUrl: _sourceUrlController.text.trim(),
      onlineUrl: _onlineUrlController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      isVerified: _isVerified,
      isPublished: _isPublished,
      isFeatured: _isFeatured,
      aiConfidence: null,
      createdBy: user?.id ?? '',
      createdAt: now,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessages.friendly(actionState.error))),
        );
      }
      return;
    }

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
      offer = offer.copyWith(id: offerId, imageUrl: imageUrl);
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
    final brands = ref.watch(activeBrandsProvider);
    final categories = ref.watch(categoriesProvider);
    final cities = ref.watch(citiesProvider);
    final actionState = ref.watch(offerActionsProvider);

    return offerAsync.when(
      data: (offer) {
        if (_isEditing && offer == null) {
          return const AppErrorView(message: 'Offer not found.');
        }
        if (offer != null) {
          _hydrate(offer);
        }

        final brandItems = brands.value ?? const <Brand>[];
        final categoryItems =
            categories.value ?? const <app_category.Category>[];
        final cityItems = cities.value ?? const <City>[];
        final loadingLookups =
            brands.isLoading || categories.isLoading || cities.isLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                              child: DropdownButtonFormField<String>(
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
                                validator: (value) =>
                                    value == null ? 'Category required' : null,
                              ),
                            ),
                            DropdownBox(
                              child: DropdownButtonFormField<String>(
                                initialValue: _cityId,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                ),
                                items: cityItems
                                    .map(
                                      (city) => DropdownMenuItem(
                                        value: city.id,
                                        child: Text(city.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _cityId = value),
                                validator: (value) =>
                                    value == null ? 'City required' : null,
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
                            label: const Text('Published'),
                            selected: _isPublished,
                            onSelected: (value) =>
                                setState(() => _isPublished = value),
                          ),
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
                            onPressed: actionState.isLoading || loadingLookups
                                ? null
                                : () => _submit(
                                    brands: brandItems,
                                    categories: categoryItems,
                                    cities: cityItems,
                                  ),
                            icon: actionState.isLoading
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
