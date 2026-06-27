import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/app_error_dialog.dart';

Future<bool> completeDeleteAction(
  BuildContext context,
  AsyncValue<void> actionState, {
  String errorTitle = 'Could Not Delete',
}) async {
  if (!actionState.hasError) {
    return true;
  }
  if (context.mounted) {
    await showAppError(context, actionState.error, title: errorTitle);
  }
  return false;
}
