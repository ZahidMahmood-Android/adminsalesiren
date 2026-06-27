import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Rounded brand thumbnail: bordered logo when [logoUrl] loads; gradient tile +
/// storefront icon when URL is missing or fails.
class BrandLogoBox extends StatefulWidget {
  const BrandLogoBox({
    required this.name,
    this.logoUrl,
    this.size = 56,
    this.borderRadius = 14,
    this.accent,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String name;
  final String? logoUrl;
  final double size;
  final double borderRadius;
  final Color? accent;
  final BoxFit fit;

  @override
  State<BrandLogoBox> createState() => _BrandLogoBoxState();
}

class _BrandLogoBoxState extends State<BrandLogoBox> {
  var _loadFailed = false;

  @override
  void didUpdateWidget(covariant BrandLogoBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoUrl?.trim() != widget.logoUrl?.trim()) {
      _loadFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.logoUrl?.trim() ?? '';
    if (url.isEmpty || _loadFailed) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: _BrandLogoFallback(
            accent: widget.accent,
            icon: Icons.storefront_outlined,
          ),
        ),
      );
    }

    final brightness = Theme.of(context).brightness;
    final borderColor = AppColors.border(brightness).withValues(alpha: 0.65);
    final innerRadius = widget.borderRadius > 1
        ? widget.borderRadius - 1
        : widget.borderRadius;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Image.network(
            url,
            fit: widget.fit,
            alignment: Alignment.center,
            width: widget.size,
            height: widget.size,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loadFailed) {
                  setState(() => _loadFailed = true);
                }
              });
              return const SizedBox.shrink();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _BrandLogoFallback extends StatelessWidget {
  const _BrandLogoFallback({
    required this.icon,
    this.accent,
    this.child,
  });

  final IconData icon;
  final Color? accent;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppTheme.freshGreen;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child:
            child ??
            Icon(icon, size: 28, color: color.withValues(alpha: 0.9)),
      ),
    );
  }
}
