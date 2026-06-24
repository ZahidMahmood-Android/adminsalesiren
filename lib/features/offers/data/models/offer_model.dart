import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sale_siren_models/sale_siren_models.dart';

import '../../../brands/domain/entities/brand_url_source.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_line.dart';

class OfferModel extends Offer {
  const OfferModel({
    required super.id,
    required super.title,
    required super.description,
    required super.brandId,
    required super.brandName,
    required super.categoryId,
    required super.categoryName,
    required super.cityId,
    required super.cityName,
    required super.discountText,
    required super.discountType,
    required super.discountValue,
    required super.imageUrl,
    super.imageUrls,
    super.imageSliderAutoPlay,
    super.imageDisplayMode,
    required super.sourceUrl,
    required super.onlineUrl,
    super.linkSources = const [],
    super.shareUrl = '',
    required super.startDate,
    required super.endDate,
    required super.isVerified,
    required super.isPublished,
    required super.isFeatured,
    required super.aiConfidence,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.createdByUserId,
    super.createdByRole,
    super.status,
    super.approvalStatus,
    super.approvalNotes,
    super.approvedBy,
    super.approvedAt,
    super.categoryIds,
    super.categoryNames,
    super.cityIds,
    super.cityNames,
    super.viewCount,
    super.saveCount,
    super.shareCount,
    super.clickCount,
    super.reportCount,
    super.offerLines,
  });

  factory OfferModel.fromEntity(Offer offer) {
    return OfferModel(
      id: offer.id,
      title: offer.title,
      description: offer.description,
      brandId: offer.brandId,
      brandName: offer.brandName,
      categoryId: offer.categoryId,
      categoryName: offer.categoryName,
      cityId: offer.cityId,
      cityName: offer.cityName,
      discountText: offer.discountText,
      discountType: offer.discountType,
      discountValue: offer.discountValue,
      imageUrl: offer.imageUrl,
      imageUrls: offer.imageUrls,
      imageSliderAutoPlay: offer.imageSliderAutoPlay,
      imageDisplayMode: offer.imageDisplayMode,
      sourceUrl: offer.sourceUrl,
      onlineUrl: offer.onlineUrl,
      linkSources: offer.linkSources,
      shareUrl: offer.shareUrl,
      startDate: offer.startDate,
      endDate: offer.endDate,
      isVerified: offer.isVerified,
      isPublished: offer.isPublished,
      isFeatured: offer.isFeatured,
      aiConfidence: offer.aiConfidence,
      createdBy: offer.createdBy,
      createdAt: offer.createdAt,
      updatedAt: offer.updatedAt,
      createdByUserId: offer.createdByUserId,
      createdByRole: offer.createdByRole,
      status: offer.status,
      approvalStatus: offer.approvalStatus,
      approvalNotes: offer.approvalNotes,
      approvedBy: offer.approvedBy,
      approvedAt: offer.approvedAt,
      categoryIds: offer.categoryIds,
      categoryNames: offer.categoryNames,
      cityIds: offer.cityIds,
      cityNames: offer.cityNames,
      viewCount: offer.viewCount,
      saveCount: offer.saveCount,
      shareCount: offer.shareCount,
      clickCount: offer.clickCount,
      reportCount: offer.reportCount,
      offerLines: offer.offerLines,
    );
  }

