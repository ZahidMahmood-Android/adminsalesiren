class BrandUrlSource {
  const BrandUrlSource({
    required this.id,
    required this.name,
    required this.url,
  });

  final String id;
  final String name;
  final String url;

  bool get hasUrl => url.trim().isNotEmpty;

  BrandUrlSource copyWith({String? id, String? name, String? url}) {
    return BrandUrlSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'url': url.trim()};
  }

  static BrandUrlSource fromMap(Map<String, dynamic> map) {
    return BrandUrlSource(
      id: map['id'] as String? ?? newId(),
      name: map['name'] as String? ?? 'Link',
      url: map['url'] as String? ?? '',
    );
  }

  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  static const websiteId = 'website';
  static const instagramId = 'instagram';
  static const facebookId = 'facebook';

  static List<BrandUrlSource> defaultTemplates({
    String websiteUrl = '',
    String instagramUrl = '',
    String facebookUrl = '',
  }) {
    return [
      BrandUrlSource(id: websiteId, name: 'Website', url: websiteUrl),
      BrandUrlSource(id: instagramId, name: 'Instagram', url: instagramUrl),
      BrandUrlSource(id: facebookId, name: 'Facebook', url: facebookUrl),
    ];
  }
}

class BrandUrlSourceUtils {
  const BrandUrlSourceUtils._();

  static List<BrandUrlSource> readList(Object? raw) {
    if (raw is! Iterable) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => BrandUrlSource.fromMap(Map<String, dynamic>.from(item)))
        .where((source) => source.name.trim().isNotEmpty)
        .toList();
  }

  static List<BrandUrlSource> fromLegacyFields({
    String websiteUrl = '',
    String instagramUrl = '',
    String facebookUrl = '',
  }) {
    return BrandUrlSource.defaultTemplates(
      websiteUrl: websiteUrl,
      instagramUrl: instagramUrl,
      facebookUrl: facebookUrl,
    );
  }

  static List<BrandUrlSource> readFromBrandData(Map<String, dynamic> data) {
    final fromArray = readList(data['urlSources']);
    if (fromArray.isNotEmpty) {
      return fromArray;
    }
    return fromLegacyFields(
      websiteUrl: data['websiteUrl'] as String? ?? '',
      instagramUrl: data['instagramUrl'] as String? ?? '',
      facebookUrl: data['facebookUrl'] as String? ?? '',
    );
  }

  static List<BrandUrlSource> withStableIds(List<BrandUrlSource> sources) {
    return sources
        .map(
          (source) => source.id.trim().isEmpty
              ? source.copyWith(id: BrandUrlSource.newId())
              : source,
        )
        .toList();
  }

  static String? urlForId(List<BrandUrlSource> sources, String id) {
    for (final source in sources) {
      if (source.id == id && source.hasUrl) {
        return source.url.trim();
      }
    }
    return null;
  }

  static String? urlMatchingName(List<BrandUrlSource> sources, String needle) {
    final lower = needle.toLowerCase();
    for (final source in sources) {
      if (source.name.toLowerCase().contains(lower) && source.hasUrl) {
        return source.url.trim();
      }
    }
    return null;
  }

  static String legacySourceUrl(List<BrandUrlSource> sources) {
    return urlForId(sources, BrandUrlSource.instagramId) ??
        urlMatchingName(sources, 'instagram') ??
        '';
  }

  static String legacyOnlineUrl(List<BrandUrlSource> sources) {
    return urlForId(sources, BrandUrlSource.websiteId) ??
        urlMatchingName(sources, 'website') ??
        '';
  }

  static void syncLegacyBrandFields(List<BrandUrlSource> sources) {
    // Legacy fields are written explicitly in BrandModel.toFirestore.
  }

  static String websiteUrl(List<BrandUrlSource> sources) =>
      legacyOnlineUrl(sources);

  static String instagramUrl(List<BrandUrlSource> sources) =>
      legacySourceUrl(sources);

  static String facebookUrl(List<BrandUrlSource> sources) =>
      urlForId(sources, BrandUrlSource.facebookId) ??
      urlMatchingName(sources, 'facebook') ??
      '';

  static List<BrandUrlSource> activeSources(List<BrandUrlSource> sources) {
    return sources.where((source) => source.hasUrl).toList();
  }

  static List<BrandUrlSource> copyList(List<BrandUrlSource> sources) {
    return sources.map((source) => source.copyWith()).toList();
  }
}
