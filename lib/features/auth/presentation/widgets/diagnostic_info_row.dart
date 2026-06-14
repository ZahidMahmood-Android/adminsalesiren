import 'package:flutter/material.dart';

import '../../../../core/utils/copy_utils.dart';

class DiagnosticInfoRow extends StatelessWidget {
  const DiagnosticInfoRow({
    required this.label,
    required this.value,
    required this.context,
    this.isCopyable = false,
    super.key,
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
