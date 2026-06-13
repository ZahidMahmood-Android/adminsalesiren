import 'dart:async';

import 'package:flutter/material.dart';

class AppLoadingView extends StatefulWidget {
  const AppLoadingView({
    super.key,
    this.label = 'Loading',
    this.delay = const Duration(milliseconds: 250),
  });

  final String label;
  final Duration delay;

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView> {
  var _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
