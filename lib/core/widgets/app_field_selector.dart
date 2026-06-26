import 'package:flutter/material.dart';

/// Shared dropdown-style field shell for single and multi selectors.
class AppFieldSelector extends StatelessWidget {
  const AppFieldSelector({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.prefixIcon,
    this.enabled = true,
    this.width = 300,
    super.key,
  });

  final String label;
  final String valueText;
  final VoidCallback? onTap;
  final IconData? prefixIcon;
  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          isEmpty: valueText.trim().isEmpty,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            valueText.trim().isEmpty ? ' ' : valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
