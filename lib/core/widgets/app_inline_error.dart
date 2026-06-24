import 'package:flutter/material.dart';

import '../errors/error_messages.dart';

/// Compact inline error text for form sections and dropdown loaders.
class AppInlineError extends StatelessWidget {
  const AppInlineError(this.error, {super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Text(
      ErrorMessages.friendly(error),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
