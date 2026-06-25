import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_content.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile_material.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../../core/widgets/sweet_confirmation_dialog.dart';
import '../../../access/domain/feature_access_utils.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/analytics_stat_chart.dart';
import '../../../dashboard/presentation/widgets/animated_metric_card.dart';
import '../../domain/entities/bug_report.dart';
import '../providers/bug_report_providers.dart';

class BugReportsDashboardScreen extends ConsumerStatefulWidget {
  const BugReportsDashboardScreen({super.key});

  @override
  ConsumerState<BugReportsDashboardScreen> createState() =>
      _BugReportsDashboardScreenState();
}

class _BugReportsDashboardScreenState
    extends ConsumerState<BugReportsDashboardScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(bugReportsProvider);
    final actionState = ref.watch(bugReportActionsProvider);
    final user = ref.watch(currentUserProvider);
    final canSubmitBug =
        user != null && FeatureAccessUtils.canSubmitBugReport(user);

    return ScreenScaffold(
      title: 'Bug Reports',
      actions: [
        if (canSubmitBug)
          TextButton.icon(
            onPressed: () => context.push('/bug-reports/submit'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Report bug'),
          ),
      ],
      child: reportsAsync.when(
        data: (reports) {
          final filtered = _statusFilter == null
              ? reports
              : reports.where((r) => r.status == _statusFilter).toList();
          final newCount = reports.where((r) => r.status == 'new').length;
          final investigatingCount = reports
              .where((r) => r.status == 'investigating')
              .length;
          final resolvedCount = reports
              .where((r) => r.status == 'resolved')
              .length;
          final mobileCount = reports.where((r) => r.source == 'mobile').length;
          final adminCount = reports.where((r) => r.source == 'admin').length;

          return AnimatedContent(
            child: ListView(
              children: [
                Text(
                  'Track issues from mobile and admin users, then mark them resolved after fixes ship.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 980
                        ? 4
                        : constraints.maxWidth > 640
                        ? 2
                        : 1;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.55,
                      children: [
                        AnimatedMetricCard(
                          label: 'New',
                          value: newCount,
                          icon: Icons.fiber_new_rounded,
                          color: AppTheme.coral,
                          subtitle: 'Needs triage',
                        ),
                        AnimatedMetricCard(
                          label: 'Investigating',
                          value: investigatingCount,
                          icon: Icons.search_rounded,
                          color: AppTheme.saffron,
                          subtitle: 'In progress',
                        ),
                        AnimatedMetricCard(
                          label: 'Resolved',
                          value: resolvedCount,
                          icon: Icons.verified_rounded,
                          color: AppTheme.deepGreen,
                          subtitle: 'Fixed & closed',
                        ),
                        AnimatedMetricCard(
                          label: 'Total',
                          value: reports.length,
                          icon: Icons.bug_report_outlined,
                          color: AppColors.info,
                          subtitle: 'All time',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                AnalyticsStatChart(
                  title: 'Reports by status',
                  subtitle: 'Live breakdown of open vs resolved bugs',
                  segments: [
                    ChartSegment(
                      label: 'New',
                      value: newCount,
                      color: AppTheme.coral,
                    ),
                    ChartSegment(
                      label: 'Investigating',
                      value: investigatingCount,
                      color: AppTheme.saffron,
                    ),
                    ChartSegment(
                      label: 'Resolved',
                      value: resolvedCount,
                      color: AppTheme.deepGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AnalyticsStatChart(
                  title: 'Reports by source',
                  subtitle: 'Where bugs were reported from',
                  segments: [
                    ChartSegment(
                      label: 'Mobile app',
                      value: mobileCount,
                      color: AppColors.info,
                    ),
                    ChartSegment(
                      label: 'Admin panel',
                      value: adminCount,
                      color: AppTheme.coral,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    FilterChip(
                      label: const Text('New'),
                      selected: _statusFilter == 'new',
                      onSelected: (_) => setState(() => _statusFilter = 'new'),
                    ),
                    FilterChip(
                      label: const Text('Investigating'),
                      selected: _statusFilter == 'investigating',
                      onSelected: (_) =>
                          setState(() => _statusFilter = 'investigating'),
                    ),
                    FilterChip(
                      label: const Text('Resolved'),
                      selected: _statusFilter == 'resolved',
                      onSelected: (_) =>
                          setState(() => _statusFilter = 'resolved'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.bug_report_outlined,
                    title: 'No bug reports',
                    message:
                        'Reports from the mobile app and admin panel appear here.',
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final report = filtered[index];
                        return FadeIn(
                          delay: Duration(milliseconds: index * 24),
                          child: _BugReportTile(
                            report: report,
                            isBusy: actionState.isLoading,
                            onMarkResolved: () async {
                              final confirmed = await showSweetConfirmationDialog(
                                context: context,
                                title: 'Mark as resolved?',
                                message:
                                    'This will close the bug report after your fix is deployed.',
                                confirmLabel: 'Mark resolved',
                              );
                              if (!confirmed || !context.mounted) return;
                              await ref
                                  .read(bugReportActionsProvider.notifier)
                                  .markResolved(report.id);
                            },
                            onStatusChanged: (status) => ref
                                .read(bugReportActionsProvider.notifier)
                                .updateStatus(report.id, status),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

class _BugReportTile extends StatelessWidget {
  const _BugReportTile({
    required this.report,
    required this.isBusy,
    required this.onMarkResolved,
    required this.onStatusChanged,
  });

  final BugReport report;
  final bool isBusy;
  final VoidCallback onMarkResolved;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final reporter = [
      if (report.userName?.trim().isNotEmpty ?? false) report.userName!.trim(),
      if (report.userEmail?.trim().isNotEmpty ?? false)
        report.userEmail!.trim(),
    ].join(' · ');

    return AppListTileMaterial(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: _statusColor(report.status).withValues(alpha: 0.14),
          child: Icon(
            _categoryIcon(report.category),
            color: _statusColor(report.status),
          ),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              [
                report.details,
                if (reporter.isNotEmpty) reporter,
                '${report.source.toUpperCase()} · ${report.category}',
                if (report.appVersion != null) 'v${report.appVersion}',
                if (report.platform != null) report.platform!,
                report.createdAt.compactDateTime,
              ].where((line) => line.trim().isNotEmpty).join('\n'),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppStatusChip(status: report.status),
            DropdownButton<String>(
              value: report.status,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'new', child: Text('New')),
                DropdownMenuItem(
                  value: 'investigating',
                  child: Text('Investigating'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              ],
              onChanged: isBusy
                  ? null
                  : (value) {
                      if (value == null) return;
                      onStatusChanged(value);
                    },
            ),
            if (report.status != 'resolved')
              FilledButton.tonalIcon(
                onPressed: isBusy ? null : onMarkResolved,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Resolve'),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'resolved' => AppTheme.deepGreen,
      'investigating' => AppTheme.saffron,
      _ => AppTheme.coral,
    };
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'crash' => Icons.bug_report_rounded,
      'ui' => Icons.palette_outlined,
      'notifications' => Icons.notifications_active_outlined,
      'performance' => Icons.speed_rounded,
      _ => Icons.more_horiz_rounded,
    };
  }
}
