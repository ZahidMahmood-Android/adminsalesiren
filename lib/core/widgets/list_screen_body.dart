import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_view.dart';
import 'app_loader.dart';

class ListScreenBody<T> extends StatelessWidget {
  const ListScreenBody({
    required this.asyncValue,
    required this.builder,
    this.onRetry,
    this.skipLoadingOnReload = true,
    this.skipLoadingOnRefresh = true,
    super.key,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final bool skipLoadingOnReload;
  final bool skipLoadingOnRefresh;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      skipLoadingOnReload: skipLoadingOnReload,
      loading: () => const AppLoader(),
      error: (error, _) => AppErrorView(error: error, onRetry: onRetry),
      data: builder,
    );
  }
}
