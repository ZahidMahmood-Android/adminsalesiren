import 'package:flutter/material.dart';

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
    required this.imageUrl,
    required this.pickedImageName,
    required this.onPick,
    super.key,
  });

  final String imageUrl;
  final String? pickedImageName;
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 84,
                height: 64,
                child: imageUrl.isEmpty
                    ? ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined),
                      )
                    : Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                pickedImageName ??
                    (imageUrl.isEmpty ? 'No image selected' : 'Current image'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
