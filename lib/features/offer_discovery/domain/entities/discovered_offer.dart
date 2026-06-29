class DiscoveredOffer {
  const DiscoveredOffer({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.sourceType,
    required this.sourceUrl,
    required this.rawText,
    required this.suggestedTitle,
    required this.suggestedDescription,
    required this.suggestedDiscountText,
    this.suggestedDiscountType = '',
    this.suggestedDiscountValue,
    required this.suggestedCategoryCodes,
    required this.suggestedCityCodes,
    required this.imageUrl,
    required this.confidenceScore,
    required this.status,
    required this.convertedOfferId,
    required this.rejectionReason,
    required this.duplicateOfOfferId,
    required this.createdAt,
    required this.updatedAt,
    required this.checkedAt,
  });

  final String id;
  final String brandId;
  final String brandName;
  final String sourceType;
  final String sourceUrl;
  final String rawText;
  final String suggestedTitle;
  final String suggestedDescription;
  final String suggestedDiscountText;
  final String suggestedDiscountType;
  final int? suggestedDiscountValue;
  final List<String> suggestedCategoryCodes;
  final List<String> suggestedCityCodes;
  final String imageUrl;
  final double confidenceScore;
  final String status;
  final String convertedOfferId;
  final String rejectionReason;
  final String duplicateOfOfferId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? checkedAt;

  DiscoveredOffer copyWith({
    String? id,
    String? brandId,
    String? brandName,
    String? sourceType,
    String? sourceUrl,
    String? rawText,
    String? suggestedTitle,
    String? suggestedDescription,
    String? suggestedDiscountText,
    String? suggestedDiscountType,
    int? suggestedDiscountValue,
    List<String>? suggestedCategoryCodes,
    List<String>? suggestedCityCodes,
    String? imageUrl,
    double? confidenceScore,
    String? status,
    String? convertedOfferId,
    String? rejectionReason,
    String? duplicateOfOfferId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? checkedAt,
  }) {
    return DiscoveredOffer(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      sourceType: sourceType ?? this.sourceType,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      rawText: rawText ?? this.rawText,
      suggestedTitle: suggestedTitle ?? this.suggestedTitle,
      suggestedDescription: suggestedDescription ?? this.suggestedDescription,
      suggestedDiscountText:
          suggestedDiscountText ?? this.suggestedDiscountText,
      suggestedDiscountType:
          suggestedDiscountType ?? this.suggestedDiscountType,
      suggestedDiscountValue:
          suggestedDiscountValue ?? this.suggestedDiscountValue,
      suggestedCategoryCodes:
          suggestedCategoryCodes ?? this.suggestedCategoryCodes,
      suggestedCityCodes: suggestedCityCodes ?? this.suggestedCityCodes,
      imageUrl: imageUrl ?? this.imageUrl,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      status: status ?? this.status,
      convertedOfferId: convertedOfferId ?? this.convertedOfferId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      duplicateOfOfferId: duplicateOfOfferId ?? this.duplicateOfOfferId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}
