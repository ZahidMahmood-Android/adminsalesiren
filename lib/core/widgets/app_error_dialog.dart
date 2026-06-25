import 'package:flutter/material.dart';

import '../errors/error_messages.dart';
import '../theme/app_theme.dart';

/// Shows a user-friendly [AlertDialog] for errors.
/// Prefer this over snackbars for action errors (save, delete, upload failures).
Future<void> showAppError(
  BuildContext context,
  Object? error, {
  String? title,
  String? message,
}) {
  final displayMessage = message ?? ErrorMessages.friendly(error);
  return showDialog<void>(
    context: context,
    builder: (ctx) =>
        AppErrorDialog(title: title ?? 'Error', message: displayMessage),
  );
}

/// Inline user-friendly error dialog.
class AppErrorDialog extends StatelessWidget {
  const AppErrorDialog({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.error_outline, size: 40, color: AppTheme.coral),
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Shows a transient success [SnackBar] with a tick icon.
/// Keep using snackbars for non-critical confirmations (e.g. "Saved", "Copied").
void showAppSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.deepGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

/// Shows a transient info/warning [SnackBar].
void showAppSnack(
  BuildContext context,
  String message, {
  Color? color,
  IconData? icon,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: color ?? AppTheme.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
