import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sale_siren_models/sale_siren_models.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/multi_select_field.dart';
import '../../../../core/widgets/single_select_field.dart';
import '../../../../core/widgets/app_field_selector.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/domain/entities/brand_url_source.dart';
import '../../../brands/presentation/widgets/url_sources_field.dart';
import '../../../categories/domain/entities/category.dart' as app_category;
import '../../../cities/domain/entities/city.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_image_upload_task.dart';
import '../../domain/entities/offer_line.dart';
import '../../domain/utils/offer_discount_parse_utils.dart';
import 'offer_form_controls.dart';

const kAllCitiesLabel = 'All cities';
const kWholeBrandCategoryLabel = 'Whole brand';

Set<String> allCityIds(List<City> cities) =>
    cities.map((city) => city.id).toSet();

bool offerCoversAllCities({
  required Offer offer,
  required List<City> allCities,
}) {
  if (allCities.isEmpty) {
    return false;
  }
  final selected = offer.cityIds.isEmpty
      ? {if (offer.cityId.isNotEmpty) offer.cityId}
      : offer.cityIds.toSet();
  if (selected.isEmpty) {
    return false;
  }
  final visibleIds = allCityIds(allCities);
  return selected.length == visibleIds.length &&
      visibleIds.every(selected.contains);
}

String offerCitiesDisplayLabel(Offer offer, {List<City>? allCities}) {
  if (allCities != null &&
      offerCoversAllCities(offer: offer, allCities: allCities)) {
    return kAllCitiesLabel;
  }
  if (offer.cityNames.isNotEmpty) {
    return offer.cityNames.join(', ');
  }
  return offer.cityName;
}

enum OfferCategoryScope { selected, wholeBrand }

