import 'offer.dart';

class OfferFilters {
  const OfferFilters({
    this.cityId,
    this.categoryId,
    this.brandId,
    this.cityIds = const [],
    this.categoryIds = const [],
    this.brandIds = const [],
    this.isPublished,
    this.isVerified,
  });

  final String? cityId;
  final String? categoryId;
  final String? brandId;
  final List<String> cityIds;
  final List<String> categoryIds;
  final List<String> brandIds;
  final bool? isPublished;
  final bool? isVerified;

  bool get hasActiveFilters =>
      cityId != null ||
      categoryId != null ||
      brandId != null ||
      cityIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      brandIds.isNotEmpty ||
      isPublished != null ||
      isVerified != null;

  bool matchesOffer(Offer offer) {
    final cityFilters = {
      if (cityId != null && cityId!.isNotEmpty) cityId!,
      ...cityIds,
    };
    if (cityFilters.isNotEmpty &&
        !cityFilters.any(
          (id) => offer.cityId == id || offer.cityIds.contains(id),
        )) {
      return false;
    }
    final categoryFilters = {
      if (categoryId != null && categoryId!.isNotEmpty) categoryId!,
      ...categoryIds,
    };
    if (categoryFilters.isNotEmpty &&
        !categoryFilters.any(
          (id) => offer.categoryId == id || offer.categoryIds.contains(id),
        )) {
      return false;
    }
    final brandFilters = {
      if (brandId != null && brandId!.isNotEmpty) brandId!,
      ...brandIds,
    };
    if (brandFilters.isNotEmpty && !brandFilters.contains(offer.brandId)) {
      return false;
    }
    if (isPublished != null &&
        offer.isPublishedForListing != isPublished) {
      return false;
    }
    if (isVerified != null && offer.isVerified != isVerified) {
      return false;
    }
    return true;
  }

  List<Offer> applyTo(List<Offer> offers) =>
      offers.where(matchesOffer).toList();

  OfferFilters copyWith({
    String? cityId,
    String? categoryId,
    String? brandId,
    List<String>? cityIds,
    List<String>? categoryIds,
    List<String>? brandIds,
    bool? isPublished,
    bool? isVerified,
    bool clearCity = false,
    bool clearCategory = false,
    bool clearBrand = false,
    bool clearCities = false,
    bool clearCategories = false,
    bool clearBrands = false,
    bool clearPublished = false,
    bool clearVerified = false,
  }) {
    return OfferFilters(
      cityId: clearCity ? null : cityId ?? this.cityId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      brandId: clearBrand ? null : brandId ?? this.brandId,
      cityIds: clearCities ? const [] : cityIds ?? this.cityIds,
      categoryIds: clearCategories ? const [] : categoryIds ?? this.categoryIds,
      brandIds: clearBrands ? const [] : brandIds ?? this.brandIds,
      isPublished: clearPublished ? null : isPublished ?? this.isPublished,
      isVerified: clearVerified ? null : isVerified ?? this.isVerified,
    );
  }
}
