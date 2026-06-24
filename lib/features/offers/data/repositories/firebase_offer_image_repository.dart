import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/offer_image_repository.dart';

class FirebaseOfferImageRepository implements OfferImageRepository {
  FirebaseOfferImageRepository(this._storage);

  final FirebaseStorage _storage;
  final _log = AppLogger.get('FirebaseOfferImageRepository');

  @override
  Future<String> uploadOfferImage({
    required String offerId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'offers/$offerId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    _log.info('Uploading offer image offerId=$offerId path=$path');
    try {
      final task = await ref
          .putData(
            Uint8List.fromList(bytes),
            SettableMetadata(contentType: contentType),
          )
          .timeout(const Duration(seconds: 45));
      final url = await task.ref.getDownloadURL().timeout(
        const Duration(seconds: 20),
      );
      _log.info('Uploaded offer image offerId=$offerId path=$path');
      return url;
    } catch (error, stackTrace) {
      _log.severe(
        'Offer image upload failed offerId=$offerId path=$path',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteImagesForOffer({
    required String offerId,
    Iterable<String> imageUrls = const [],
  }) async {
    _log.info('Deleting offer images offerId=$offerId');
    try {
      await _deleteStorageFolder(_storage.ref('offers/$offerId'));
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to delete offer image folder offerId=$offerId',
        error,
        stackTrace,
      );
    }

    for (final url in imageUrls
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (error) {
        _log.fine('Could not delete image url (may already be gone): $url');
      }
    }
  }

  Future<void> _deleteStorageFolder(Reference ref) async {
    final list = await ref.listAll();
    for (final item in list.items) {
      await item.delete();
    }
    for (final prefix in list.prefixes) {
      await _deleteStorageFolder(prefix);
    }
  }
}
