import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/multi_select_field.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/domain/entities/brand_url_source.dart';
import '../../../brands/presentation/widgets/url_sources_field.dart';
import '../../../categories/domain/entities/category.dart' as app_category;
import '../../../cities/domain/entities/city.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_image_upload_task.dart';
import '../../domain/entities/offer_line.dart';
import 'offer_form_controls.dart';

class OfferLineDraft {
  OfferLineDraft({
    required this.id,
    this.brandId,
    Set<String>? selectedCityIds,
    this.title = '',
    this.description = '',
    this.categoryId,
    this.discountText = '',
    this.discountType = 'percentage',
    this.discountValue = '',
    this.status = 'pending_review',
    this.lifecycleStatus = 'active',
    DateTime? startDate,
    DateTime? endDate,
    this.isVerified = false,
    this.isFeatured = false,
    this.imageSliderAutoPlay = true,
    this.imageDisplayMode = 'carousel',
    List<String>? imageUrls,
    List<XFile>? pickedImages,
    List<OfferImageUploadTask>? imageUploads,
    List<BrandUrlSource>? linkSources,
  }) : selectedCityIds = selectedCityIds ?? <String>{},
       startDate = startDate ?? _defaultStartDate(),
       endDate = endDate ?? _defaultEndDate(),
       imageUrls = imageUrls ?? <String>[],
       pickedImages = pickedImages ?? <XFile>[],
       imageUploads = imageUploads ?? <OfferImageUploadTask>[],
       linkSources =
           linkSources ??
           BrandUrlSourceUtils.copyList(BrandUrlSource.defaultTemplates());

  final String id;
  String? brandId;
  Set<String> selectedCityIds;
  String title;
  String description;
  String? categoryId;
  String discountText;
  String discountType;
  String discountValue;
  String status;
  String lifecycleStatus;
  DateTime? startDate;
  DateTime? endDate;
  bool isVerified;
  bool isFeatured;
  bool imageSliderAutoPlay;
  String imageDisplayMode;
  List<String> imageUrls;
  List<XFile> pickedImages;
  List<OfferImageUploadTask> imageUploads;
  List<BrandUrlSource> linkSources;

