import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/brand.dart';
import 'brand_logo_box.dart';

class BrandTile extends StatelessWidget {
  const BrandTile({
    required this.brand,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
    this.showDelete = true,
    super.key,
  });

  final Brand brand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = brand.isActive ? AppTheme.freshGreen : Colors.blueGrey;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandLogoBox(
            name: brand.name,
            logoUrl: brand.logoUrl,
            accent: accent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.title(
                  brand.name,
                  fontWeight: FontWeight.w900,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (brand.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppTextView.body(
                    brand.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.textMuted(brightness),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(icon: Icons.tag, label: brand.id),
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: '${brand.categoryIds.length} categories',
                    ),
                    _MetaChip(
                      icon: Icons.location_city_outlined,
                      label: '${brand.cityIds.length} cities',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppBadge(
                      label: brand.isActive ? 'Active' : 'Inactive',
                      color: brand.isActive
                          ? AppTheme.deepGreen
                          : Colors.black45,
                    ),
                    if (brand.isFeatured)
                      const AppBadge(label: 'Featured', color: AppTheme.coral),
                    if (brand.isVerified)
                      const AppBadge(
                        label: 'Verified',
                        color: AppTheme.freshGreen,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  tooltip: 'Edit brand',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (showDelete)
                  IconButton(
                    tooltip: 'Delete brand',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
