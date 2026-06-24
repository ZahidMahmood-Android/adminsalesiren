import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../roles/presentation/providers/role_providers.dart';

class UserRolesField extends ConsumerWidget {
  const UserRolesField({
    required this.selectedRoleIds,
    required this.onChanged,
    super.key,
  });

  final Set<String> selectedRoleIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(assignableRolesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Roles',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Select one or more roles for this user.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final selected = selectedRoleIds.contains(role.id);
            return FilterChip(
              label: Text(role.name),
              selected: selected,
              tooltip: role.description.isEmpty ? role.name : role.description,
              onSelected: (value) {
                final next = {...selectedRoleIds};
                if (value) {
                  next.add(role.id);
                } else {
                  next.remove(role.id);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
        if (selectedRoleIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Select at least one role.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
