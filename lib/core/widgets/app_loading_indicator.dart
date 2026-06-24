import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Branded animated loader matching the mobile app loading indicator.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({this.size = 118, super.key});

  final double size;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glowColor = brightness == Brightness.dark
        ? AppColors.freshGreen
        : AppColors.deepGreen;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.5 + (math.sin(_controller.value * math.pi * 2) * 0.5);
        return Transform.scale(
          scale: 0.96 + (pulse * 0.06),
          child: CustomPaint(
            painter: _AppLoadingIndicatorPainter(
              progress: _controller.value,
              glowColor: glowColor,
              pulse: pulse,
            ),
            size: Size.square(widget.size),
          ),
        );
      },
    );
  }
}

class _AppLoadingIndicatorPainter extends CustomPainter {
  const _AppLoadingIndicatorPainter({
    required this.progress,
    required this.glowColor,
    required this.pulse,
  });

  final double progress;
  final Color glowColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.28 + pulse * 0.12),
          glowColor.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round
      ..color = glowColor.withValues(alpha: 0.16);
    canvas.drawCircle(center, radius * 0.58, basePaint);
    canvas.drawCircle(
      center,
      radius * 0.34,
      basePaint..strokeWidth = radius * 0.07,
    );

    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.58);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          glowColor.withValues(alpha: 0),
          AppTheme.saffron.withValues(alpha: 0.72),
          glowColor,
        ],
        stops: const [0.0, 0.55, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(arcRect);
    canvas.drawArc(
      arcRect,
      -math.pi / 2 + progress * math.pi * 2,
      math.pi * 1.3,
      false,
      arcPaint,
    );

    final dotAngle = -math.pi / 2 + progress * math.pi * 2;
    final dotOffset = Offset(
      math.cos(dotAngle) * radius * 0.58,
      math.sin(dotAngle) * radius * 0.58,
    );
    canvas.drawCircle(
      center + dotOffset,
      radius * 0.09,
      Paint()..color = AppTheme.saffron,
    );
  }

  @override
  bool shouldRepaint(covariant _AppLoadingIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.pulse != pulse;
  }
}
