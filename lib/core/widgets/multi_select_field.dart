import 'package:flutter/material.dart';

import 'app_field_selector.dart';
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
    this.prefixIcon,
    this.width = 300,
    this.emptyLabel = 'Any',
    this.enableSelectAll = false,
    this.selectAllLabel = 'Select all',
    this.showClearOption = true,
    this.enabled = true,
    super.key,
  });

  final String label;
  final List<MultiSelectOption> options;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final IconData? prefixIcon;
  final double width;
  final String emptyLabel;
  final bool enableSelectAll;
  final String selectAllLabel;
  final bool showClearOption;
  final bool enabled;

  bool get _allSelected =>
      options.isNotEmpty && selectedIds.length == options.length;

  String _summary() {
    if (selectedIds.isEmpty) {
      return emptyLabel;
    }
    if (enableSelectAll && _allSelected) {
      return selectAllLabel;
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
    if (!enabled) {
      return;
    }
    final draft = {...selectedIds};
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allSelected =
                options.isNotEmpty && draft.length == options.length;
            return AlertDialog(
              title: Text(label),
              content: SizedBox(
                width: 320,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (enableSelectAll) ...[
                      AppListTileMaterial(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(selectAllLabel),
                          value: allSelected,
                          onChanged: (_) {
                            setDialogState(() {
                              if (allSelected) {
                                draft.clear();
                              } else {
                                draft
                                  ..clear()
                                  ..addAll(options.map((option) => option.id));
                              }
                            });
                          },
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    if (showClearOption) ...[
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
                    ],
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
    return AppFieldSelector(
      label: label,
      valueText: _summary(),
      prefixIcon: prefixIcon,
      width: width,
      enabled: enabled,
      onTap: () => _openPicker(context),
    );
  }
}
