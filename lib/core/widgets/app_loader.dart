import 'package:flutter/material.dart';

import 'app_shimmer.dart';

/// Shimmer loading placeholder for page and section fetch states.
class AppLoader extends StatelessWidget {
  const AppLoader({this.size = 118, this.list = false, super.key});

  final double size;
  final bool list;

  @override
  Widget build(BuildContext context) {
    if (list) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.hasBoundedHeight) {
            return const AppListShimmer();
          }
          return const AppFormShimmer();
        },
      );
    }
    return const Center(child: AppFormShimmer());
  }
}
