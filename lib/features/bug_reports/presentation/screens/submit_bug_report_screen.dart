import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/bug_report_providers.dart';

class SubmitBugReportScreen extends ConsumerStatefulWidget {
  const SubmitBugReportScreen({super.key});

  @override
  ConsumerState<SubmitBugReportScreen> createState() =>
      _SubmitBugReportScreenState();
}

class _SubmitBugReportScreenState extends ConsumerState<SubmitBugReportScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  static const _categories = <String, IconData>{
    'crash': Icons.bug_report_rounded,
    'ui': Icons.palette_outlined,
    'notifications': Icons.notifications_active_outlined,
    'performance': Icons.speed_rounded,
    'other': Icons.more_horiz_rounded,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();
    if (title.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a summary and details.')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = ref.read(currentUserProfileProvider).value;

    ref.read(bugReportSubmittingProvider.notifier).setValue(true);
    try {
      await ref
          .read(bugReportsRepositoryProvider)
          .submitBugReport(
            userId: user.id,
            source: 'admin',
            category: ref.read(selectedAdminBugCategoryProvider),
            title: title,
            details: details,
            userEmail: user.email,
            userName: profile?.displayName,
            appVersion: 'admin-panel',
            platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (context.canPop()) {
        context.pop();
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Bug report submitted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send report: $error')));
    } finally {
      ref.read(bugReportSubmittingProvider.notifier).setValue(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(selectedAdminBugCategoryProvider);
    final submitting = ref.watch(bugReportSubmittingProvider);

    return AppLoadingOverlay(
      isLoading: submitting,
      child: SingleChildScrollView(
        padding: screenPadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepGreen.withValues(alpha: 0.92),
                        AppColors.coral.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report a bug',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Found something broken in the admin panel? Tell the owner team.',
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Issue type',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.entries.map((entry) {
                    final selected = category == entry.key;
                    return FilterChip(
                      selected: selected,
                      showCheckmark: false,
                      avatar: Icon(
                        entry.value,
                        size: 18,
                        color: selected ? Colors.white : AppColors.deepGreen,
                      ),
                      label: Text(_categoryLabel(entry.key)),
                      selectedColor: AppColors.deepGreen,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : null,
                      ),
                      onSelected: (_) => ref
                          .read(selectedAdminBugCategoryProvider.notifier)
                          .select(entry.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Short summary',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _detailsController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 96),
                      child: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: submitting ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: submitting ? null : _submit,
                      icon: AppAsyncButtonIcon(
                        isLoading: submitting,
                        icon: Icons.send_rounded,
                      ),
                      label: const Text('Send bug report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String key) {
    return switch (key) {
      'crash' => 'Crash',
      'ui' => 'UI / layout',
      'notifications' => 'Notifications',
      'performance' => 'Performance',
      _ => 'Other',
    };
  }
}
