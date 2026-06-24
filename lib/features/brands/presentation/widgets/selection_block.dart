import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_inline_error.dart';
import '../../../../core/widgets/app_loader.dart';

class SelectionBlock<T> extends StatelessWidget {
  const SelectionBlock({
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.idOf,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final String title;
  final AsyncValue<List<T>> items;
  final Set<String> selectedIds;
  final String Function(T item) idOf;
  final String Function(T item) labelOf;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        items.when(
          data: (values) {
            if (values.isEmpty) {
              return const Text('No active records found.');
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((item) {
                final id = idOf(item);
                final selected = selectedIds.contains(id);
                return FilterChip(
                  label: Text(labelOf(item)),
                  selected: selected,
                  onSelected: (value) {
                    if (value) {
                      selectedIds.add(id);
                    } else {
                      selectedIds.remove(id);
                    }
                    onChanged();
                  },
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(height: 72, child: AppLoader(size: 56)),
          error: (error, _) => AppInlineError(error),
        ),
      ],
    );
  }
}