  factory OfferModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final linkSources = _readLinkSources(data);
    final sourceUrl =
        data['sourceUrl'] as String? ??
        BrandUrlSourceUtils.legacySourceUrl(linkSources);
    final onlineUrl =
        data['onlineUrl'] as String? ??
        BrandUrlSourceUtils.legacyOnlineUrl(linkSources);
    final discount = OfferDiscount.fromMap(data);
    final schedule = OfferSchedule.fromMap(data);
    return OfferModel(
      id: data['id'] as String? ?? doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      brandId: data['brandId'] as String? ?? '',
      brandName: data['brandName'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      cityId: data['cityId'] as String? ?? '',
      cityName: data['cityName'] as String? ?? '',
      discountText: discount.discountText,
      discountType: discount.discountType,
      discountValue: discount.discountValue,
      imageUrl: data['imageUrl'] as String? ?? '',
      imageUrls: _readImageUrls(data),
      imageSliderAutoPlay: data['imageSliderAutoPlay'] as bool? ?? true,
      imageDisplayMode: data['imageDisplayMode'] as String? ?? 'carousel',
      sourceUrl: sourceUrl,
      onlineUrl: onlineUrl,
      linkSources: linkSources,
      shareUrl: AppConstants.offerShareUrl(doc.id),
      startDate: schedule.startDate,
      endDate: schedule.endDate,
      isVerified: data['isVerified'] as bool? ?? false,
      isPublished: data['isPublished'] as bool? ?? false,
      isFeatured: data['isFeatured'] as bool? ?? false,
      aiConfidence: data['aiConfidence'] as num?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: FirestoreValues.readDateOr(
        data['createdAt'],
        fallback: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      updatedAt: FirestoreValues.readDateOr(
        data['updatedAt'],
        fallback: DateTime.fromMillisecondsSinceEpoch(0),
      ),
      createdByUserId:
          data['createdByUserId'] as String? ??
          data['createdBy'] as String? ??
          '',
      createdByRole: data['createdByRole'] as String? ?? 'owner',
      status:
          data['status'] as String? ??
          ((data['isPublished'] as bool? ?? false) ? 'published' : 'draft'),
      approvalStatus:
          data['approvalStatus'] as String? ??
          ((data['isVerified'] as bool? ?? false) ? 'approved' : 'pending'),
      approvalNotes: data['approvalNotes'] as String? ?? '',
      approvedBy: data['approvedBy'] as String? ?? '',
      approvedAt: FirestoreValues.readDate(data['approvedAt']),
      categoryIds: FirestoreValues.readStringList(data['categoryIds']).isEmpty
          ? [
              data['categoryId'] as String? ?? '',
            ].where((id) => id.isNotEmpty).toList()
          : FirestoreValues.readStringList(data['categoryIds']),
      categoryNames:
          FirestoreValues.readStringList(data['categoryNames']).isEmpty
          ? [
              data['categoryName'] as String? ?? '',
            ].where((name) => name.isNotEmpty).toList()
          : FirestoreValues.readStringList(data['categoryNames']),
      cityIds: FirestoreValues.readStringList(data['cityIds']).isEmpty
          ? [
              data['cityId'] as String? ?? '',
            ].where((id) => id.isNotEmpty).toList()
          : FirestoreValues.readStringList(data['cityIds']),
      cityNames: FirestoreValues.readStringList(data['cityNames']).isEmpty
          ? [
              data['cityName'] as String? ?? '',
            ].where((name) => name.isNotEmpty).toList()
          : FirestoreValues.readStringList(data['cityNames']),
      viewCount: data['viewCount'] as int? ?? 0,
      saveCount: data['saveCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      clickCount: data['clickCount'] as int? ?? 0,
      reportCount: data['reportCount'] as int? ?? 0,
      offerLines: _readOfferLines(data),
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = true}) {
    final sources = BrandUrlSourceUtils.withStableIds(linkSources);
    final legacySource = BrandUrlSourceUtils.legacySourceUrl(sources);
    final legacyOnline = BrandUrlSourceUtils.legacyOnlineUrl(sources);
    return {
      'id': id,
      'title': title,
      'description': description,
      'brandId': brandId,
      'brandName': brandName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIds': categoryIds,
      'categoryNames': categoryNames,
      'cityId': cityId,
      'cityName': cityName,
      'cityIds': cityIds,
      'cityNames': cityNames,
      ...discount.toMap(),
      'imageUrl': imageUrl,
      'imageUrls': imageUrls.isEmpty
          ? [imageUrl].where((url) => url.isNotEmpty).toList()
          : imageUrls,
      'imageSliderAutoPlay': imageSliderAutoPlay,
      'imageDisplayMode': imageDisplayMode,
      'sourceUrl': legacySource.isNotEmpty ? legacySource : sourceUrl,
      'onlineUrl': legacyOnline.isNotEmpty ? legacyOnline : onlineUrl,
      'linkSources': sources.map((source) => source.toMap()).toList(),
      'shareUrl': shareUrl.isNotEmpty
          ? shareUrl
          : AppConstants.offerShareUrl(id),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isVerified': isVerified,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'aiConfidence': aiConfidence,
      'createdBy': createdBy,
      'createdByUserId': createdByUserId,
      'createdByRole': createdByRole,
      'status': status,
      'approvalStatus': approvalStatus,
      'approvalNotes': approvalNotes,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'viewCount': viewCount,
      'saveCount': saveCount,
      'shareCount': shareCount,
      'clickCount': clickCount,
      'reportCount': reportCount,
      'offerLines': offerLines.map((line) => line.toMap()).toList(),
      if (includeCreatedAt) 'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static List<OfferLine> _readOfferLines(Map<String, dynamic> data) {
    final raw = data['offerLines'];
    if (raw is! Iterable) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => OfferLine.fromMap(Map<String, dynamic>.from(item)))
        .where(
          (line) => line.categoryId.isNotEmpty || line.discountText.isNotEmpty,
        )
        .toList();
  }

  static List<String> _readImageUrls(Map<String, dynamic> data) {
    final urls = FirestoreValues.readStringList(data['imageUrls']);
    if (urls.isNotEmpty) {
      return urls;
    }
    final imageUrl = data['imageUrl'] as String? ?? '';
    return imageUrl.isEmpty ? const [] : [imageUrl];
  }

  static List<BrandUrlSource> _readLinkSources(Map<String, dynamic> data) {
    final fromArray = BrandUrlSourceUtils.readList(data['linkSources']);
    if (fromArray.isNotEmpty) {
      return fromArray;
    }
    return BrandUrlSourceUtils.fromLegacyFields(
      websiteUrl: data['onlineUrl'] as String? ?? '',
      instagramUrl: data['sourceUrl'] as String? ?? '',
    );
  }
}
