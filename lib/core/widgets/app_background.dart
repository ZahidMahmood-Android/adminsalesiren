import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Draws a subtle doodle pattern (circles, dots, arcs) as a non-interactive
/// decorative layer behind page content.
///
/// Wrap any [Scaffold] body or content area with this widget:
/// ```dart
/// AppBackground(child: ListView(...))
/// ```
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doodleColor = isDark
        ? AppColors.freshGreen.withOpacity(0.04)
        : AppColors.deepGreen.withOpacity(0.045);

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _DoodlePainter(doodleColor)),
          ),
        ),
        child,
      ],
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Fixed-seed deterministic layout so doodles don't jump on rebuild.
    final rng = math.Random(42);
    final w = size.width;
    final h = size.height;

    // ── Scattered hollow circles ────────────────────────────────────────
    for (var i = 0; i < 18; i++) {
      final cx = rng.nextDouble() * w;
      final cy = rng.nextDouble() * h;
      final r = 12.0 + rng.nextDouble() * 48;
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // ── Tiny filled dots ───────────────────────────────────────────────
    for (var i = 0; i < 30; i++) {
      final cx = rng.nextDouble() * w;
      final cy = rng.nextDouble() * h;
      canvas.drawCircle(Offset(cx, cy), 2.5, fillPaint);
    }

    // ── Small arcs / partial rings ─────────────────────────────────────
    for (var i = 0; i < 8; i++) {
      final cx = rng.nextDouble() * w;
      final cy = rng.nextDouble() * h;
      final r = 18.0 + rng.nextDouble() * 32;
      final startAngle = rng.nextDouble() * math.pi * 2;
      final sweepAngle = math.pi * 0.6 + rng.nextDouble() * math.pi * 0.8;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // ── Dashed "+" crosshairs ──────────────────────────────────────────
    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (var i = 0; i < 10; i++) {
      final cx = rng.nextDouble() * w;
      final cy = rng.nextDouble() * h;
      const half = 6.0;
      canvas.drawLine(Offset(cx - half, cy), Offset(cx + half, cy), dashPaint);
      canvas.drawLine(Offset(cx, cy - half), Offset(cx, cy + half), dashPaint);
    }

    // ── Hexagon outlines ───────────────────────────────────────────────
    for (var i = 0; i < 5; i++) {
      final cx = rng.nextDouble() * w;
      final cy = rng.nextDouble() * h;
      final r = 14.0 + rng.nextDouble() * 22;
      _drawHexagon(canvas, Offset(cx, cy), r, paint);
    }

    // ── Corner accent — large quarter-circle ───────────────────────────
    final accentPaint = Paint()
      ..color = color.withOpacity(color.opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: w * 0.38),
      0,
      math.pi / 2,
      false,
      accentPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w, h), radius: w * 0.30),
      math.pi,
      math.pi / 2,
      false,
      accentPaint,
    );
  }

  void _drawHexagon(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 6;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DoodlePainter oldDelegate) => oldDelegate.color != color;
}
