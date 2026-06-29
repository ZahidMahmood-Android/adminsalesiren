import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/offer_discovery_settings.dart';
import '../providers/discovered_offer_providers.dart';

class OfferDiscoveryScheduleCard extends ConsumerStatefulWidget {
  const OfferDiscoveryScheduleCard({super.key});

  @override
  ConsumerState<OfferDiscoveryScheduleCard> createState() =>
      _OfferDiscoveryScheduleCardState();
}

class _OfferDiscoveryScheduleCardState
    extends ConsumerState<OfferDiscoveryScheduleCard> {
  List<String> _draftTimes = OfferDiscoverySettings.defaults().scheduledTimes;
  bool _draftEnabled = true;
  var _hydrated = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(offerDiscoverySettingsProvider);
    final canManage = ref.watch(canManageOfferDiscoveryScheduleProvider);
    final saveState = ref.watch(offerDiscoverySettingsActionsProvider);

    return settingsAsync.when(
      loading: () => const AppCard(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Text('Could not load schedule: $error'),
      ),
      data: (settings) {
        if (!_hydrated) {
          _draftTimes = List<String>.from(settings.scheduledTimes);
          _draftEnabled = settings.autoDiscoveryEnabled;
          _hydrated = true;
        }

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.freshGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppTheme.freshGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextView.title(
                          'Automatic discovery schedule',
                          fontWeight: FontWeight.w800,
                        ),
                        AppTextView.body(
                          'Times are in ${settings.timeZone}. Runs every 15 minutes and matches these slots.',
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _draftEnabled,
                    onChanged: canManage && !saveState.isLoading
                        ? (value) => setState(() => _draftEnabled = value)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in _draftTimes)
                    InputChip(
                      label: Text(time),
                      onDeleted: canManage && _draftTimes.length > 1
                          ? () => setState(
                              () => _draftTimes = _draftTimes
                                  .where((item) => item != time)
                                  .toList(),
                            )
                          : null,
                    ),
                  if (canManage)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Add time'),
                      onPressed: saveState.isLoading ? null : _addTime,
                    ),
                ],
              ),
              if (canManage) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: saveState.isLoading ? null : _save,
                    icon: saveState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save schedule'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked == null) return;
    final value = OfferDiscoverySettings.fromTimeOfDay(
      picked.hour,
      picked.minute,
    );
    setState(() {
      if (!_draftTimes.contains(value)) {
        _draftTimes = [..._draftTimes, value]..sort();
      }
    });
  }

  Future<void> _save() async {
    final settings = OfferDiscoverySettings(
      timeZone: OfferDiscoverySettings.defaultTimeZone,
      scheduledTimes: _draftTimes,
      autoDiscoveryEnabled: _draftEnabled,
    );
    await ref
        .read(offerDiscoverySettingsActionsProvider.notifier)
        .save(settings);
  }
}
