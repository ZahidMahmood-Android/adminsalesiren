import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/screen_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/mobile_alert_settings.dart';
import '../providers/app_settings_providers.dart';

class AlertSettingsScreen extends ConsumerStatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  ConsumerState<AlertSettingsScreen> createState() =>
      _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends ConsumerState<AlertSettingsScreen> {
  final _customLabelController = TextEditingController();
  final _customSlugController = TextEditingController();
  String? _formError;

  @override
  void dispose() {
    _customLabelController.dispose();
    _customSlugController.dispose();
    super.dispose();
  }

  Future<void> _persist(MobileAlertSettings settings) async {
    await ref
        .read(appSettingsActionsProvider.notifier)
        .saveMobileAlertSettings(settings);
  }

  Future<void> _toggleType(
    MobileAlertSettings settings,
    AlertTypeSetting type,
    bool enabled,
  ) async {
    final enabledCount = settings.types.where((item) => item.enabled).length;
    if (!enabled && enabledCount <= 1 && type.enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one alert category must stay enabled.'),
        ),
      );
      return;
    }
    final updated = settings.types
        .map(
          (item) => item.slug == type.slug ? item.copyWith(enabled: enabled) : item,
        )
        .toList();
    await _persist(MobileAlertSettings(types: updated));
  }

  Future<void> _resetDefaults() async {
    await _persist(MobileAlertSettings.defaults());
  }

  Future<void> _addCustomType(MobileAlertSettings settings) async {
    final label = _customLabelController.text.trim();
    final slug = normalizeAlertTypeSlug(
      _customSlugController.text.trim().isEmpty ? label : _customSlugController.text,
    );
    if (label.isEmpty) {
      setState(() => _formError = 'Enter a display name for the alert type.');
      return;
    }
    if (!isValidAlertTypeSlug(slug)) {
      setState(
        () => _formError =
            'Slug must be lowercase letters, numbers, and underscores (e.g. flash_sale).',
      );
      return;
    }
    if (settings.types.any((type) => type.slug == slug)) {
      setState(() => _formError = 'An alert type with this slug already exists.');
      return;
    }
    setState(() => _formError = null);
    final updated = [
      ...settings.types,
      AlertTypeSetting(slug: slug, label: label, enabled: true, builtIn: false),
    ];
    _customLabelController.clear();
    _customSlugController.clear();
    await _persist(MobileAlertSettings(types: updated));
  }

  Future<void> _removeCustomType(
    MobileAlertSettings settings,
    AlertTypeSetting type,
  ) async {
    if (type.builtIn) {
      return;
    }
    final updated =
        settings.types.where((item) => item.slug != type.slug).toList();
    await _persist(MobileAlertSettings(types: updated));
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = ref.watch(isOwnerProvider);
    if (!isOwner) {
      return const Center(child: Text('Only the platform owner can manage alert settings.'));
    }

    final settingsAsync = ref.watch(mobileAlertSettingsProvider);
    final actionsState = ref.watch(appSettingsActionsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, _) => Center(child: Text('Failed to load alert settings: $error')),
      data: (settings) {
        return SingleChildScrollView(
          padding: screenPadding(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Alert settings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: actionsState.isLoading ? null : _resetDefaults,
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Reset defaults'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which alert categories appear in the mobile Alerts tab and when publishing or editing offers. '
                  'Disabled types are hidden from the app. Auto-suggested types (price drop, update, etc.) only use enabled categories.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted(
                          Theme.of(context).colorScheme.brightness,
                        ),
                      ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${settings.enabledSlugs.length} of ${settings.types.length} enabled for mobile and offer notifications',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 16),
                      for (final type in settings.types) ...[
                        _AlertTypeRow(
                          type: type,
                          busy: actionsState.isLoading,
                          onEnabledChanged: (value) =>
                              _toggleType(settings, type, value),
                          onRemove: type.builtIn
                              ? null
                              : () => _removeCustomType(settings, type),
                        ),
                        if (type != settings.types.last)
                          const Divider(height: 20),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add custom alert type',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Custom types appear in the offer notification picker and mobile Alerts tab when enabled.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          hintText: 'Flash sale',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customSlugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug (optional)',
                          hintText: 'flash_sale',
                          prefixIcon: Icon(Icons.tag_outlined),
                          helperText: 'Leave blank to generate from the display name.',
                        ),
                      ),
                      if (_formError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _formError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: actionsState.isLoading
                              ? null
                              : () => _addCustomType(settings),
                          icon: const Icon(Icons.add_outlined),
                          label: const Text('Add alert type'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested defaults',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      const _SuggestionRow(
                        title: 'New offer',
                        detail: 'First-time publish without a strong discount signal.',
                      ),
                      const _SuggestionRow(
                        title: 'Price drop',
                        detail: 'Discount increases (e.g. 7% → 20% off) or new percentage deals.',
                      ),
                      const _SuggestionRow(
                        title: 'Price up',
                        detail: 'Discount decreases versus the previous published offer.',
                      ),
                      const _SuggestionRow(
                        title: 'Ending soon',
                        detail: 'Offer expires within 3 days.',
                      ),
                      const _SuggestionRow(
                        title: 'Update',
                        detail: 'Other meaningful edits (title, description, categories).',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertTypeRow extends StatelessWidget {
  const _AlertTypeRow({
    required this.type,
    required this.busy,
    required this.onEnabledChanged,
    this.onRemove,
  });

  final AlertTypeSetting type;
  final bool busy;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.slug,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  fontFamily: 'monospace',
                ),
              ),
              if (type.builtIn)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Built-in',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: type.enabled,
          onChanged: busy ? null : onEnabledChanged,
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remove custom type',
            onPressed: busy ? null : onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
