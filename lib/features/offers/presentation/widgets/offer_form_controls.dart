import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_field_selector.dart';
import '../../domain/entities/offer_image_upload_task.dart';

class DropdownBox extends StatelessWidget {
  const DropdownBox({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 300, child: child);
  }
}

class DateButton extends StatelessWidget {
  const DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
    this.prefixIcon = Icons.calendar_month_outlined,
    this.width = 300,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? value;
  final VoidCallback onPressed;
  final IconData prefixIcon;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppFieldSelector(
      label: label,
      valueText: value ?? 'Select',
      prefixIcon: prefixIcon,
      width: width,
      enabled: enabled,
      onTap: onPressed,
    );
  }
}

class ImagePickerPanel extends StatelessWidget {
  const ImagePickerPanel({
    required this.imageUrls,
    required this.imageUploads,
    required this.onPick,
    this.onRetryUpload,
    this.onRemoveUpload,
    super.key,
  });

  final List<String> imageUrls;
  final List<OfferImageUploadTask> imageUploads;
  final VoidCallback onPick;
  final void Function(String taskId)? onRetryUpload;
  final void Function(String taskId)? onRemoveUpload;

  bool get _isUploading => imageUploads.any(
    (task) => task.status == OfferImageUploadStatus.uploading,
  );

  int get _activeCount => imageUploads.where((task) => task.isActive).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalItems = imageUrls.length + imageUploads.length;
    final hasItems = totalItems > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.04),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _isUploading
              ? colorScheme.primary.withValues(alpha: 0.45)
              : colorScheme.outline.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer images',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onPick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add images'),
                ),
              ],
            ),
            if (_isUploading) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Uploading $_activeCount image${_activeCount == 1 ? '' : 's'}…',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (hasItems) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...imageUrls.map((url) => _UploadedImageTile(imageUrl: url)),
                  ...imageUploads.map(
                    (task) => _UploadingImageTile(
                      task: task,
                      onRetry: onRetryUpload == null
                          ? null
                          : () => onRetryUpload!(task.id),
                      onRemove: onRemoveUpload == null
                          ? null
                          : () => onRemoveUpload!(task.id),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.25),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick images from your computer',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Images upload right away so saving is instant.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel() {
    if (_isUploading) {
      return 'Upload in progress — save unlocks when finished.';
    }
    if (imageUploads.any(
      (task) => task.status == OfferImageUploadStatus.failed,
    )) {
      return 'Some uploads failed. Retry or remove them to continue.';
    }
    if (imageUrls.isEmpty) {
      return 'At least one image is required.';
    }
    return '${imageUrls.length} uploaded image${imageUrls.length == 1 ? '' : 's'} ready.';
  }
}

class _UploadedImageTile extends StatelessWidget {
  const _UploadedImageTile({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadingImageTile extends StatelessWidget {
  const _UploadingImageTile({required this.task, this.onRetry, this.onRemove});

  final OfferImageUploadTask task;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFailed = task.status == OfferImageUploadStatus.failed;
    final isUploading =
        task.status == OfferImageUploadStatus.uploading ||
        task.status == OfferImageUploadStatus.queued;
    final borderColor = isFailed
        ? colorScheme.error
        : colorScheme.primary.withValues(alpha: 0.5);

    return SizedBox(
      width: 108,
      height: 108,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          color: colorScheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (task.file != null)
                FutureBuilder<Uint8List>(
                  future: task.file!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    }
                    return ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                )
              else
                ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (isUploading)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.42),
                  child: Center(
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: task.progress > 0 ? task.progress : null,
                            strokeWidth: 3,
                            color: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                          Text(
                            task.progress > 0
                                ? '${(task.progress * 100).round()}%'
                                : '…',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isFailed)
                ColoredBox(
                  color: colorScheme.error.withValues(alpha: 0.72),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(height: 6),
                      if (onRetry != null)
                        TextButton(
                          onPressed: onRetry,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              if (onRemove != null && !isUploading)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemove,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      task.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
