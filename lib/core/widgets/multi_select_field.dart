import 'package:flutter/material.dart';

import 'app_list_tile_material.dart';

class MultiSelectOption {
  const MultiSelectOption({required this.id, required this.label});

  final String id;
  final String label;
}

class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    this.width = 260,
    this.emptyLabel = 'Any',
    super.key,
  });

  final String label;
  final List<MultiSelectOption> options;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final double width;
  final String emptyLabel;

  String _summary() {
    if (selectedIds.isEmpty) {
      return emptyLabel;
    }
    final labels = options
        .where((option) => selectedIds.contains(option.id))
        .map((option) => option.label)
        .toList();
    if (labels.length == 1) {
      return labels.first;
    }
    return '${labels.length} selected';
  }

  Future<void> _openPicker(BuildContext context) async {
    final draft = {...selectedIds};
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(label),
              content: SizedBox(
                width: 320,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    AppListTileMaterial(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(emptyLabel),
                        value: draft.isEmpty,
                        onChanged: (_) {
                          setDialogState(() => draft.clear());
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ...options.map((option) {
                      final selected = draft.contains(option.id);
                      return AppListTileMaterial(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(option.label),
                          value: selected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value ?? false) {
                                draft.add(option.id);
                              } else {
                                draft.remove(option.id);
                              }
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    onChanged(draft.toList());
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(_summary(), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
