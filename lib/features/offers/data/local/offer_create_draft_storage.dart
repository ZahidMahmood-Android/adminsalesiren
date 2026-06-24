import 'dart:convert';
import 'dart:html' as html;

import '../../presentation/widgets/offer_lines_editor.dart';

class OfferCreateDraftStorage {
  OfferCreateDraftStorage._();

  static String _keyForUser(String userId) => 'offer_create_draft_$userId';

  static List<OfferLineDraft>? load(String userId) {
    if (userId.isEmpty) {
      return null;
    }
    final raw = html.window.localStorage[_keyForUser(userId)];
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final linesRaw = decoded['lines'];
      if (linesRaw is! List) {
        return null;
      }
      final lines = linesRaw
          .whereType<Map>()
          .map(
            (item) => OfferLineDraft.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      if (lines.isEmpty) {
        return null;
      }
      return lines;
    } catch (_) {
      return null;
    }
  }

  static void save(String userId, List<OfferLineDraft> lines) {
    if (userId.isEmpty) {
      return;
    }
    if (!lines.any((line) => !line.isEffectivelyEmpty)) {
      clear(userId);
      return;
    }
    final payload = jsonEncode({
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'lines': lines.map((line) => line.toJson()).toList(),
    });
    html.window.localStorage[_keyForUser(userId)] = payload;
  }

  static void clear(String userId) {
    if (userId.isEmpty) {
      return;
    }
    html.window.localStorage.remove(_keyForUser(userId));
  }
}
