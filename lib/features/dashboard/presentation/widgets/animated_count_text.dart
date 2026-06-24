import 'package:flutter/material.dart';

class AnimatedCountText extends StatefulWidget {
  const AnimatedCountText({
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    super.key,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText> {
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value;
      _to = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$_from-$_to'),
      tween: Tween<double>(begin: _from.toDouble(), end: _to.toDouble()),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(value.round().toString(), style: widget.style);
      },
    );
  }
}
