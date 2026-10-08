import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../field/card_state.dart';

/// The species this device has recently recorded, most recent first.
///
/// Persisted rather than derived, because the point is exactly the thing a
/// cache cannot hold: what *this* guide keeps seeing. A picker that opens on
/// the last five species saves a search on every sighting, which is where the
/// time actually goes in the field.
class RecentSpecies {
  RecentSpecies._(this._prefs);

  static const String _key = 'recent_species';

  /// Cap on the list. Long enough to cover a week of mixed drives, short
  /// enough that the section stays scannable without scrolling.
  static const int _limit = 8;

  final SharedPreferences _prefs;

  /// Opens the store. Cheap after the first call (the plugin caches the
  /// instance), so `await`ing it at startup is fine.
  static Future<RecentSpecies> open() async =>
      RecentSpecies._(await SharedPreferences.getInstance());

  /// The recent list, newest first. Never throws: a corrupt or absent value
  /// reads as empty, because a broken preferences blob must not stop a
  /// sighting being recorded.
  Future<List<SpeciesChoice>> list() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final choices = <SpeciesChoice>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final code = '${entry['code'] ?? ''}';
        if (code.isEmpty) continue;
        choices.add(
          SpeciesChoice(
            code: code,
            commonName: '${entry['common_name'] ?? ''}',
            scientificName: '${entry['scientific_name'] ?? ''}',
          ),
        );
      }
      return choices;
    } on Object {
      return const [];
    }
  }

  /// Records [choice] as most-recently-used, moving any previous mention to
  /// the front and trimming to the cap.
  Future<void> note(SpeciesChoice choice) async {
    if (choice.code.isEmpty) return;
    // A copy, because list() may hand back a const empty (or the shared
    // result of a decode) and this mutates it.
    final current = List<SpeciesChoice>.of(await list());
    current.removeWhere((c) => c.code == choice.code);
    current.insert(0, choice);
    final trimmed = current.length > _limit
        ? current.sublist(0, _limit)
        : current;
    await _prefs.setString(
      _key,
      jsonEncode([
        for (final c in trimmed)
          {
            'code': c.code,
            'common_name': c.commonName,
            'scientific_name': c.scientificName,
          },
      ]),
    );
  }
}
