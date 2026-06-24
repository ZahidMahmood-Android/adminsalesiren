import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_feature.dart';
import '../providers/app_feature_providers.dart';

class UserFeaturesField extends ConsumerWidget {
  const UserFeaturesField({
    required this.selectedFeatureIds,
    required this.onChanged,
    this.onApplyRoleDefaults,
    super.key,
  });

  final Set<String> selectedFeatureIds;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback? onApplyRoleDefaults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(appFeaturesCatalogProvider).value ?? const [];

    final adminFeatures = features
        .where((feature) => feature.isAdminPanel)
        .toList();
    final mobileFeatures = features
        .where((feature) => feature.isMobileApp)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Feature access',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (onApplyRoleDefaults != null)
              TextButton.icon(
                onPressed: onApplyRoleDefaults,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Use role defaults'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose what this user can see in the admin panel and mobile app.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        if (adminFeatures.isNotEmpty)
          _FeatureGroup(
            title: 'Admin panel',
            features: adminFeatures,
            selectedFeatureIds: selectedFeatureIds,
            onChanged: onChanged,
          ),
        if (adminFeatures.isNotEmpty && mobileFeatures.isNotEmpty)
          const SizedBox(height: 16),
        if (mobileFeatures.isNotEmpty)
          _FeatureGroup(
            title: 'Mobile app',
            features: mobileFeatures,
            selectedFeatureIds: selectedFeatureIds,
            onChanged: onChanged,
          ),
        if (selectedFeatureIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Select at least one feature.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({
    required this.title,
    required this.features,
    required this.selectedFeatureIds,
    required this.onChanged,
  });

  final String title;
  final List<AppFeature> features;
  final Set<String> selectedFeatureIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features.map((feature) {
            final selected = selectedFeatureIds.contains(feature.id);
            return FilterChip(
              label: Text(feature.name),
              selected: selected,
              tooltip: feature.description.isEmpty
                  ? feature.name
                  : feature.description,
              onSelected: (value) {
                final next = {...selectedFeatureIds};
                if (value) {
                  next.add(feature.id);
                } else {
                  next.remove(feature.id);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

void syncUserFeaturesWithRoles({
  required Set<String> selectedRoleIds,
  required Set<String> currentFeatureIds,
  required void Function(Set<String> featureIds) apply,
}) {
  apply(defaultFeatureIdsForRoles(selectedRoleIds));
}
