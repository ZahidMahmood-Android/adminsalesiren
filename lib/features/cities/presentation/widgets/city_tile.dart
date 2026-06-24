import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/city.dart';

class CityTile extends StatelessWidget {
  const CityTile({
    required this.city,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
    super.key,
  });

  final City city;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = city.isActive ? AppTheme.freshGreen : Colors.blueGrey;

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
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.location_city_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.title(
                  city.name,
                  fontWeight: FontWeight.w900,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.public,
                      label: city.countryName.isNotEmpty
                          ? city.countryName
                          : city.country,
                    ),
                    if (city.province.isNotEmpty)
                      _MetaChip(icon: Icons.map_outlined, label: city.province),
                    _MetaChip(icon: Icons.tag, label: city.id),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppBadge(
                      label: city.isActive ? 'Active' : 'Inactive',
                      color: city.isActive
                          ? AppTheme.deepGreen
                          : Colors.black45,
                    ),
                    if (city.isComingSoon)
                      const AppBadge(
                        label: 'Coming soon',
                        color: AppTheme.saffron,
                      ),
                    AppBadge(
                      label: 'Sort ${city.sortOrder}',
                      color: AppColors.textMuted(brightness),
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
                  tooltip: 'Edit city',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete city',
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