  static DateTime _defaultStartDate() {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  static DateTime _defaultEndDate() {
    return _defaultStartDate().add(const Duration(days: 14));
  }

  factory OfferLineDraft.empty({
    String? brandId,
    Set<String>? selectedCityIds,
    List<BrandUrlSource>? linkSources,
  }) {
    return OfferLineDraft(
      id: const Uuid().v4(),
      brandId: brandId,
      selectedCityIds: selectedCityIds,
      linkSources: linkSources == null
          ? null
          : BrandUrlSourceUtils.copyList(linkSources),
    );
  }

  factory OfferLineDraft.fromOffer(Offer offer) {
    final sources = offer.linkSources.isNotEmpty
        ? offer.linkSources
        : BrandUrlSourceUtils.fromLegacyFields(
            websiteUrl: offer.onlineUrl,
            instagramUrl: offer.sourceUrl,
          );
    final images = offer.imageUrls.isNotEmpty
        ? offer.imageUrls
        : [offer.imageUrl].where((url) => url.isNotEmpty).toList();
    var status = offer.isPublished ? 'published' : offer.status;
    if (status == 'pending') {
      status = 'pending_review';
    }
    if (status != 'pending_review' && status != 'published') {
      status = 'pending_review';
    }
    return OfferLineDraft(
      id: offer.id,
      brandId: offer.brandId,
      selectedCityIds: offer.cityIds.isEmpty
          ? {if (offer.cityId.isNotEmpty) offer.cityId}
          : offer.cityIds.toSet(),
      title: offer.title,
      description: offer.description,
      categoryId: offer.categoryId.isEmpty ? null : offer.categoryId,
      discountText: offer.discountText,
      discountType: offer.discountType,
      discountValue: offer.discountValue?.toString() ?? '',
      status: status,
      lifecycleStatus: lifecycleForDate(offer.endDate),
      startDate: offer.startDate,
      endDate: offer.endDate,
      isVerified: offer.isVerified,
      isFeatured: offer.isFeatured,
      imageSliderAutoPlay: offer.imageSliderAutoPlay,
      imageDisplayMode: offer.imageDisplayMode == 'grid' ? 'grid' : 'carousel',
      imageUrls: [...images],
      linkSources: BrandUrlSourceUtils.copyList(sources),
    );
  }

  factory OfferLineDraft.fromLine(OfferLine line, {required Offer parent}) {
    final lineImages = line.resolvedImageUrls();
    final parentImages = parent.imageUrls.isNotEmpty
        ? parent.imageUrls
        : [parent.imageUrl].where((url) => url.isNotEmpty).toList();
    final parentSources = parent.linkSources.isNotEmpty
        ? parent.linkSources
        : BrandUrlSourceUtils.fromLegacyFields(
            websiteUrl: parent.onlineUrl,
            instagramUrl: parent.sourceUrl,
          );
    var status = parent.isPublished ? 'published' : parent.status;
    if (status == 'pending') {
      status = 'pending_review';
    }
    if (status != 'pending_review' && status != 'published') {
      status = 'pending_review';
    }
    return OfferLineDraft(
      id: line.id,
      brandId: parent.brandId,
      selectedCityIds: parent.cityIds.isEmpty
          ? {if (parent.cityId.isNotEmpty) parent.cityId}
          : parent.cityIds.toSet(),
      title: line.title.isNotEmpty ? line.title : parent.title,
      description: line.description.isNotEmpty
          ? line.description
          : parent.description,
      categoryId: line.categoryId.isEmpty ? null : line.categoryId,
      discountText: line.discountText,
      discountType: line.discountType,
      discountValue: line.discountValue?.toString() ?? '',
      status: status,
      lifecycleStatus: lifecycleForDate(parent.endDate),
      startDate: parent.startDate,
      endDate: parent.endDate,
      isVerified: parent.isVerified,
      isFeatured: parent.isFeatured,
      imageSliderAutoPlay: parent.imageSliderAutoPlay,
      imageDisplayMode: parent.imageDisplayMode == 'grid' ? 'grid' : 'carousel',
      imageUrls: lineImages.isNotEmpty ? [...lineImages] : [...parentImages],
      linkSources: BrandUrlSourceUtils.copyList(
        line.linkSources.isNotEmpty ? line.linkSources : parentSources,
      ),
    );
  }

  bool get hasImages => imageUrls.isNotEmpty;

  bool get isUploadingImages => imageUploads.any((task) => task.isActive);

  bool get hasFailedUploads =>
      imageUploads.any((task) => task.status == OfferImageUploadStatus.failed);

  bool get imagesReady => hasImages && !isUploadingImages && !hasFailedUploads;

  bool get isEffectivelyEmpty =>
      title.trim().isEmpty &&
      description.trim().isEmpty &&
      (categoryId == null || categoryId!.isEmpty) &&
      discountText.trim().isEmpty &&
      imageUrls.isEmpty &&
      imageUploads.isEmpty &&
      pickedImages.isEmpty &&
      linkSources.every((source) => !source.hasUrl) &&
      (brandId == null || brandId!.isEmpty) &&
      selectedCityIds.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'selectedCityIds': selectedCityIds.toList(),
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'discountText': discountText,
      'discountType': discountType,
      'discountValue': discountValue,
      'status': status,
      'lifecycleStatus': lifecycleStatus,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'imageSliderAutoPlay': imageSliderAutoPlay,
      'imageDisplayMode': imageDisplayMode,
      'imageUrls': imageUrls,
      'linkSources': linkSources.map((source) => source.toMap()).toList(),
    };
  }

  factory OfferLineDraft.fromJson(Map<String, dynamic> json) {
    final cityIds = json['selectedCityIds'];
    return OfferLineDraft(
      id: json['id'] as String? ?? const Uuid().v4(),
      brandId: json['brandId'] as String?,
      selectedCityIds: cityIds is List
          ? cityIds.map((item) => item.toString()).toSet()
          : null,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      discountText: json['discountText'] as String? ?? '',
      discountType: json['discountType'] as String? ?? 'percentage',
      discountValue: json['discountValue'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      lifecycleStatus: json['lifecycleStatus'] as String? ?? 'active',
      startDate: _readDate(json['startDate']),
      endDate: _readDate(json['endDate']),
      isVerified: json['isVerified'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      imageSliderAutoPlay: json['imageSliderAutoPlay'] as bool? ?? true,
      imageDisplayMode: json['imageDisplayMode'] as String? ?? 'carousel',
      imageUrls: _readStringList(json['imageUrls']),
      linkSources: BrandUrlSourceUtils.readList(json['linkSources']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void applyLifecycleStatus(String value) {
    lifecycleStatus = value;
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    if (value == 'expired') {
      startDate = date.subtract(const Duration(days: 7));
      endDate = date.subtract(const Duration(days: 1));
    } else if (value == 'ending_soon') {
      startDate = date;
      endDate = date.add(const Duration(days: 2));
    } else {
      startDate = date;
      endDate = date.add(const Duration(days: 14));
    }
  }

  void syncLifecycleFromEndDate() {
    lifecycleStatus = lifecycleForDate(endDate);
  }
}

String lifecycleForDate(DateTime? endDate) {
  if (endDate == null) {
    return 'active';
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  if (end.isBefore(today)) {
    return 'expired';
  }
  if (!end.isAfter(today.add(const Duration(days: 3)))) {
    return 'ending_soon';
  }
  return 'active';
}

class OfferLinesEditor extends StatelessWidget {
  const OfferLinesEditor({
    required this.lines,
    required this.brands,
    required this.cities,
    required this.categories,
    required this.onChanged,
    required this.onPickImages,
    required this.onPickDate,
    required this.onRetryUpload,
    required this.onRemoveUpload,
    this.allowMultiple = true,
    this.isBrandScopedUser = false,
    this.scopedBrandId,
    this.isManager = false,
    this.lockedOffer = false,
    this.isEditing = false,
    super.key,
  });

  final List<OfferLineDraft> lines;
  final List<Brand> brands;
  final List<City> cities;
  final List<app_category.Category> categories;
  final ValueChanged<List<OfferLineDraft>> onChanged;
  final Future<void> Function(int index) onPickImages;
  final Future<void> Function(int index, {required bool start}) onPickDate;
  final void Function(int index, String taskId) onRetryUpload;
  final void Function(int index, String taskId) onRemoveUpload;
  final bool allowMultiple;
  final bool isBrandScopedUser;
  final String? scopedBrandId;
  final bool isManager;
  final bool lockedOffer;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OfferEditorHeader(
          isEditing: isEditing,
          allowMultiple: allowMultiple,
          offerCount: lines.length,
          colorScheme: colorScheme,
          theme: theme,
        ),
        if (allowMultiple && !lockedOffer && !isEditing) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                onChanged([
                  ...lines,
                  OfferLineDraft.empty(
                    brandId: isBrandScopedUser ? scopedBrandId : null,
                  ),
                ]);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add another offer'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        ...lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OfferLineCard(
              index: index,
              line: line,
              brands: brands,
              cities: cities,
              categories: categories,
              allowMultiple: allowMultiple,
              canRemove:
                  allowMultiple &&
                  lines.length > 1 &&
                  !lockedOffer &&
                  !isEditing,
              isBrandScopedUser: isBrandScopedUser,
              scopedBrandId: scopedBrandId,
              isManager: isManager,
              lockedOffer: lockedOffer,
              onChanged: () => onChanged([...lines]),
              onRemove: () {
                final next = [...lines]..removeAt(index);
                onChanged(
                  next.isEmpty
                      ? [
                          OfferLineDraft.empty(
                            brandId: isBrandScopedUser ? scopedBrandId : null,
                          ),
                        ]
                      : next,
                );
              },
              onPickImages: () => onPickImages(index),
              onPickDate: (start) => onPickDate(index, start: start),
              onRetryUpload: (taskId) => onRetryUpload(index, taskId),
              onRemoveUpload: (taskId) => onRemoveUpload(index, taskId),
            ),
          );
        }),
      ],
    );
  }
}

