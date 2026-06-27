import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_network_image.dart';

/// A circular avatar that shows a network image when [imageUrl] is provided,
/// or falls back to the first letter of [name] on the brand-green background.
///
/// Usage:
/// ```dart
/// AppAvatar(name: 'Burger King', imageUrl: brand.logoUrl, radius: 22)
/// AppAvatar.icon(icon: Icons.person)
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  }) : _icon = null;

  const AppAvatar.icon({
    super.key,
    required IconData this._icon,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  }) : name = '',
       imageUrl = null;

  final String name;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? _icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.greenTint);
    final fg =
        foregroundColor ?? (isDark ? AppColors.freshGreen : AppTheme.deepGreen);
    final size = radius * 2;
    final fallback = _buildFallback(fg);

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: AppNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              icon: Icons.storefront_outlined,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(radius: radius, backgroundColor: bg, child: fallback);
  }

  Widget _buildFallback(Color fg) {
    final initial = name.isEmpty
        ? ''
        : name.trim().characters.first.toUpperCase();
    if (_icon != null) {
      return Icon(_icon, size: radius * 0.9, color: fg);
    }
    return Text(
      initial,
      style: TextStyle(
        color: fg,
        fontWeight: FontWeight.w900,
        fontSize: radius * 0.75,
      ),
    );
  }
}
