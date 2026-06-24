import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';

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
    super.key,
  });

  final String label;
  final String? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text('$label: ${value ?? 'Select'}'),
        ),
      ),
    );
  }
}

class ImagePickerPanel extends StatelessWidget {
  const ImagePickerPanel({
    required this.imageUrls,
    required this.pickedImageNames,
    required this.onPick,
    super.key,
  });

  final List<String> imageUrls;
  final List<String> pickedImageNames;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 72,
              child: imageUrls.isEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const AppNetworkImage(imageUrl: ''),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 84,
                          height: 64,
                          child: AppNetworkImage(imageUrl: imageUrls[index]),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                pickedImageNames.isNotEmpty
                    ? pickedImageNames.join(', ')
                    : (imageUrls.isEmpty
                          ? 'No images selected'
                          : '${imageUrls.length} current image${imageUrls.length == 1 ? '' : 's'}'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload images'),
            ),
          ],
        ),
      ),
    );
  }
}