class _OfferEditorHeader extends StatelessWidget {
  const _OfferEditorHeader({
    required this.isEditing,
    required this.allowMultiple,
    required this.offerCount,
    required this.colorScheme,
    required this.theme,
  });

  final bool isEditing;
  final bool allowMultiple;
  final int offerCount;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final title = isEditing
        ? (allowMultiple ? 'Edit grouped offers' : 'Edit offer')
        : 'Build your offers';
    final subtitle = isEditing
        ? (allowMultiple
              ? 'Update each offer card below. Changes save together on this record.'
              : 'Update the details below and save when you are ready.')
        : 'Each card is a complete offer with its own brand, cities, dates, status, images, and links.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isEditing ? Icons.edit_note_rounded : Icons.local_offer_rounded,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (!isEditing && offerCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$offerCount ${offerCount == 1 ? 'offer' : 'offers'}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfferLineCard extends StatelessWidget {
  const _OfferLineCard({
    required this.index,
    required this.line,
    required this.brands,
    required this.cities,
    required this.categories,
    required this.allowMultiple,
    required this.canRemove,
    required this.isBrandScopedUser,
    required this.scopedBrandId,
    required this.isManager,
    required this.lockedOffer,
    required this.onChanged,
    required this.onRemove,
    required this.onPickImages,
    required this.onPickDate,
    required this.onRetryUpload,
    required this.onRemoveUpload,
  });

