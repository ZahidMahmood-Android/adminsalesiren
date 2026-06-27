import '../../../brands/domain/entities/brand_url_source.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import 'offer_line.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.cityId,
    required this.cityName,
    required this.discountText,
    required this.discountType,
    required this.discountValue,
    required this.imageUrl,
    this.imageUrls = const [],
    this.imageSliderAutoPlay = true,
    this.imageDisplayMode = 'carousel',
    required this.sourceUrl,
    required this.onlineUrl,
    this.linkSources = const [],
    this.shareUrl = '',
    required this.startDate,
    this.endDate,
    this.endDateMode = OfferEndDateModes.fixed,
    required this.isVerified,
    required this.isPublished,
    required this.isFeatured,
    required this.aiConfidence,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUserId = '',
    this.createdByRole = 'owner',
    this.status = 'published',
    this.approvalStatus = 'approved',
    this.approvalNotes = '',
    this.approvedBy = '',
    this.approvedAt,
    this.categoryIds = const [],
    this.categoryNames = const [],
    this.cityIds = const [],
    this.cityNames = const [],
    this.viewCount = 0,
    this.saveCount = 0,
    this.shareCount = 0,
    this.clickCount = 0,
    this.reportCount = 0,
    this.offerLines = const [],
    this.alertType = '',
    this.notificationSnapshot,
  });

  final String id;
  final String title;
  final String description;
  final String brandId;
  final String brandName;
  final String categoryId;
  final String categoryName;
  final String cityId;
  final String cityName;
  final String discountText;
  final String discountType;
  final num? discountValue;
  final String imageUrl;
  final List<String> imageUrls;
  final bool imageSliderAutoPlay;
  final String imageDisplayMode;
  final String sourceUrl;
  final String onlineUrl;
  final List<BrandUrlSource> linkSources;
  final String shareUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String endDateMode;
  final bool isVerified;
  final bool isPublished;
  final bool isFeatured;
  final num? aiConfidence;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByUserId;
  final String createdByRole;
  final String status;
  final String approvalStatus;
  final String approvalNotes;
  final String approvedBy;
  final DateTime? approvedAt;
  final List<String> categoryIds;
  final List<String> categoryNames;
  final List<String> cityIds;
  final List<String> cityNames;
  final int viewCount;
  final int saveCount;
  final int shareCount;
  final int clickCount;
  final int reportCount;
  final List<OfferLine> offerLines;
  final String alertType;
  final Map<String, dynamic>? notificationSnapshot;

  bool get isGroupOffer => resolvedLines.length > 1;

  List<OfferLine> get resolvedLines {
    if (offerLines.isNotEmpty) {
      return offerLines;
    }
    if (categoryId.isEmpty && discountText.isEmpty) {
      return const [];
    }
    return [
      OfferLine(
        id: 'primary',
        title: title,
        description: description,
        categoryId: categoryId,
        categoryName: categoryName,
        discountText: discountText,
        discountType: discountType,
        discountValue: discountValue,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
        linkSources: linkSources,
        published: isPublished,
      ),
    ];
  }

  String get groupSummaryLabel {
    final lines = resolvedLines;
    if (lines.length <= 1) {
      return discountText;
    }
    return '${lines.length} offers';
  }

  OfferDiscount get discount => OfferDiscount(
    discountText: discountText,
    discountType: discountType,
    discountValue: discountValue,
  );

  String get discountDisplay => discount.displayText;

  String get scheduleEndLabel => OfferEndDateModes.scheduleEndLabel(
        mode: endDateMode,
        endDate: endDate,
        formatDate: (date) => date.shortDate,
      );

  bool get isExpired =>
      status == 'expired' ||
      OfferSchedule(
        startDate: startDate,
        endDate: endDate,
        endDateMode: endDateMode,
      ).isExpired;

  Offer copyWith({
    String? id,
    String? title,
    String? description,
    String? brandId,
    String? brandName,
    String? categoryId,
    String? categoryName,
    String? cityId,
    String? cityName,
    String? discountText,
    String? discountType,
    num? discountValue,
    String? imageUrl,
    List<String>? imageUrls,
    bool? imageSliderAutoPlay,
    String? imageDisplayMode,
    String? sourceUrl,
    String? onlineUrl,
    List<BrandUrlSource>? linkSources,
    String? shareUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? endDateMode,
    bool clearEndDate = false,
    bool? isVerified,
    bool? isPublished,
    bool? isFeatured,
    num? aiConfidence,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUserId,
    String? createdByRole,
    String? status,
    String? approvalStatus,
    String? approvalNotes,
    String? approvedBy,
    DateTime? approvedAt,
    List<String>? categoryIds,
    List<String>? categoryNames,
    List<String>? cityIds,
    List<String>? cityNames,
    int? viewCount,
    int? saveCount,
    int? shareCount,
    int? clickCount,
    int? reportCount,
    List<OfferLine>? offerLines,
    String? alertType,
    Map<String, dynamic>? notificationSnapshot,
  }) {
    return Offer(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      discountText: discountText ?? this.discountText,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      imageSliderAutoPlay: imageSliderAutoPlay ?? this.imageSliderAutoPlay,
      imageDisplayMode: imageDisplayMode ?? this.imageDisplayMode,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      onlineUrl: onlineUrl ?? this.onlineUrl,
      linkSources: linkSources ?? this.linkSources,
      shareUrl: shareUrl ?? this.shareUrl,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      endDateMode: endDateMode ?? this.endDateMode,
      isVerified: isVerified ?? this.isVerified,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByRole: createdByRole ?? this.createdByRole,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryNames: categoryNames ?? this.categoryNames,
      cityIds: cityIds ?? this.cityIds,
      cityNames: cityNames ?? this.cityNames,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
      shareCount: shareCount ?? this.shareCount,
      clickCount: clickCount ?? this.clickCount,
      reportCount: reportCount ?? this.reportCount,
      offerLines: offerLines ?? this.offerLines,
      alertType: alertType ?? this.alertType,
      notificationSnapshot: notificationSnapshot ?? this.notificationSnapshot,
    );
  }
}
