import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';

class ChartSegment {
  const ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class AnalyticsStatChart extends StatefulWidget {
  const AnalyticsStatChart({
    required this.title,
    required this.segments,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<ChartSegment> segments;

  @override
  State<AnalyticsStatChart> createState() => _AnalyticsStatChartState();
}

class _AnalyticsStatChartState extends State<AnalyticsStatChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(AnalyticsStatChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.segments.fold<int>(
      0,
      (sum, segment) => sum + segment.value,
    );
    final maxBar = widget.segments.fold<int>(
      1,
      (max, segment) => math.max(max, segment.value),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = math.min(constraints.maxWidth, 220.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(chartWidth, chartWidth),
                        painter: _DonutChartPainter(
                          segments: widget.segments,
                          progress: _controller.value,
                          total: total,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: widget.segments.map((segment) {
                        final factor = segment.value / maxBar;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: segment.color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      segment.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  AnimatedCountInChart(value: segment.value),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: factor),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return LinearProgressIndicator(
                                      value: value * _controller.value,
                                      minHeight: 8,
                                      backgroundColor: segment.color.withValues(
                                        alpha: 0.12,
                                      ),
                                      color: segment.color,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AnimatedCountInChart extends StatelessWidget {
  const AnimatedCountInChart({required this.value, super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) {
        return Text(
          animated.round().toString(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.segments,
    required this.progress,
    required this.total,
  });

  final List<ChartSegment> segments;
  final double progress;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = 22.0;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final background = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, background);

    if (total <= 0) {
      return;
    }

    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) {
        continue;
      }
      final sweep = (segment.value / total) * math.pi * 2 * progress;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.segments != segments;
  }
}
