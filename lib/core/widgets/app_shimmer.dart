import 'package:flutter/material.dart';

/// Animated shimmer highlight used for loading placeholders.
class AppShimmer extends StatefulWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + (_controller.value * 2), 0),
              end: Alignment(_controller.value * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class AppListShimmer extends StatelessWidget {
  const AppListShimmer({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _ShimmerListTile(),
    );
  }
}

class AppFormShimmer extends StatelessWidget {
  const AppFormShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              AppShimmerBox(height: 28, width: 220),
              SizedBox(height: 24),
              AppShimmerBox(height: 52),
              SizedBox(height: 16),
              AppShimmerBox(height: 52),
              SizedBox(height: 16),
              AppShimmerBox(height: 52),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: AppShimmerBox(height: 52)),
                  SizedBox(width: 16),
                  Expanded(child: AppShimmerBox(height: 52)),
                ],
              ),
              SizedBox(height: 24),
              AppShimmerBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class AppPageShimmer extends StatelessWidget {
  const AppPageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppShimmerBox(height: 32, width: 240),
          SizedBox(height: 20),
          Expanded(child: AppListShimmer(itemCount: 6)),
        ],
      ),
    );
  }
}

class _ShimmerListTile extends StatelessWidget {
  const _ShimmerListTile();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        AppShimmerBox(width: 48, height: 48, borderRadius: 12),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmerBox(height: 14),
              SizedBox(height: 8),
              AppShimmerBox(height: 12, width: 180),
            ],
          ),
        ),
      ],
    );
  }
}
