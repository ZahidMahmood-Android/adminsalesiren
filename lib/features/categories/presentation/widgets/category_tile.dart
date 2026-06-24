import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/category.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
    super.key,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = _accentColor(category);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.24),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForName(category.iconName),
              color: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.title(
                  category.name,
                  fontWeight: FontWeight.w900,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppTextView.body(
                    category.description,
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
                    _MetaChip(icon: Icons.tag, label: category.id),
                    if (category.topic.isNotEmpty)
                      _MetaChip(
                        icon: Icons.notifications_outlined,
                        label: 'Alerts: ${category.name}',
                      ),
                    _MetaChip(
                      icon: Icons.sort,
                      label: 'Order ${category.sortOrder}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppBadge(
                      label: category.isActive ? 'Active' : 'Inactive',
                      color: category.isActive
                          ? AppTheme.deepGreen
                          : Colors.black45,
                    ),
                    if (category.isFeatured)
                      const AppBadge(label: 'Featured', color: AppTheme.coral),
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
                  tooltip: 'Edit category',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete category',
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

Color _accentColor(Category category) {
  final fromHex = _parseHexColor(category.colorHex);
  if (fromHex != null) {
    return fromHex;
  }
  return category.isActive ? AppTheme.saffron : Colors.blueGrey;
}

Color? _parseHexColor(String hex) {
  if (hex.trim().isEmpty) {
    return null;
  }
  final cleaned = hex.replaceFirst('#', '').trim();
  if (cleaned.length != 6) {
    return null;
  }
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) {
    return null;
  }
  return Color(0xFF000000 | value);
}

IconData _iconForName(String iconName) {
  switch (iconName) {
    case 'shopping_bag':
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'restaurant':
      return Icons.restaurant_outlined;
    case 'grocery':
      return Icons.local_grocery_store_outlined;
    case 'electronics':
      return Icons.devices_outlined;
    case 'fashion':
    case 'clothing':
      return Icons.checkroom_outlined;
    case 'beauty':
      return Icons.spa_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'sports':
      return Icons.sports_soccer_outlined;
    case 'kids':
      return Icons.child_care_outlined;
    case 'automotive':
      return Icons.directions_car_outlined;
    default:
      return Icons.category_outlined;
  }
}
