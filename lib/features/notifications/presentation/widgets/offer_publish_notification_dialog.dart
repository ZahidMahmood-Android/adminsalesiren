import 'package:flutter/material.dart';

import '../../../../core/widgets/app_network_image.dart';
import '../../domain/alert_type_utils.dart';
import '../../domain/entities/offer_notification_draft.dart';

Future<List<OfferNotificationDraft>?> showOfferPublishNotificationDialog(
  BuildContext context, {
  required List<OfferNotificationDraft> drafts,
  String title = 'Notification preview',
  String subtitle =
      'Review the push notification before publishing. Alert category is calculated automatically from the offer.',
  String confirmLabel = 'Publish',
  Map<String, String>? alertTypeLabels,
}) {
  if (drafts.isEmpty) {
    return Future.value(const []);
  }

  return showDialog<List<OfferNotificationDraft>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _OfferPublishNotificationDialog(
      drafts: drafts,
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      alertTypeLabels: alertTypeLabels ?? const {},
    ),
  );
}

class _OfferPublishNotificationDialog extends StatefulWidget {
  const _OfferPublishNotificationDialog({
    required this.drafts,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.alertTypeLabels,
  });

  final List<OfferNotificationDraft> drafts;
  final String title;
  final String subtitle;
  final String confirmLabel;
  final Map<String, String> alertTypeLabels;

  @override
  State<_OfferPublishNotificationDialog> createState() =>
      _OfferPublishNotificationDialogState();
}

class _OfferPublishNotificationDialogState
    extends State<_OfferPublishNotificationDialog> {
  late final List<_DraftEditorState> _editors;

  @override
  void initState() {
    super.initState();
    _editors = widget.drafts
        .map(
          (draft) => _DraftEditorState(
            titleController: TextEditingController(text: draft.title),
            bodyController: TextEditingController(text: draft.body),
            includeImage: draft.includeImage && draft.imageUrl.isNotEmpty,
            draft: draft,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final editor in _editors) {
      editor.titleController.dispose();
      editor.bodyController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ..._editors.asMap().entries.map((entry) {
                final index = entry.key;
                final editor = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _editors.length - 1 ? 0 : 18,
                  ),
                  child: _NotificationDraftEditor(
                    editor: editor,
                    showLineLabel: widget.drafts.length > 1,
                    alertTypeLabels: widget.alertTypeLabels,
                    onChanged: () => setState(() {}),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.campaign_outlined),
          label: Text(widget.confirmLabel),
          style: FilledButton.styleFrom(backgroundColor: primary),
        ),
      ],
    );
  }

  void _submit() {
    final results = <OfferNotificationDraft>[];
    for (final editor in _editors) {
      final title = editor.titleController.text.trim();
      final body = editor.bodyController.text.trim();
      if (title.isEmpty || body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification title and message are required.'),
          ),
        );
        return;
      }
      results.add(
        editor.draft.copyWith(
          title: title,
          body: body,
          includeImage: editor.includeImage,
        ),
      );
    }
    Navigator.pop(context, results);
  }
}

class _DraftEditorState {
  _DraftEditorState({
    required this.titleController,
    required this.bodyController,
    required this.includeImage,
    required this.draft,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  bool includeImage;
  final OfferNotificationDraft draft;
}

class _NotificationDraftEditor extends StatelessWidget {
  const _NotificationDraftEditor({
    required this.editor,
    required this.showLineLabel,
    required this.alertTypeLabels,
    required this.onChanged,
  });

  final _DraftEditorState editor;
  final bool showLineLabel;
  final Map<String, String> alertTypeLabels;
  final VoidCallback onChanged;

  String _labelFor(String slug) =>
      alertTypeLabels[slug]?.trim().isNotEmpty == true
      ? alertTypeLabels[slug]!.trim()
      : alertTypeLabel(slug);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final previewTitle = editor.titleController.text.trim().isEmpty
        ? 'Notification title'
        : editor.titleController.text.trim();
    final previewBody = editor.bodyController.text.trim().isEmpty
        ? 'Notification message will appear here.'
        : editor.bodyController.text.trim();
    final showImage =
        editor.includeImage && editor.draft.imageUrl.trim().isNotEmpty;
    final alertType = editor.draft.alertType;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLineLabel && editor.draft.lineLabel.trim().isNotEmpty) ...[
            Text(
              editor.draft.lineLabel.trim(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Alert category (auto)',
              prefixIcon: Icon(Icons.auto_awesome_outlined),
            ),
            child: Text(
              _labelFor(alertType),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: AppNetworkImage(
                        imageUrl: editor.draft.imageUrl,
                        fit: BoxFit.cover,
                        icon: Icons.image_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        previewBody,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: editor.titleController,
            decoration: const InputDecoration(
              labelText: 'Notification title',
              prefixIcon: Icon(Icons.title_outlined),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: editor.bodyController,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notification message',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Send with image'),
            subtitle: Text(
              editor.draft.imageUrl.trim().isEmpty
                  ? 'No offer image is available for this notification.'
                  : 'Include the offer image in the mobile push notification.',
            ),
            value: editor.includeImage,
            onChanged: editor.draft.imageUrl.trim().isEmpty
                ? null
                : (value) {
                    editor.includeImage = value;
                    onChanged();
                  },
          ),
        ],
      ),
    );
  }
}
