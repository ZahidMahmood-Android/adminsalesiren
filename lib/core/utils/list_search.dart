String normalizeSearchQuery(String query) => query.trim().toLowerCase();

String searchValueToText(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is bool) {
    return value
        ? 'active enabled yes true on featured verified published approved'
        : 'inactive disabled no false off draft pending rejected';
  }
  if (value is num) {
    return value.toString();
  }
  if (value is DateTime) {
    return '${value.year}-${value.month}-${value.day} '
        '${value.day}/${value.month}/${value.year}';
  }
  if (value is Iterable) {
    return value
        .map(searchValueToText)
        .where((item) => item.isNotEmpty)
        .join(' ');
  }
  return value.toString();
}

Iterable<String> _searchableFields({
  Iterable<String> fields = const [],
  Iterable<dynamic> values = const [],
  Iterable<String> keywords = const [],
}) {
  return [
    ...fields,
    ...values.map(searchValueToText),
    ...keywords,
  ].map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty);
}

bool matchesSearchQuery(
  String query, {
  Iterable<String> fields = const [],
  Iterable<dynamic> values = const [],
  Iterable<String> keywords = const [],
}) {
  final normalized = normalizeSearchQuery(query);
  if (normalized.isEmpty) {
    return true;
  }

  final searchable = _searchableFields(
    fields: fields,
    values: values,
    keywords: keywords,
  ).toList();
  if (searchable.isEmpty) {
    return false;
  }

  final haystack = searchable.join(' ');
  if (haystack.contains(normalized)) {
    return true;
  }

  final tokens = normalized
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
  return tokens.every(
    (token) => searchable.any((field) => field.contains(token)),
  );
}
