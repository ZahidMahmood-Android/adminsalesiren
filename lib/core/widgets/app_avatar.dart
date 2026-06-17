import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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
    required IconData icon,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  }) : name = '',
       imageUrl = null,
       _icon = icon;

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

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initial = name.isEmpty
        ? ''
        : name.trim().characters.first.toUpperCase();
    final fallback = _icon != null
        ? Icon(_icon, size: radius * 0.9, color: fg)
        : Text(
            initial,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: radius * 0.75,
            ),
          );

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: fallback),
              ),
            )
          : fallback,
    );
  }
}
