import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';

/// Centered branded loader used on list screens and heavy process states.
class AppLoader extends StatelessWidget {
  const AppLoader({this.size = 118, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLoadingIndicator(size: size));
  }
}
