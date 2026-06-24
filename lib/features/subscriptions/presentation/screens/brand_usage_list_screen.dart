import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../brands/domain/entities/brand.dart';
import '../../../brands/presentation/providers/brand_providers.dart';
import '../../domain/entities/brand_usage.dart';
import '../providers/subscription_providers.dart';

class BrandUsageListScreen extends ConsumerStatefulWidget {
  const BrandUsageListScreen({super.key});

  @override
  ConsumerState<BrandUsageListScreen> createState() =>
      _BrandUsageListScreenState();
}

class _BrandUsageListScreenState extends ConsumerState<BrandUsageListScreen> {
  String? _selectedBrandId;

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(brandUsageProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final brandsMap = brandsAsync.maybeWhen(
      data: (list) => {for (final b in list) b.id: b},
      orElse: () => <String, Brand>{},
    );

    return ScreenScaffold(
      title: 'Brand Usage',
      actions: [
        // Brand filter dropdown
        brandsAsync.maybeWhen(
          data: (brands) {
            final usedIds = usage.maybeWhen(
              data: (rows) => rows.map((r) => r.brandId).toSet(),
              orElse: () => <String>{},
            );
            final relevant =
                brands.where((b) => usedIds.contains(b.id)).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
            if (relevant.isEmpty) return const SizedBox.shrink();
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: DropdownButtonFormField<String?>(
                value: _selectedBrandId,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Filter by brand',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(child: Text('All brands')),
                  ...relevant.map(
                    (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedBrandId = v),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      child: AnimatedContent(
        child: usage.when(
          data: (List<BrandUsage> rows) {
            if (rows.isEmpty) {
              return const EmptyState(
                key: ValueKey('usage-empty'),
                icon: Icons.bar_chart_outlined,
                title: 'No usage records',
                message: 'Usage is tracked when brands create offers.',
              );
            }

            // Apply brand filter.
            final filtered = _selectedBrandId == null
                ? rows
                : rows.where((r) => r.brandId == _selectedBrandId).toList();

            if (filtered.isEmpty) {
              return const EmptyState(
                key: ValueKey('usage-filtered-empty'),
                icon: Icons.search_off_outlined,
                title: 'No records for this brand',
                message: 'Try selecting a different brand or clear the filter.',
              );
            }

            // Group by brandId → sorted months.
            final grouped = <String, List<BrandUsage>>{};
            for (final row in filtered) {
              grouped.putIfAbsent(row.brandId, () => []).add(row);
            }
            for (final list in grouped.values) {
              list.sort((a, b) {
                final yearCmp = b.year.compareTo(a.year);
                return yearCmp != 0 ? yearCmp : b.month.compareTo(a.month);
              });
            }
            final sortedBrands = grouped.keys.toList()..sort();

            return ListView.builder(
              key: const ValueKey('usage-list'),
              itemCount: sortedBrands.length,
              itemBuilder: (context, index) {
                final brandId = sortedBrands[index];
                final brandName = brandsMap[brandId]?.name ?? brandId;
                final logoUrl = brandsMap[brandId]?.logoUrl ?? '';
                final brandRows = grouped[brandId]!;

                return FadeIn(
                  delay: Duration(milliseconds: index * 40),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand header row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            children: [
                              // Logo or avatar
                              AppAvatar(
                                name: brandName,
                                imageUrl: logoUrl,
                                radius: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppTextView.title(
                                      brandName,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    AppTextView.label(
                                      brandId,
                                      color: AppColors.textMuted(
                                        Theme.of(
                                          context,
                                        ).colorScheme.brightness,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              AppTextView.label(
                                '${brandRows.length} month(s)',
                                color: AppColors.textMuted(
                                  Theme.of(context).colorScheme.brightness,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // Monthly rows
                        ...brandRows.map((row) => _MonthRow(row: row)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const AppLoader(),
          error: (error, _) => AppErrorView(error: error),
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.row});

  final BrandUsage row;

  static const _months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final monthLabel = row.month >= 1 && row.month <= 12
        ? '${_months[row.month]} ${row.year}'
        : '${row.month}/${row.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.label(
            monthLabel,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted(
              Theme.of(context).colorScheme.brightness,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _Stat('Offers', row.offersCreated, Icons.local_offer_outlined),
              _Stat('Active', row.activeOffers, Icons.check_circle_outline),
              _Stat(
                'Push',
                row.pushNotificationsRequested,
                Icons.notifications_outlined,
              ),
              _Stat('Featured', row.featuredOffersUsed, Icons.star_outline),
              if (row.viewCount > 0)
                _Stat('Views', row.viewCount, Icons.visibility_outlined),
              if (row.clickCount > 0)
                _Stat('Clicks', row.clickCount, Icons.touch_app_outlined),
            ],
          ),
          if (row != row) const Divider(height: 1),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textMuted(Theme.of(context).colorScheme.brightness),
        ),
        const SizedBox(width: 4),
        AppTextView.label('$label: $value'),
      ],
    );
  }
}
