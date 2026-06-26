import '../../domain/entities/offer.dart';

class OfferStorageUtils {
  OfferStorageUtils._();

  static Set<String> collectImageUrls(Offer offer) {
    final urls = <String>{};
    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        urls.add(trimmed);
      }
    }

    add(offer.imageUrl);
    for (final url in offer.imageUrls) {
      add(url);
    }
    for (final line in offer.resolvedLines) {
      for (final url in line.resolvedImageUrls()) {
        add(url);
      }
    }
    return urls;
  }

  static Set<String> storageFolderIds(Offer offer) {
    final ids = <String>{offer.id};
    for (final line in offer.resolvedLines) {
      if (line.id.trim().isNotEmpty) {
        ids.add(line.id.trim());
      }
    }
    return ids;
  }

  static String? pathFromFirebaseStorageUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      const marker = '/o/';
      final markerIndex = uri.path.indexOf(marker);
      if (markerIndex < 0) {
        return null;
      }
      final encodedPath = uri.path.substring(markerIndex + marker.length);
      final path = Uri.decodeComponent(encodedPath);
      return path.isEmpty ? null : path;
    } catch (_) {
      return null;
    }
  }

  static Set<String> storagePathsForUrls(Iterable<String> imageUrls) {
    final paths = <String>{};
    for (final url in imageUrls) {
      final path = pathFromFirebaseStorageUrl(url);
      if (path != null) {
        paths.add(path);
      }
    }
    return paths;
  }
}
