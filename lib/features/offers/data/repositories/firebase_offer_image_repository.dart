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
}
