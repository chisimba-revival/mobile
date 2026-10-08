import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../field/card_state.dart';
import '../net/chisimba_api.dart';
import '../net/session_store.dart';
import 'database.dart';

/// A snapshot of the reference data the field card needs: the species
/// catalogue, the outing list, and the behaviour/age-sex reference values.
///
/// [fromCache] is true when the snapshot came from (or was supplemented by)
/// the local store rather than a live fetch. [refreshError] explains why the
/// live fetch did not succeed, so the picker can say so instead of showing an
/// empty list with no explanation.
class ReferenceSnapshot {
  const ReferenceSnapshot({
    this.species = const [],
    this.outings = const [],
    this.reference = const ReferenceValues(),
    this.fromCache = false,
    this.refreshError,
  });

  final List<SpeciesChoice> species;
  final List<Outing> outings;
  final ReferenceValues reference;
  final bool fromCache;
  final String? refreshError;
}

/// Loads reference data (species, outings, competencies) for the field card.
///
/// The design is cache-first: the [ReferenceData] table always answers
/// immediately, and a live fetch refreshes it when the session allows. This is
/// deliberate — the previous implementation gated the fetch on
/// `connectivity.hasTransport`, which lies on platforms without a
/// NetworkManager DBus (desktop Linux, for example) and left the species
/// picker empty even with a working network. The fetch is instead attempted
/// whenever a usable session exists, with a short timeout; a failure falls
/// back to whatever the cache holds and records [ReferenceSnapshot.refreshError]
/// so the UI can offer a retry.
class ReferenceLoader {
  ReferenceLoader({
    required this.database,
    required this.api,
    required this.sessions,
  });

  final FieldLogDatabase database;
  final ChisimbaApi api;
  final SessionStore sessions;

  /// How long a successful fetch stays fresh. Two minutes keeps a long
  /// session from re-downloading the catalogue for every sighting while still
  /// picking up a new outing or a corrected species name quickly.
  static const Duration _ttl = Duration(minutes: 2);

  /// Upper bound on one refresh. Offline devices fail fast anyway; this
  /// exists for flaky links, so opening a card never hangs on the network.
  static const Duration _refreshTimeout = Duration(seconds: 6);

  static const String _metaKind = 'meta';
  static const String _fetchedAtCode = 'fetched_at';
  static const String _speciesKind = 'species';
  static const String _outingKind = 'outing';
  static const String _behaviourKind = 'behaviour';
  static const String _ageSexKind = 'age_sex_class';

  /// The fallback reference lists, used when the service returns no matching
  /// competencies. They mirror what the card has always offered so a guide is
  /// never stuck without a behaviour to tick.
  static const List<String> _fallbackBehaviours = [
    'grazing',
    'moving',
    'resting',
    'feeding',
    'with_young',
    'alert',
    'unknown',
  ];
  static const List<String> _fallbackAgeSex = [
    'female',
    'male',
    'juvenile',
    'adult_unknown',
    'unknown',
  ];

  /// Returns the best available snapshot: fresh data when the network and
  /// session allow it, cached data otherwise.
  ///
  /// [forceRefresh] bypasses the freshness window — the picker's retry button
  /// uses it, because a failed fetch leaves the cache technically fresh.
  Future<ReferenceSnapshot> load({bool forceRefresh = false}) async {
    final (cached, fetchedAt) = await _readCache();

    if (!forceRefresh &&
        fetchedAt != null &&
        DateTime.now().toUtc().difference(fetchedAt) < _ttl) {
      return cached;
    }

    final stored = await sessions.read();
    if (stored == null || !stored.isUsable) {
      // Signed out: the cache is all there is, and that is fine — recording
      // must never require a login.
      return cached;
    }

    try {
      return await _refresh(stored.accessToken).timeout(_refreshTimeout);
    } on Object catch (error) {
      debugPrint('Reference refresh failed; serving cache: $error');
      return ReferenceSnapshot(
        species: cached.species,
        outings: cached.outings,
        reference: cached.reference,
        fromCache: true,
        refreshError: '$error',
      );
    }
  }

  Future<ReferenceSnapshot> _refresh(String accessToken) async {
    final speciesList = await api.getSpecies(accessToken);
    final outingList = await api.getOutings(accessToken);
    final competencyList = await api.getCompetencies(accessToken);

    final snapshot = ReferenceSnapshot(
      species: [
        for (final s in speciesList.species)
          SpeciesChoice(
            code: s.code,
            commonName: s.commonName,
            scientificName: s.scientificName,
          ),
      ]..sort((a, b) => a.commonName.compareTo(b.commonName)),
      outings: outingList.outings,
      reference: _referenceFromCompetencies(competencyList.competencies),
    );

    await _writeCache(snapshot);
    return snapshot;
  }

