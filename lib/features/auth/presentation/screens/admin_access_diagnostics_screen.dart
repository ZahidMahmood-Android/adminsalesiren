import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/copy_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../providers/auth_providers.dart';

class AdminAccessDiagnosticsPage extends ConsumerWidget {
  const AdminAccessDiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final adminAccessAsync = ref.watch(adminAccessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access Diagnostics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Troubleshooting Information',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),

            // User Info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1️⃣ Your Account Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  userAsync.when(
                    data: (user) {
                      if (user == null) {
                        return const Text('❌ No user signed in');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Email',
                            value: user.email,
                            context: context,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'UID (User ID)',
                            value: user.id,
                            context: context,
                            isCopyable: true,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Display Name',
                            value: user.displayName,
                            context: context,
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const AppLoadingView(label: 'Loading user info'),
                    error: (error, _) => Text('❌ Error: $error'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Admin Access Status
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2️⃣ Admin Access Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  adminAccessAsync.when(
                    data: (hasAccess) {
                      if (hasAccess) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.deepGreen),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.deepGreen,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '✅ Admin access GRANTED',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.deepGreen,
                                      ),
                                    ),
                                    const Text(
                                      'The admins/{uid} document exists and rules are working.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.cancel, color: Colors.red),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      '❌ Admin access DENIED',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'The admins/{uid} document is missing or the rules are not deployed correctly.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    loading: () =>
                        const AppLoadingView(label: 'Checking admin access'),
                    error: (error, _) =>
                        Text('❌ Error checking access: $error'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Troubleshooting Steps
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3️⃣ Troubleshooting Checklist',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ChecklistItem(
                    title: 'Admin document exists in Firestore',
                    description:
                        'Check Firebase Console > Firestore > '
                        'Collections > admins > Your UID',
                  ),
                  const SizedBox(height: 12),
                  _ChecklistItem(
                    title: 'Document ID matches exactly',
                    description:
                        'Copy the UID from above and verify it matches '
                        'the Document ID in Firestore (case-sensitive)',
                  ),
                  const SizedBox(height: 12),
                  _ChecklistItem(
                    title: 'Security rules are deployed',
                    description:
                        'Run: firebase deploy --only firestore:rules,storage',
                  ),
                  const SizedBox(height: 12),
                  _ChecklistItem(
                    title: 'Clear browser cache',
                    description:
                        'Press Ctrl+Shift+Delete (or Cmd+Shift+Delete), '
                        'select "All time", and clear all data',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Fix
            userAsync.when(
              data: (user) {
                if (user == null) {
                  return const SizedBox.shrink();
                }
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '4️⃣ Quick Fix',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'If you haven\'t created the admin document yet:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () {
                          CopyUtils.showCopiableDialog(
                            context,
                            title: 'Create Admin Document',
                            content: user.id,
                            copyLabel: 'UID',
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('View & Copy Your UID'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Then follow these steps in Firebase Console:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '1. Go to Firestore Database\n'
                          '2. Click "Create collection"\n'
                          '3. Collection ID: admins\n'
                          '4. Document ID: [paste your UID]\n'
                          '5. Add field: email (string)\n'
                          '6. Add field: role (string) = "owner"\n'
                          '7. Save\n'
                          '8. Refresh this page',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refreshing admin access check...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 1), () {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh & Close'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.context,
    this.isCopyable = false,
  });

  final String label;
  final String value;
  final BuildContext context;
  final bool isCopyable;

  @override
  Widget build(BuildContext context) {
    final widget = Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        if (isCopyable)
          IconButton.filledTonal(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            iconSize: 16,
            onPressed: () {
              CopyUtils.copyToClipboard(context, value, label: label);
            },
            icon: const Icon(Icons.copy),
          ),
      ],
    );

    if (isCopyable) {
      return GestureDetector(
        onTap: () {
          CopyUtils.copyToClipboard(context, value, label: label);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: widget,
        ),
      );
    }

    return widget;
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_box_outline_blank,
          size: 20,
          color: Colors.black54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
