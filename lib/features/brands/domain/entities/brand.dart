import 'brand_url_source.dart';

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.websiteUrl,
    required this.instagramUrl,
    required this.facebookUrl,
    required this.categoryIds,
    required this.cityIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.urlSources = const [],
    this.slug = '',
    this.topic = '',
    this.description = '',
    this.primaryCategoryId = '',
    this.type = 'brand',
    this.isVerified = true,
    this.isFeatured = false,
    this.sortOrder = 0,
    this.searchKeywords = const [],
    this.businessContactName = '',
    this.businessContactPhone = '',
    this.businessContactEmail = '',
    this.marketingEmail = '',
    this.address = '',
    this.approvalStatus = 'approved',
    this.ownerUserIds = const [],
    this.createdByAdminId = '',
    this.userId = '',
  });

  final String id;
  final String name;
  final String logoUrl;
  final String websiteUrl;
  final String instagramUrl;
  final String facebookUrl;
  final List<BrandUrlSource> urlSources;
  final List<String> categoryIds;
  final List<String> cityIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String slug;
  final String topic;
  final String description;
  final String primaryCategoryId;
  final String type;
  final bool isVerified;
  final bool isFeatured;
  final int sortOrder;
  final List<String> searchKeywords;
  final String businessContactName;
  final String businessContactPhone;
  final String businessContactEmail;
  final String marketingEmail;
  final String address;
  final String approvalStatus;
  final List<String> ownerUserIds;
  final String createdByAdminId;
  final String userId;

  Brand copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? websiteUrl,
    String? instagramUrl,
    String? facebookUrl,
    List<BrandUrlSource>? urlSources,
    List<String>? categoryIds,
    List<String>? cityIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? slug,
    String? topic,
    String? description,
    String? primaryCategoryId,
    String? type,
    bool? isVerified,
    bool? isFeatured,
    int? sortOrder,
    List<String>? searchKeywords,
    String? businessContactName,
    String? businessContactPhone,
    String? businessContactEmail,
    String? marketingEmail,
    String? address,
    String? approvalStatus,
    List<String>? ownerUserIds,
    String? createdByAdminId,
    String? userId,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      urlSources: urlSources ?? this.urlSources,
      categoryIds: categoryIds ?? this.categoryIds,
      cityIds: cityIds ?? this.cityIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      primaryCategoryId: primaryCategoryId ?? this.primaryCategoryId,
      type: type ?? this.type,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      businessContactName: businessContactName ?? this.businessContactName,
      businessContactPhone: businessContactPhone ?? this.businessContactPhone,
      businessContactEmail: businessContactEmail ?? this.businessContactEmail,
      marketingEmail: marketingEmail ?? this.marketingEmail,
      address: address ?? this.address,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      ownerUserIds: ownerUserIds ?? this.ownerUserIds,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      userId: userId ?? this.userId,
    );
  }
}