  /// Derives the behaviour and age-sex lists from the competency catalogue,
  /// falling back to the built-in defaults when the service has nothing
  /// matching. Categories are matched loosely because the office words them
  /// inconsistently ('Behaviour', 'age/sex', 'Demographics').
  ReferenceValues _referenceFromCompetencies(List<Competency> competencies) {
    final active = competencies.where((c) => !c.retired).toList();

    final behaviours =
        active
            .where((c) => c.category.toLowerCase().contains('behav'))
            .map((c) => c.name.toLowerCase().replaceAll(' ', '_'))
            .toSet()
            .toList()
          ..sort();

    final ageSex =
        active
            .where(
              (c) =>
                  c.category.toLowerCase().contains('age') ||
                  c.category.toLowerCase().contains('sex') ||
                  c.category.toLowerCase().contains('demograph'),
            )
            .map((c) => c.name.toLowerCase().replaceAll(' ', '_'))
            .toSet()
            .toList()
          ..sort();

    return ReferenceValues(
      behaviours: behaviours.isNotEmpty ? behaviours : _fallbackBehaviours,
      ageSexClasses: ageSex.isNotEmpty ? ageSex : _fallbackAgeSex,
    );
  }

  // ---- cache ----

  /// Reads the cache, returning the snapshot alongside the freshness
  /// timestamp. The pair travels together only inside [load]; the UI has no
  /// business asking when data was fetched.
  Future<(ReferenceSnapshot, DateTime?)> _readCache() async {
    final rows = await database.select(database.referenceData).get();

    final species = <SpeciesChoice>[];
    final outings = <Outing>[];
    final behaviours = <String>[];
    final ageSex = <String>[];
    DateTime? fetchedAt;

    for (final row in rows) {
      switch (row.kind) {
        case _speciesKind:
          String scientific = '';
          final raw = row.payload;
          if (raw != null && raw.isNotEmpty) {
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) {
                scientific = '${decoded['scientific_name'] ?? ''}';
              }
            } on Object {
              // A corrupt payload degrades to no scientific name rather than
              // losing the row: the common name still identifies the species.
            }
          }
          species.add(
            SpeciesChoice(
              code: row.code,
              commonName: row.label ?? '',
              scientificName: scientific,
            ),
          );
        case _outingKind:
          final raw = row.payload;
          if (raw != null && raw.isNotEmpty) {
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) {
                outings.add(Outing.fromJson(decoded));
              }
            } on Object {
              // Skip an unparseable outing; the rest of the list still works.
            }
          }
        case _behaviourKind:
          behaviours.add(row.code);
        case _ageSexKind:
          ageSex.add(row.code);
        case _metaKind:
          if (row.code == _fetchedAtCode && row.label != null) {
            fetchedAt = DateTime.tryParse(row.label!)?.toUtc();
          }
      }
    }

    species.sort((a, b) => a.commonName.compareTo(b.commonName));
    behaviours.sort();
    ageSex.sort();

    final snapshot = ReferenceSnapshot(
      species: species,
      outings: outings,
      reference: ReferenceValues(
        behaviours: behaviours.isNotEmpty ? behaviours : _fallbackBehaviours,
        ageSexClasses: ageSex.isNotEmpty ? ageSex : _fallbackAgeSex,
      ),
      // 'fromCache' doubles as 'rows exist': an empty table is a cache miss
      // however it is dressed up.
      fromCache: rows.isNotEmpty,
    );
    return (snapshot, fetchedAt);
  }

  Future<void> _writeCache(ReferenceSnapshot snapshot) async {
    final fetchedAt = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final kind in const [
        _speciesKind,
        _outingKind,
        _behaviourKind,
        _ageSexKind,
        _metaKind,
      ]) {
        await (database.delete(
          database.referenceData,
        )..where((t) => t.kind.equals(kind))).go();
      }

      final table = database.referenceData;
      for (final s in snapshot.species) {
        await database
            .into(table)
            .insert(
              ReferenceDataCompanion.insert(
                kind: _speciesKind,
                code: s.code,
                label: drift.Value(s.commonName),
                payload: drift.Value(
                  jsonEncode({'scientific_name': s.scientificName}),
                ),
                fetchedAt: drift.Value(fetchedAt),
              ),
            );
      }
      for (final o in snapshot.outings) {
        await database
            .into(table)
            .insert(
              ReferenceDataCompanion.insert(
                kind: _outingKind,
                code: o.id,
                payload: drift.Value(jsonEncode(_outingJson(o))),
                fetchedAt: drift.Value(fetchedAt),
              ),
            );
      }
      for (final b in snapshot.reference.behaviours) {
        await database
            .into(table)
            .insert(
              ReferenceDataCompanion.insert(
                kind: _behaviourKind,
                code: b,
                fetchedAt: drift.Value(fetchedAt),
              ),
            );
      }
      for (final a in snapshot.reference.ageSexClasses) {
        await database
            .into(table)
            .insert(
              ReferenceDataCompanion.insert(
                kind: _ageSexKind,
                code: a,
                fetchedAt: drift.Value(fetchedAt),
              ),
            );
      }
      await database
          .into(table)
          .insert(
            ReferenceDataCompanion.insert(
              kind: _metaKind,
              code: _fetchedAtCode,
              label: drift.Value(fetchedAt.toIso8601String()),
            ),
          );
    });
  }

  /// [Outing] has no `toJson`; this rebuilds the shape
  /// [Outing.fromJson] expects so the raw service payload round-trips.
  Map<String, dynamic> _outingJson(Outing o) => <String, dynamic>{
    'id': o.id,
    'kind': o.kind,
    'context_code': o.contextCode,
    'guide_id': o.guideId,
    'trainee_ids': o.traineeIds,
    'status': o.status,
    'planned_start': o.plannedStart,
    'ended_at': o.endedAt,
    'sealed_at': o.sealedAt,
    'notes': o.notes,
    'revision': o.revision,
  };
}
