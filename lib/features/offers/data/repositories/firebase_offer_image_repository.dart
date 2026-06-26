import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/services/app_logger.dart';
import '../../domain/repositories/offer_image_repository.dart';
import '../utils/offer_storage_utils.dart';

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
    void Function(double progress)? onProgress,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'offers/$offerId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    _log.info('Uploading offer image offerId=$offerId path=$path');
    try {
      final uploadTask = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: contentType),
      );
      if (onProgress != null) {
        await for (final snapshot in uploadTask.snapshotEvents) {
          final total = snapshot.totalBytes;
          if (total > 0) {
            onProgress(snapshot.bytesTransferred / total);
          }
        }
      }
      final task = await uploadTask.timeout(const Duration(seconds: 45));
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
    Iterable<String> additionalFolderIds = const [],
  }) async {
    _log.info('Deleting offer images offerId=$offerId');
    final folderIds = <String>{
      offerId,
      ...additionalFolderIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
    };
    final storagePaths = OfferStorageUtils.storagePathsForUrls(imageUrls);

    for (final path in storagePaths) {
      await _deleteRefSilently(_storage.ref(path), label: path);
    }

    for (final folderId in folderIds) {
      try {
        await _deleteStorageFolder(_storage.ref('offers/$folderId'));
      } catch (error, stackTrace) {
        _log.warning(
          'Failed to delete offer image folder offers/$folderId',
          error,
          stackTrace,
        );
      }
    }

    for (final url
        in imageUrls
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()) {
      await _deleteUrlSilently(url);
    }
  }

  Future<void> _deleteUrlSilently(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (error) {
      final path = OfferStorageUtils.pathFromFirebaseStorageUrl(url);
      if (path != null) {
        await _deleteRefSilently(_storage.ref(path), label: path);
        return;
      }
      _log.fine('Could not delete image url (may already be gone): $url');
    }
  }

  Future<void> _deleteRefSilently(Reference ref, {required String label}) async {
    try {
      await ref.delete();
    } catch (error) {
      _log.fine('Could not delete storage object $label (may already be gone)');
    }
  }

  Future<void> _deleteStorageFolder(Reference ref) async {
    const pageSize = 100;
    String? pageToken;
    do {
      final listResult = await ref.list(
        ListOptions(maxResults: pageSize, pageToken: pageToken),
      );
      for (final item in listResult.items) {
        await item.delete();
      }
      for (final prefix in listResult.prefixes) {
        await _deleteStorageFolder(prefix);
      }
      pageToken = listResult.nextPageToken;
    } while (pageToken != null);
  }
}
