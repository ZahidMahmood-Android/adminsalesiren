import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for copy-to-clipboard operations
class CopyUtils {
  /// Copy text to clipboard and show a snackbar confirmation
  static void copyToClipboard(
    BuildContext context,
    String text, {
    String? label,
  }) {
    Clipboard.setData(ClipboardData(text: text))
        .then((_) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${label ?? 'Text'} copied to clipboard'),
              duration: const Duration(seconds: 2),
            ),
          );
        })
        .catchError((e) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Could not copy. Please select and copy manually.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        });
  }

  /// Open a dialog with copiable text
  static void showCopiableDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? copyLabel,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: GestureDetector(
          onTap: () => copyToClipboard(context, content, label: copyLabel),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => copyToClipboard(context, content),
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
