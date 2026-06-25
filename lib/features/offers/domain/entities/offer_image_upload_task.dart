import 'package:image_picker/image_picker.dart';

enum OfferImageUploadStatus { queued, uploading, completed, failed }

class OfferImageUploadTask {
  const OfferImageUploadTask({
    required this.id,
    required this.fileName,
    this.status = OfferImageUploadStatus.queued,
    this.progress = 0,
    this.downloadUrl,
    this.errorMessage,
    this.file,
  });

  final String id;
  final String fileName;
  final OfferImageUploadStatus status;
  final double progress;
  final String? downloadUrl;
  final String? errorMessage;
  final XFile? file;

  bool get isActive =>
      status == OfferImageUploadStatus.queued ||
      status == OfferImageUploadStatus.uploading;

  OfferImageUploadTask copyWith({
    String? id,
    String? fileName,
    OfferImageUploadStatus? status,
    double? progress,
    String? downloadUrl,
    String? errorMessage,
    XFile? file,
  }) {
    return OfferImageUploadTask(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      file: file ?? this.file,
    );
  }
}
