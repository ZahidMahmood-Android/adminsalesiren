import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/report_providers.dart';

class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offer reports',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: reports.when(
              skipLoadingOnRefresh: true,
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No reports',
                    message:
                        'Expired or incorrect offer reports will appear here.',
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final report = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.paper,
                          child: Icon(
                            Icons.flag_outlined,
                            color: _statusColor(report.status),
                          ),
                        ),
                        title: Text(
                          report.reason,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          [
                            if (report.description.isNotEmpty)
                              report.description,
                            'Offer: ${report.offerId}',
                            report.createdAt.compactDateTime,
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppBadge(
                              label: report.status,
                              color: _statusColor(report.status),
                            ),
                            DropdownButton<String>(
                              value: report.status,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Pending'),
                                ),
                                DropdownMenuItem(
                                  value: 'reviewing',
                                  child: Text('Reviewing'),
                                ),
                                DropdownMenuItem(
                                  value: 'resolved',
                                  child: Text('Resolved'),
                                ),
                                DropdownMenuItem(
                                  value: 'dismissed',
                                  child: Text('Dismissed'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                ref
                                    .read(reportActionsProvider.notifier)
                                    .updateStatus(report.id, value);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const AppLoadingView(label: 'Loading reports'),
              error: (error, _) => AppErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(reportsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'resolved' => AppTheme.deepGreen,
      'reviewing' => AppTheme.saffron,
      'dismissed' => Colors.black45,
      _ => AppTheme.coral,
    };
  }
}