  final int index;
  final OfferLineDraft line;
  final List<Brand> brands;
  final List<City> cities;
  final List<app_category.Category> categories;
  final bool allowMultiple;
  final bool canRemove;
  final bool isBrandScopedUser;
  final String? scopedBrandId;
  final bool isManager;
  final bool lockedOffer;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onPickImages;
  final Future<void> Function(bool start) onPickDate;
  final void Function(String taskId) onRetryUpload;
  final void Function(String taskId) onRemoveUpload;

  Brand? _brandById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final brand in brands) {
      if (brand.id == id) {
        return brand;
      }
    }
    return null;
  }

  void _applyBrandDefaults(Brand brand) {
    if (line.linkSources.every((source) => !source.hasUrl)) {
      line.linkSources = BrandUrlSourceUtils.copyList(
        brand.urlSources.isNotEmpty
            ? brand.urlSources
            : BrandUrlSourceUtils.fromLegacyFields(
                websiteUrl: brand.websiteUrl,
                instagramUrl: brand.instagramUrl,
                facebookUrl: brand.facebookUrl,
              ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = line.title.trim().isNotEmpty
        ? line.title.trim()
        : (allowMultiple ? 'Offer ${index + 1}' : 'Offer');
    final selectedBrand = _brandById(
      isBrandScopedUser ? scopedBrandId : line.brandId,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFAFBFC),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    header,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove offer',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (isManager)
                  DropdownBox(
                    child: TextFormField(
                      initialValue: 'Pending Review',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                    ),
                  )
                else
                  DropdownBox(
                    child: DropdownButtonFormField<String>(
                      initialValue: line.status,
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
                      onChanged: lockedOffer
                          ? null
                          : (value) {
                              line.status = value ?? 'pending_review';
                              onChanged();
                            },
                    ),
                  ),
                DropdownBox(
                  child: DropdownButtonFormField<bool>(
                    initialValue: line.isVerified,
                    decoration: const InputDecoration(
                      labelText: 'Verification',
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Verified')),
                      DropdownMenuItem(value: false, child: Text('Unverified')),
                    ],
                    onChanged: lockedOffer
                        ? null
                        : (value) {
                            line.isVerified = value ?? false;
                            if (!line.isVerified) {
                              line.isFeatured = false;
                            }
                            onChanged();
                          },
                  ),
                ),
                DropdownBox(
                  child: DropdownButtonFormField<String>(
                    initialValue: line.lifecycleStatus,
                    decoration: const InputDecoration(
                      labelText: 'Offer lifecycle',
                      prefixIcon: Icon(Icons.timeline_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'ending_soon',
                        child: Text('Ending Soon'),
                      ),
                      DropdownMenuItem(
                        value: 'expired',
                        child: Text('Expired'),
                      ),
                    ],
                    onChanged: lockedOffer
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            line.applyLifecycleStatus(value);
                            onChanged();
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: line.title,
              enabled: !lockedOffer,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Title is required' : null,
              onChanged: (value) {
                line.title = value;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: line.description,
              enabled: !lockedOffer,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              onChanged: (value) {
                line.description = value;
                onChanged();
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isBrandScopedUser)
                  DropdownBox(
                    child: TextFormField(
                      initialValue: selectedBrand?.name ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                  )
                else
                  DropdownBox(
                    child: DropdownMenu<String>(
                      width: 360,
                      requestFocusOnTap: true,
                      initialSelection: line.brandId,
                      enableSearch: true,
                      enableFilter: true,
                      label: const Text('Brand'),
                      leadingIcon: const Icon(Icons.storefront_outlined),
                      hintText: 'Select brand',
                      dropdownMenuEntries: brands
                          .map(
                            (brand) => DropdownMenuEntry(
                              value: brand.id,
                              label: brand.name,
                            ),
                          )
                          .toList(),
                      onSelected: lockedOffer
                          ? null
                          : (value) {
                              line.brandId = value;
                              final brand = _brandById(value);
                              if (brand != null) {
                                _applyBrandDefaults(brand);
                              }
                              onChanged();
                            },
                    ),
                  ),
                MultiSelectField(
                  width: 360,
                  label: 'Cities',
                  emptyLabel: 'Select cities',
                  options: cities
                      .map(
                        (city) =>
                            MultiSelectOption(id: city.id, label: city.name),
                      )
                      .toList(),
                  selectedIds: line.selectedCityIds.toList(),
                  onChanged: lockedOffer
                      ? (_) {}
                      : (ids) {
                          line.selectedCityIds = ids.toSet();
                          onChanged();
                        },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                DateButton(
                  label: 'Start date',
                  value: line.startDate?.shortDate,
                  onPressed: lockedOffer ? () {} : () => onPickDate(true),
                ),
                DateButton(
                  label: 'End date',
                  value: line.endDate?.shortDate,
                  onPressed: lockedOffer ? () {} : () => onPickDate(false),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                DropdownBox(
                  child: DropdownButtonFormField<String>(
                    initialValue: _singleMatchingValue(
                      line.categoryId,
                      categories.map((item) => item.id),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: lockedOffer
                        ? null
                        : (value) {
                            line.categoryId = value;
                            onChanged();
                          },
                  ),
                ),
                DropdownBox(
                  child: TextFormField(
                    initialValue: line.discountText,
                    enabled: !lockedOffer,
                    decoration: const InputDecoration(
                      labelText: 'Discount text',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    onChanged: (value) {
                      line.discountText = value;
                      onChanged();
                    },
                  ),
                ),
                DropdownBox(
                  child: DropdownButtonFormField<String>(
                    initialValue: line.discountType,
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
                        value: 'upto_percentage',
                        child: Text('Up to percentage'),
                      ),
                      DropdownMenuItem(
                        value: 'upto_amount',
                        child: Text('Up to amount'),
                      ),
                      DropdownMenuItem(value: 'bundle', child: Text('Bundle')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: lockedOffer
                        ? null
                        : (value) {
                            line.discountType = value ?? 'percentage';
                            onChanged();
                          },
                  ),
                ),
                DropdownBox(
                  child: TextFormField(
                    initialValue: line.discountValue,
                    enabled: !lockedOffer,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Discount value',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    onChanged: (value) {
                      line.discountValue = value;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            UrlSourcesField(
              title: 'Offer link sources',
              sources: line.linkSources,
              onChanged: lockedOffer
                  ? (_) {}
                  : (sources) {
                      line.linkSources = sources;
                      onChanged();
                    },
            ),
            const SizedBox(height: 14),
            ImagePickerPanel(
              imageUrls: line.imageUrls,
              imageUploads: line.imageUploads,
              onPick: lockedOffer ? () {} : onPickImages,
              onRetryUpload: lockedOffer ? null : onRetryUpload,
              onRemoveUpload: lockedOffer ? null : onRemoveUpload,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: AppListTileMaterial(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-advance slider'),
                      subtitle: const Text(
                        'Mobile carousel moves to the next image automatically.',
                      ),
                      value: line.imageSliderAutoPlay,
                      onChanged: lockedOffer
                          ? null
                          : (value) {
                              line.imageSliderAutoPlay = value;
                              onChanged();
                            },
                    ),
                  ),
                ),
                DropdownBox(
                  child: DropdownButtonFormField<String>(
                    initialValue: line.imageDisplayMode,
                    decoration: const InputDecoration(
                      labelText: 'Offer detail image view',
                      prefixIcon: Icon(Icons.view_carousel_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'carousel',
                        child: Text('Carousel'),
                      ),
                      DropdownMenuItem(value: 'grid', child: Text('Grid')),
                    ],
                    onChanged: lockedOffer
                        ? null
                        : (value) {
                            line.imageDisplayMode = value ?? 'carousel';
                            onChanged();
                          },
                  ),
                ),
                FilterChip(
                  label: const Text('Featured'),
                  selected: line.isFeatured,
                  onSelected: lockedOffer || !line.isVerified
                      ? null
                      : (value) {
                          line.isFeatured = value;
                          onChanged();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String? _singleMatchingValue(String? value, Iterable<String> options) {
  if (value == null) {
    return null;
  }
  var matches = 0;
  for (final option in options) {
    if (option == value) {
      matches++;
    }
  }
  return matches == 1 ? value : null;
}

Offer? buildOfferFromDraft({
  required OfferLineDraft draft,
  required List<Brand> brands,
  required List<app_category.Category> categories,
  required List<City> cities,
  required AppUser? user,
  required bool isBrandScopedUser,
  required bool isManager,
  Offer? baseOffer,
  String? forcedId,
}) {
  final brandId = isBrandScopedUser ? user?.brandId : draft.brandId;
  final brand = brands.where((item) => item.id == brandId).firstOrNull;
  final categoryId = draft.categoryId;
  if (brand == null || categoryId == null || categoryId.isEmpty) {
    return null;
  }
  final category = categories
      .where((item) => item.id == categoryId)
      .firstOrNull;
  if (category == null) {
    return null;
  }
  final selectedCities = cities
      .where((city) => draft.selectedCityIds.contains(city.id))
      .toList();
  if (selectedCities.isEmpty ||
      draft.startDate == null ||
      draft.endDate == null) {
    return null;
  }
  if (!draft.endDate!.isAfter(draft.startDate!)) {
    return null;
  }
  final sources = BrandUrlSourceUtils.withStableIds(draft.linkSources);
  final images = draft.imageUrls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();
  final now = DateTime.now();
  var selectedStatus = isBrandScopedUser
      ? draft.status
      : (baseOffer?.status ?? draft.status);
  var selectedPublished = isBrandScopedUser
      ? selectedStatus == 'published'
      : (baseOffer?.isPublished ?? draft.status == 'published');
  if (isManager) {
    selectedStatus = 'pending_review';
    selectedPublished = false;
  }
  final city = selectedCities.first;
  return Offer(
    id: forcedId ?? baseOffer?.id ?? '',
    title: draft.title.trim(),
    description: draft.description.trim(),
    brandId: brand.id,
    brandName: brand.name,
    categoryId: category.id,
    categoryName: category.name,
    categoryIds: [category.id],
    categoryNames: [category.name],
    cityId: city.id,
    cityName: city.name,
    cityIds: selectedCities.map((item) => item.id).toList(),
    cityNames: selectedCities.map((item) => item.name).toList(),
    discountText: draft.discountText.trim(),
    discountType: draft.discountType,
    discountValue: int.tryParse(draft.discountValue.trim()),
    imageUrl: images.isNotEmpty ? images.first : '',
    imageUrls: images,
    imageSliderAutoPlay: draft.imageSliderAutoPlay,
    imageDisplayMode: draft.imageDisplayMode,
    sourceUrl: BrandUrlSourceUtils.legacySourceUrl(sources),
    onlineUrl: BrandUrlSourceUtils.legacyOnlineUrl(sources),
    linkSources: sources,
    startDate: draft.startDate!,
    endDate: draft.endDate!,
    isVerified: selectedPublished ? true : draft.isVerified,
    isPublished: selectedPublished,
    isFeatured: draft.isFeatured,
    aiConfidence: baseOffer?.aiConfidence,
    createdBy: baseOffer?.createdBy ?? user?.id ?? '',
    createdAt: baseOffer?.createdAt ?? now,
    updatedAt: now,
    createdByUserId: baseOffer?.createdByUserId ?? user?.id ?? '',
    createdByRole: baseOffer?.createdByRole ?? 'owner',
    status: isBrandScopedUser
        ? selectedStatus
        : (baseOffer?.status ?? selectedStatus),
    approvalStatus: isBrandScopedUser
        ? selectedStatus == 'published'
              ? 'approved'
              : 'pending'
        : (baseOffer?.approvalStatus ?? 'pending'),
    approvedBy: isBrandScopedUser
        ? selectedStatus == 'published'
              ? user?.id ?? ''
              : ''
        : (baseOffer?.approvedBy ?? ''),
    approvedAt: isBrandScopedUser
        ? selectedStatus == 'published'
              ? now
              : null
        : baseOffer?.approvedAt,
    offerLines: const [],
  );
}

String? validateOfferDrafts(
  List<OfferLineDraft> drafts, {
  required bool isBrandScopedUser,
}) {
  if (drafts.isEmpty) {
    return 'Add at least one offer.';
  }
  for (var i = 0; i < drafts.length; i++) {
    final draft = drafts[i];
    final label = 'offer ${i + 1}';
    if (draft.title.trim().isEmpty) {
      return 'Enter a title for $label.';
    }
    if (!isBrandScopedUser &&
        (draft.brandId == null || draft.brandId!.isEmpty)) {
      return 'Select a brand for $label.';
    }
    if (draft.selectedCityIds.isEmpty) {
      return 'Select at least one city for $label.';
    }
    if (draft.startDate == null || draft.endDate == null) {
      return 'Select start and end dates for $label.';
    }
    if (!draft.endDate!.isAfter(draft.startDate!)) {
      return 'End date must be after start date for $label.';
    }
    if (draft.categoryId == null || draft.categoryId!.isEmpty) {
      return 'Select a category for $label.';
    }
    if (draft.discountText.trim().isEmpty) {
      return 'Enter discount text for $label.';
    }
    if (!draft.imagesReady) {
      if (draft.isUploadingImages) {
        return 'Wait for image uploads to finish for $label.';
      }
      if (draft.hasFailedUploads) {
        return 'Retry or remove failed image uploads for $label.';
      }
      return 'Upload at least one image for $label.';
    }
    if (draft.isFeatured && !draft.isVerified) {
      return 'Only verified offers can be featured ($label).';
    }
  }
  return null;
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