class OfferLineDraft {
  OfferLineDraft({
    required this.id,
    this.brandId,
    Set<String>? selectedCityIds,
    this.title = '',
    this.description = '',
    Set<String>? selectedCategoryIds,
    this.categoryScope = OfferCategoryScope.selected,
    this.discountText = '',
    this.discountType = 'percentage',
    this.discountValue = '',
    this.status = 'pending_review',
    this.lifecycleStatus = 'active',
    this.endDateMode = OfferEndDateModes.fixed,
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
  }) : selectedCityIds = selectedCityIds ?? const {},
       selectedCategoryIds = selectedCategoryIds ?? <String>{},
       startDate = startDate ?? _defaultStartDate(),
       endDate = OfferEndDateModes.hasOpenEndedEnd(endDateMode)
           ? null
           : (endDate ?? _defaultEndDate()),
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
  Set<String> selectedCategoryIds;
  OfferCategoryScope categoryScope;
  String discountText;
  String discountType;
  String discountValue;
  String status;
  String lifecycleStatus;
  String endDateMode;
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
    List<City>? cities,
    List<BrandUrlSource>? linkSources,
  }) {
    return OfferLineDraft(
      id: const Uuid().v4(),
      brandId: brandId,
      selectedCityIds:
          selectedCityIds ??
          (cities != null && cities.isNotEmpty ? allCityIds(cities) : null),
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
    if (status != 'pending_review' &&
        status != 'published' &&
        status != 'approved') {
      status = 'pending_review';
    }
    final discount = OfferDiscountParseUtils.resolve(
      discountText: offer.discountText,
      discountType: offer.discountType,
      discountValue: offer.discountValue,
    );
    return OfferLineDraft(
      id: offer.id,
      brandId: offer.brandId,
      selectedCityIds: offer.cityIds.isEmpty
          ? {if (offer.cityId.isNotEmpty) offer.cityId}
          : offer.cityIds.toSet(),
      title: offer.title,
      description: offer.description,
      selectedCategoryIds: offer.categoryIds.isNotEmpty
          ? offer.categoryIds.toSet()
          : {if (offer.categoryId.isNotEmpty) offer.categoryId},
      categoryScope: offer.categoryName == kWholeBrandCategoryLabel
          ? OfferCategoryScope.wholeBrand
          : OfferCategoryScope.selected,
      discountText: discount.discountText,
      discountType: discount.discountType,
      discountValue: discount.discountValue?.toString() ?? '',
      status: status,
      lifecycleStatus: lifecycleForDate(offer.endDate, offer.endDateMode),
      startDate: offer.startDate,
      endDate: offer.endDate,
      endDateMode: offer.endDateMode,
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
    if (status != 'pending_review' &&
        status != 'published' &&
        status != 'approved') {
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
      selectedCategoryIds: line.categoryId.isEmpty
          ? parent.categoryIds.toSet()
          : {line.categoryId},
      categoryScope:
          line.categoryName == kWholeBrandCategoryLabel ||
              parent.categoryName == kWholeBrandCategoryLabel
          ? OfferCategoryScope.wholeBrand
          : OfferCategoryScope.selected,
      discountText: line.discountText,
      discountType: line.discountType,
      discountValue: line.discountValue?.toString() ?? '',
      status: status,
      lifecycleStatus: lifecycleForDate(parent.endDate, parent.endDateMode),
      startDate: parent.startDate,
      endDate: parent.endDate,
      endDateMode: parent.endDateMode,
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
      categoryScope == OfferCategoryScope.selected &&
      selectedCategoryIds.isEmpty &&
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
      'selectedCategoryIds': selectedCategoryIds.toList(),
      'categoryScope': categoryScope.name,
      'discountText': discountText,
      'discountType': discountType,
      'discountValue': discountValue,
      'status': status,
      'lifecycleStatus': lifecycleStatus,
      'endDateMode': endDateMode,
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
    final categoryIds = json['selectedCategoryIds'];
    final legacyCategoryId = json['categoryId'] as String?;
    final parsedCategoryIds = categoryIds is List
        ? categoryIds.map((item) => item.toString()).toSet()
        : <String>{
            if (legacyCategoryId != null && legacyCategoryId.isNotEmpty)
              legacyCategoryId,
          };
    final scopeName = json['categoryScope'] as String?;
    return OfferLineDraft(
      id: json['id'] as String? ?? const Uuid().v4(),
      brandId: json['brandId'] as String?,
      selectedCityIds: cityIds is List
          ? cityIds.map((item) => item.toString()).toSet()
          : null,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      selectedCategoryIds: parsedCategoryIds,
      categoryScope: scopeName == OfferCategoryScope.wholeBrand.name
          ? OfferCategoryScope.wholeBrand
          : OfferCategoryScope.selected,
      discountText: json['discountText'] as String? ?? '',
      discountType: json['discountType'] as String? ?? 'percentage',
      discountValue: json['discountValue'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      lifecycleStatus: json['lifecycleStatus'] as String? ?? 'active',
      endDateMode: json['endDateMode'] as String? ?? OfferEndDateModes.fixed,
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
      endDateMode = OfferEndDateModes.fixed;
      startDate = date.subtract(const Duration(days: 7));
      endDate = date.subtract(const Duration(days: 1));
    } else if (value == 'ending_soon') {
      endDateMode = OfferEndDateModes.fixed;
      startDate = date;
      endDate = date.add(const Duration(days: 2));
    } else {
      startDate = date;
      if (endDateMode == OfferEndDateModes.fixed) {
        endDate = date.add(const Duration(days: 14));
      }
    }
  }

  void syncLifecycleFromEndDate() {
    lifecycleStatus = lifecycleForDate(endDate, endDateMode);
  }
}

String lifecycleForDate(DateTime? endDate, [String? endDateMode]) {
  if (OfferEndDateModes.hasOpenEndedEnd(endDateMode)) {
    return 'active';
  }
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
    this.onRemoveUploaded,
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
  final void Function(int index, String imageUrl)? onRemoveUploaded;
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
                    cities: cities,
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
                            cities: cities,
                          ),
                        ]
                      : next,
                );
              },
              onPickImages: () => onPickImages(index),
              onPickDate: (start) => onPickDate(index, start: start),
              onRetryUpload: (taskId) => onRetryUpload(index, taskId),
              onRemoveUpload: (taskId) => onRemoveUpload(index, taskId),
              onRemoveUploaded: onRemoveUploaded == null
                  ? null
                  : (imageUrl) => onRemoveUploaded!(index, imageUrl),
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
    this.onRemoveUploaded,
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
  final void Function(String imageUrl)? onRemoveUploaded;

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
                  SingleSelectField<String>(
                    label: 'Status',
                    prefixIcon: Icons.info_outline,
                    value: 'pending_review',
                    enabled: false,
                    options: const [
                      SingleSelectOption(
                        value: 'pending_review',
                        label: 'Pending Review',
                      ),
                    ],
                    onChanged: null,
                  )
                else
                  SingleSelectField<String>(
                    label: 'Status',
                    prefixIcon: Icons.info_outline,
                    value: line.status,
                    enabled: !lockedOffer,
                    options: const [
                      SingleSelectOption(
                        value: 'pending_review',
                        label: 'Pending Review',
                      ),
                      SingleSelectOption(
                        value: 'published',
                        label: 'Published',
                      ),
                    ],
                    onChanged: lockedOffer
                        ? null
                        : (value) {
                            line.status = value ?? 'pending_review';
                            onChanged();
                          },
                  ),
                SingleSelectField<bool>(
                  label: 'Verification',
                  prefixIcon: Icons.verified_outlined,
                  value: line.isVerified,
                  enabled: !lockedOffer,
                  options: const [
                    SingleSelectOption(value: true, label: 'Verified'),
                    SingleSelectOption(value: false, label: 'Unverified'),
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
                SingleSelectField<String>(
                  label: 'Offer lifecycle',
                  prefixIcon: Icons.timeline_outlined,
                  value: line.lifecycleStatus,
                  enabled: !lockedOffer,
                  options: const [
                    SingleSelectOption(value: 'active', label: 'Active'),
                    SingleSelectOption(
                      value: 'ending_soon',
                      label: 'Ending Soon',
                    ),
                    SingleSelectOption(value: 'expired', label: 'Expired'),
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
                  SingleSelectField<String>(
                    label: 'Brand',
                    prefixIcon: Icons.storefront_outlined,
                    value: line.brandId,
                    emptyLabel: 'Select brand',
                    enableSearch: true,
                    enabled: !lockedOffer,
                    options: brands
                        .map(
                          (brand) => SingleSelectOption(
                            value: brand.id,
                            label: brand.name,
                          ),
                        )
                        .toList(),
                    onChanged: lockedOffer
                        ? null
                        : (value) {
                            line.brandId = value;
                            final brand = _brandById(value);
                            if (brand != null) {
                              _applyBrandDefaults(brand);
                              if (line.categoryScope ==
                                  OfferCategoryScope.selected) {
                                final allowed = brand.categoryIds.toSet();
                                if (allowed.isNotEmpty) {
                                  line.selectedCategoryIds.removeWhere(
                                    (id) => !allowed.contains(id),
                                  );
                                }
                              }
                            }
                            onChanged();
                          },
                  ),
                MultiSelectField(
                  label: 'Cities',
                  prefixIcon: Icons.location_city_outlined,
                  emptyLabel: 'Select cities',
                  enableSelectAll: true,
                  selectAllLabel: 'All cities',
                  showClearOption: false,
                  enabled: !lockedOffer,
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
                  enabled: !lockedOffer,
                  onPressed: lockedOffer ? () {} : () => onPickDate(true),
                ),
                SingleSelectField<String>(
                  label: 'Offer ends',
                  prefixIcon: Icons.event_available_outlined,
                  value: line.endDateMode,
                  enabled: !lockedOffer,
                  options: const [
                    SingleSelectOption(
                      value: OfferEndDateModes.fixed,
                      label: 'Fixed end date',
                    ),
                    SingleSelectOption(
                      value: OfferEndDateModes.ongoing,
                      label: 'Ongoing',
                    ),
                    SingleSelectOption(
                      value: OfferEndDateModes.untilStockEnds,
                      label: 'Until stock ends',
                    ),
                  ],
                  onChanged: lockedOffer
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          line.endDateMode = value;
                          if (OfferEndDateModes.hasOpenEndedEnd(value)) {
                            line.endDate = null;
                          } else {
                            line.endDate ??= OfferLineDraft._defaultEndDate();
                          }
                          line.syncLifecycleFromEndDate();
                          onChanged();
                        },
                ),
                if (line.endDateMode == OfferEndDateModes.fixed)
                  DateButton(
                    label: 'End date',
                    value: line.endDate?.shortDate,
                    enabled: !lockedOffer,
                    onPressed: lockedOffer ? () {} : () => onPickDate(false),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Offer applies to',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SegmentedButton<OfferCategoryScope>(
              segments: const [
                ButtonSegment(
                  value: OfferCategoryScope.selected,
                  label: Text('Selected categories'),
                  icon: Icon(Icons.category_outlined),
                ),
                ButtonSegment(
                  value: OfferCategoryScope.wholeBrand,
                  label: Text('Whole brand'),
                  icon: Icon(Icons.storefront_outlined),
                ),
              ],
              selected: {line.categoryScope},
              onSelectionChanged: lockedOffer
                  ? null
                  : (selection) {
                      final scope = selection.first;
                      line.categoryScope = scope;
                      if (scope == OfferCategoryScope.wholeBrand) {
                        line.selectedCategoryIds.clear();
                      }
                      onChanged();
                    },
            ),
            const SizedBox(height: 12),
            if (line.categoryScope == OfferCategoryScope.wholeBrand)
              AppFieldSelector(
                label: 'Categories',
                prefixIcon: Icons.category_outlined,
                valueText: selectedBrand == null
                    ? 'Select a brand to run this offer on the whole brand'
                    : 'Offer on whole brand',
                enabled: false,
                onTap: null,
              )
            else
              MultiSelectField(
                label: 'Categories',
                prefixIcon: Icons.category_outlined,
                emptyLabel: 'Select categories',
                enabled: !lockedOffer,
                options:
                    categoriesForBrand(
                          brand: selectedBrand,
                          allCategories: categories,
                        )
                        .map(
                          (category) => MultiSelectOption(
                            id: category.id,
                            label: category.name,
                          ),
                        )
                        .toList(),
                selectedIds: line.selectedCategoryIds.toList(),
                onChanged: lockedOffer
                    ? (_) {}
                    : (ids) {
                        line.selectedCategoryIds = ids.toSet();
                        onChanged();
                      },
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
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
                SingleSelectField<String>(
                  label: 'Discount type',
                  prefixIcon: Icons.local_offer_outlined,
                  value: line.discountType,
                  enabled: !lockedOffer,
                  options: const [
                    SingleSelectOption(
                      value: 'percentage',
                      label: 'Percentage',
                    ),
                    SingleSelectOption(value: 'flat', label: 'Flat amount'),
                    SingleSelectOption(
                      value: 'upto_percentage',
                      label: 'Up to percentage',
                    ),
                    SingleSelectOption(
                      value: 'upto_amount',
                      label: 'Up to amount',
                    ),
                    SingleSelectOption(value: 'bundle', label: 'Bundle'),
                    SingleSelectOption(value: 'other', label: 'Other'),
                  ],
                  onChanged: lockedOffer
                      ? null
                      : (value) {
                          line.discountType = value ?? 'percentage';
                          onChanged();
                        },
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
              onRemoveUploaded: lockedOffer ? null : onRemoveUploaded,
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
                SingleSelectField<String>(
                  label: 'Offer detail image view',
                  prefixIcon: Icons.view_carousel_outlined,
                  value: line.imageDisplayMode,
                  enabled: !lockedOffer,
                  options: const [
                    SingleSelectOption(value: 'carousel', label: 'Carousel'),
                    SingleSelectOption(value: 'grid', label: 'Grid'),
                  ],
                  onChanged: lockedOffer
                      ? null
                      : (value) {
                          line.imageDisplayMode = value ?? 'carousel';
                          onChanged();
                        },
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

List<app_category.Category> categoriesForBrand({
  required Brand? brand,
  required List<app_category.Category> allCategories,
}) {
  if (brand == null || brand.categoryIds.isEmpty) {
    return allCategories;
  }
  final allowed = brand.categoryIds.toSet();
  return allCategories
      .where((category) => allowed.contains(category.id))
      .toList();
}

List<app_category.Category> resolveDraftCategories({
  required OfferLineDraft draft,
  required Brand? brand,
  required List<app_category.Category> allCategories,
}) {
  if (draft.categoryScope == OfferCategoryScope.wholeBrand) {
    return categoriesForBrand(brand: brand, allCategories: allCategories);
  }
  return allCategories
      .where((category) => draft.selectedCategoryIds.contains(category.id))
      .toList();
}

String offerCategoryLabel({
  required OfferCategoryScope scope,
  required List<app_category.Category> categories,
}) {
  if (scope == OfferCategoryScope.wholeBrand) {
    return kWholeBrandCategoryLabel;
  }
  if (categories.isEmpty) {
    return '';
  }
  if (categories.length == 1) {
    return categories.first.name;
  }
  return '${categories.length} categories';
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
  if (brand == null) {
    return null;
  }
  final resolvedCategories = resolveDraftCategories(
    draft: draft,
    brand: brand,
    allCategories: categories,
  );
  if (resolvedCategories.isEmpty) {
    return null;
  }
  final resolvedCityIds = draft.selectedCityIds.isNotEmpty
      ? draft.selectedCityIds
      : allCityIds(cities);
  final selectedCities = cities
      .where((city) => resolvedCityIds.contains(city.id))
      .toList();
  if (selectedCities.isEmpty || draft.startDate == null) {
    return null;
  }
  if (draft.endDateMode == OfferEndDateModes.fixed) {
    if (draft.endDate == null || !draft.endDate!.isAfter(draft.startDate!)) {
      return null;
    }
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
  final primaryCategory = resolvedCategories.first;
  return Offer(
    id: forcedId ?? baseOffer?.id ?? '',
    title: draft.title.trim(),
    description: draft.description.trim(),
    brandId: brand.id,
    brandName: brand.name,
    categoryId: primaryCategory.id,
    categoryName: offerCategoryLabel(
      scope: draft.categoryScope,
      categories: resolvedCategories,
    ),
    categoryIds: resolvedCategories.map((item) => item.id).toList(),
    categoryNames: resolvedCategories.map((item) => item.name).toList(),
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
    endDate: draft.endDate,
    endDateMode: draft.endDateMode,
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
        ? selectedPublished
              ? 'approved'
              : (baseOffer?.approvalStatus ?? 'pending')
        : (baseOffer?.approvalStatus ?? 'pending'),
    approvedBy: isBrandScopedUser
        ? selectedPublished
              ? (baseOffer?.approvedBy.isNotEmpty == true
                    ? baseOffer!.approvedBy
                    : user?.id ?? '')
              : (baseOffer?.approvedBy ?? '')
        : (baseOffer?.approvedBy ?? ''),
    approvedAt: isBrandScopedUser
        ? selectedPublished
              ? (baseOffer?.approvedAt ?? now)
              : baseOffer?.approvedAt
        : baseOffer?.approvedAt,
    offerLines: const [],
  );
}

String? validateOfferDrafts(
  List<OfferLineDraft> drafts, {
  required bool isBrandScopedUser,
  List<City> cities = const [],
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
    final resolvedCityIds = draft.selectedCityIds.isNotEmpty
        ? draft.selectedCityIds
        : allCityIds(cities);
    if (resolvedCityIds.isEmpty) {
      return 'Select at least one city for $label.';
    }
    if (draft.startDate == null) {
      return 'Select a start date for $label.';
    }
    if (draft.endDateMode == OfferEndDateModes.fixed) {
      if (draft.endDate == null) {
        return 'Select an end date for $label.';
      }
      if (!draft.endDate!.isAfter(draft.startDate!)) {
        return 'End date must be after start date for $label.';
      }
    }
    if (draft.categoryScope == OfferCategoryScope.wholeBrand) {
      if (!isBrandScopedUser &&
          (draft.brandId == null || draft.brandId!.isEmpty)) {
        return 'Select a brand for whole-brand $label.';
      }
    } else if (draft.selectedCategoryIds.isEmpty) {
      return 'Select at least one category for $label.';
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
