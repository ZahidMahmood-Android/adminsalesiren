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
    required this.sourceUrl,
    required this.onlineUrl,
    required this.startDate,
    required this.endDate,
    required this.isVerified,
    required this.isPublished,
    required this.isFeatured,
    required this.aiConfidence,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
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
  final String sourceUrl;
  final String onlineUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isVerified;
  final bool isPublished;
  final bool isFeatured;
  final num? aiConfidence;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpired => endDate.isBefore(DateTime.now());

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
    String? sourceUrl,
    String? onlineUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool? isVerified,
    bool? isPublished,
    bool? isFeatured,
    num? aiConfidence,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      sourceUrl: sourceUrl ?? this.sourceUrl,
      onlineUrl: onlineUrl ?? this.onlineUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isVerified: isVerified ?? this.isVerified,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
