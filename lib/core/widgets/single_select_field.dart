import 'package:flutter/material.dart';

import 'app_field_selector.dart';
import 'app_list_tile_material.dart';

class SingleSelectOption<T> {
  const SingleSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

class SingleSelectField<T> extends StatelessWidget {
  const SingleSelectField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
    this.width = 300,
    this.emptyLabel = 'Select',
    this.enableSearch = false,
    this.enabled = true,
    this.allowAny = false,
    super.key,
  });

  final String label;
  final List<SingleSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final double width;
  final String emptyLabel;
  final bool enableSearch;
  final bool enabled;
  final bool allowAny;

  String _summary() {
    for (final option in options) {
      if (option.value == value) {
        return option.label;
      }
    }
    return emptyLabel;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || onChanged == null) {
      return;
    }
    var query = '';
    T? draft = value;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = options.where((option) {
              if (!enableSearch || query.trim().isEmpty) {
                return true;
              }
              return option.label.toLowerCase().contains(query.toLowerCase());
            }).toList();
            return AlertDialog(
              title: Text(label),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (enableSearch) ...[
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search',
                        ),
                        onChanged: (value) =>
                            setDialogState(() => query = value),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: (MediaQuery.sizeOf(context).height * 0.5)
                            .clamp(240.0, 420.0),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (allowAny)
                            AppListTileMaterial(
                              child: RadioListTile<T?>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(emptyLabel),
                                value: null,
                                groupValue: draft,
                                onChanged: (selected) {
                                  setDialogState(() => draft = selected);
                                },
                              ),
                            ),
                          ...filtered.map(
                            (option) => AppListTileMaterial(
                              child: RadioListTile<T>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(option.label),
                                value: option.value,
                                groupValue: draft,
                                onChanged: (selected) {
                                  setDialogState(() => draft = selected);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    onChanged!(draft);
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
