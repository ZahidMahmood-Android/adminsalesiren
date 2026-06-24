import '../../../brands/domain/entities/brand_url_source.dart';

class OfferLine {
  const OfferLine({
    required this.id,
    this.title = '',
    this.description = '',
    required this.categoryId,
    required this.categoryName,
    required this.discountText,
    required this.discountType,
    this.discountValue,
    this.imageUrl = '',
    this.imageUrls = const [],
    this.linkSources = const [],
    this.published = false,
    this.notificationRequestId = '',
  });

  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String discountText;
  final String discountType;
  final num? discountValue;
  final String imageUrl;
  final List<String> imageUrls;
  final List<BrandUrlSource> linkSources;
  final bool published;
  final String notificationRequestId;

  String displayTitle(String fallback) =>
      title.trim().isNotEmpty ? title.trim() : fallback;

  String displayDescription(String fallback) =>
      description.trim().isNotEmpty ? description.trim() : fallback;

  List<String> resolvedImageUrls() {
    if (imageUrls.isNotEmpty) {
      return imageUrls;
    }
    if (imageUrl.trim().isNotEmpty) {
      return [imageUrl];
    }
    return const [];
  }

  List<BrandUrlSource> resolvedLinkSources() {
    if (linkSources.isNotEmpty) {
      return BrandUrlSourceUtils.withStableIds(linkSources);
    }
    return const [];
  }

  OfferLine copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? discountText,
    String? discountType,
    num? discountValue,
    String? imageUrl,
    List<String>? imageUrls,
    List<BrandUrlSource>? linkSources,
    bool? published,
    String? notificationRequestId,
  }) {
    return OfferLine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      discountText: discountText ?? this.discountText,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      linkSources: linkSources ?? this.linkSources,
      published: published ?? this.published,
      notificationRequestId:
          notificationRequestId ?? this.notificationRequestId,
    );
  }

  Map<String, dynamic> toMap() {
    final sources = BrandUrlSourceUtils.withStableIds(linkSources);
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'discountText': discountText,
      'discountType': discountType,
      'discountValue': discountValue,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls.isEmpty
          ? [imageUrl].where((url) => url.isNotEmpty).toList()
          : imageUrls,
      'linkSources': sources.map((source) => source.toMap()).toList(),
      'published': published,
      'notificationRequestId': notificationRequestId,
    };
  }

  static OfferLine fromMap(Map<String, dynamic> map) {
    final imageUrls = _readImageUrls(map);
    final imageUrl = map['imageUrl'] as String? ?? '';
    return OfferLine(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      discountText: map['discountText'] as String? ?? '',
      discountType: map['discountType'] as String? ?? 'percentage',
      discountValue: map['discountValue'] as num?,
      imageUrl: imageUrl.isNotEmpty
          ? imageUrl
          : (imageUrls.isNotEmpty ? imageUrls.first : ''),
      imageUrls: imageUrls,
      linkSources: BrandUrlSourceUtils.readList(map['linkSources']),
      published: map['published'] as bool? ?? false,
      notificationRequestId: map['notificationRequestId'] as String? ?? '',
    );
  }

  static List<String> _readImageUrls(Map<String, dynamic> data) {
    final raw = data['imageUrls'];
    if (raw is Iterable) {
      return raw
          .map((item) => item?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
