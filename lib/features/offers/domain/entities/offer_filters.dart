class OfferFilters {
  const OfferFilters({
    this.cityId,
    this.categoryId,
    this.brandId,
    this.isPublished,
    this.isVerified,
  });

  final String? cityId;
  final String? categoryId;
  final String? brandId;
  final bool? isPublished;
  final bool? isVerified;

  bool get hasActiveFilters =>
      cityId != null ||
      categoryId != null ||
      brandId != null ||
      isPublished != null ||
      isVerified != null;

  OfferFilters copyWith({
    String? cityId,
    String? categoryId,
    String? brandId,
    bool? isPublished,
    bool? isVerified,
    bool clearCity = false,
    bool clearCategory = false,
    bool clearBrand = false,
    bool clearPublished = false,
    bool clearVerified = false,
  }) {
    return OfferFilters(
      cityId: clearCity ? null : cityId ?? this.cityId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      brandId: clearBrand ? null : brandId ?? this.brandId,
      isPublished: clearPublished ? null : isPublished ?? this.isPublished,
      isVerified: clearVerified ? null : isVerified ?? this.isVerified,
    );
  }
}
