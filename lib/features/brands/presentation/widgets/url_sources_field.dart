import 'package:flutter/material.dart';

import '../../domain/entities/brand_url_source.dart';

class UrlSourcesField extends StatefulWidget {
  const UrlSourcesField({
    super.key,
    required this.sources,
    required this.onChanged,
    this.title = 'Link sources',
  });

  final List<BrandUrlSource> sources;
  final ValueChanged<List<BrandUrlSource>> onChanged;
  final String title;

  @override
  State<UrlSourcesField> createState() => _UrlSourcesFieldState();
}

class _UrlSourcesFieldState extends State<UrlSourcesField> {
  late List<_UrlSourceRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _rowsFromSources(widget.sources);
  }

  @override
  void didUpdateWidget(covariant UrlSourcesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sources != widget.sources) {
      _rows = _rowsFromSources(widget.sources);
    }
  }

  List<_UrlSourceRow> _rowsFromSources(List<BrandUrlSource> sources) {
    final items = sources.isEmpty
        ? BrandUrlSource.defaultTemplates()
        : BrandUrlSourceUtils.copyList(sources);
    return items
        .map(
          (source) => _UrlSourceRow(
            id: source.id,
            nameController: TextEditingController(text: source.name),
            urlController: TextEditingController(text: source.url),
          ),
        )
        .toList();
  }

  void _emit() {
    widget.onChanged(
      _rows
          .map(
            (row) => BrandUrlSource(
              id: row.id,
              name: row.nameController.text.trim(),
              url: row.urlController.text.trim(),
            ),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  IconData _iconFor(String id, String name) {
    final lower = name.toLowerCase();
    if (id == BrandUrlSource.instagramId || lower.contains('instagram')) {
      return Icons.camera_alt_outlined;
    }
    if (id == BrandUrlSource.facebookId || lower.contains('facebook')) {
      return Icons.facebook;
    }
    return Icons.language;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ..._rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Icon(
                    _iconFor(row.id, row.nameController.text),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: row.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Source name',
                      isDense: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: row.urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      isDense: true,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _rows.add(
                  _UrlSourceRow(
                    id: BrandUrlSource.newId(),
                    nameController: TextEditingController(text: 'Link'),
                    urlController: TextEditingController(),
                  ),
                );
              });
              _emit();
            },
            icon: const Icon(Icons.add_link),
            label: const Text('Add link source'),
          ),
        ),
      ],
    );
  }
}

class _UrlSourceRow {
  _UrlSourceRow({
    required this.id,
    required this.nameController,
    required this.urlController,
  });

  final String id;
  final TextEditingController nameController;
  final TextEditingController urlController;

  void dispose() {
    nameController.dispose();
    urlController.dispose();
  }
}
