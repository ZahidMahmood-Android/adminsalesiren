import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../domain/entities/brand_usage.dart';
import '../providers/subscription_providers.dart';

class MyUsageScreen extends ConsumerWidget {
  const MyUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(brandUsageProvider);

    return ScreenScaffold(
      title: 'My Usage',
      child: AnimatedContent(
        child: usage.when(
          data: (List<BrandUsage> rows) {
            if (rows.isEmpty) {
              return const EmptyState(
                key: ValueKey('my-usage-empty'),
                icon: Icons.bar_chart_outlined,
                title: 'No usage yet',
                message: 'Usage appears when you create offers or requests.',
              );
            }
            return AppCard(
              key: const ValueKey('my-usage-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: AppListTileMaterial(
                      child: ListTile(
                      title: Text(
                        '${row.month}/${row.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Offers: ${row.offersCreated} · Push: ${row.pushNotificationsRequested} · '
                        'Featured: ${row.featuredOffersUsed} · Views: ${row.viewCount}',
                      ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const AppLoader(),
          error: (error, _) => AppErrorView(error: error),
        ),
      ),
    );
  }
}
