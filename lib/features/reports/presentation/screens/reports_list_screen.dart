import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../providers/report_providers.dart';

class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);

    return ScreenScaffold(
      header: const ScreenHeader(title: 'Offer Reports'),
      child: AnimatedContent(
        child: reports.when(
          skipLoadingOnRefresh: true,
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                key: ValueKey('reports-empty'),
                icon: Icons.flag_outlined,
                title: 'No reports',
                message: 'Expired or incorrect offer reports will appear here.',
              );
            }
            return AppCard(
              key: const ValueKey('reports-list'),
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final report = items[index];
                  return FadeIn(
                    delay: Duration(milliseconds: index * 30),
                    child: ListTile(
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
                          if (report.description.isNotEmpty) report.description,
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
                              if (value == null) return;
                              ref
                                  .read(reportActionsProvider.notifier)
                                  .updateStatus(report.id, value);
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete report',
                            onPressed: () async {
                              final confirmed = await showSweetConfirmationDialog(
                                context: context,
                                title: 'Delete report?',
                                message:
                                    'This report record will be removed permanently.',
                                confirmLabel: 'Delete',
                              );
                              if (!confirmed || !context.mounted) return;
                              await ref
                                  .read(reportActionsProvider.notifier)
                                  .delete(report.id);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
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
