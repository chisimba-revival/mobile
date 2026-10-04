import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/pull_engine.dart';
import 'package:field_log/models/geo_point.dart';
import 'package:field_log/models/sighting.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory store. Each test gets its own, so no test can pass because of
/// something another one left behind.
FieldLogDatabase memoryStore() =>
    FieldLogDatabase(NativeDatabase.memory(logStatements: false));

final captured = DateTime.utc(2026, 10, 4, 6, 30);
final recorded = DateTime.utc(2026, 10, 4, 18, 5);

/// A sighting in the client's own shape, which is the only place it exists
/// before anything is sent.
WildlifeSighting aSighting({
  String id = 'local-1',
  int revision = 0,
  SightingStatus status = SightingStatus.pending,
  String? notes = 'three on the track',
}) {
  return WildlifeSighting(
    id: id,
    contextCode: 'kiswahili',
    driveId: 'drive-1',
    status: status,
    location: GeoPoint(longitude: 36.8219, latitude: -1.2921),
    capturedAt: captured,
    recordedAt: recorded,
    revision: revision,
    createdBy: 'usr_trainee',
    speciesCode: 'ANTH',
    count: 3,
    notes: notes,
  );
}

/// A stored sighting that still carries edits the service has not accepted.
SightingsCompanion pendingSighting() {
  return SightingsCompanion.insert(
    localId: 'local-1',
    contextCode: 'kiswahili',
    driveId: 'drive-1',
    locationLat: -1.2921,
    locationLng: 36.8219,
    status: SightingStatus.pending,
    capturedAt: captured,
    recordedAt: recorded,
    revision: const Value(0),
    createdBy: 'usr_trainee',
    speciesCode: const Value('ANTH'),
    count: const Value(3),
    notes: const Value('three on the track'),
    hasPendingChanges: const Value(true),
  );
}

/// The state as a change feed would carry it.
Map<String, dynamic> wireStateOf(WildlifeSighting sighting) {
  return {
    'id': sighting.id,
    'context_code': sighting.contextCode,
    'drive_id': sighting.driveId,
    'status': sighting.status.name,
    'location': sighting.location.toGeoJson(),
    'captured_at': captured.toIso8601String(),
    'recorded_at': recorded.toIso8601String(),
    'revision': sighting.revision,
    'created_by': sighting.createdBy,
    if (sighting.speciesCode != null) 'species_code': sighting.speciesCode,
    if (sighting.count != null) 'count': sighting.count,
    if (sighting.notes != null) 'notes': sighting.notes,
  };
}

PullPage pageOf(List<PullChange> changes, {String? next = 'cursor-2'}) {
  return PullPage(
    changes: changes,
    nextCursor: next,
    hasMore: next != null,
    serverTime: DateTime.utc(2026, 10, 4, 19),
  );
}

PullChange changeOf({
  String id = 'local-1',
  int revision = 1,
  bool tombstone = false,
  Map<String, dynamic>? state,
}) {
  return PullChange(
    entity: EntityKind.sighting,
    entityId: id,
    revision: revision,
    isTombstone: tombstone,
    state: state ?? wireStateOf(aSighting(id: id, revision: revision)),
  );
}

void main() {
  group('a page and its cursor are one unit of work', () {
    test('a crash before the cursor is written loses the page too', () async {
      final db = memoryStore();
      addTearDown(db.close);

      // Fault injection: the cursor table is gone, so the cursor write at the end
      // of the transaction cannot succeed. If the page writes were a separate
      // unit of work they would already be committed by now.
      await db.customStatement('DROP TABLE sync_cursors');

      var threw = false;
      try {
        await PullEngine(db)
            .applyPage(scope: 'kiswahili', page: pageOf([changeOf()]));
      } catch (_) {
        threw = true;
      }

      expect(threw, isTrue, reason: 'the cursor write should have failed');

      // The point of the single transaction. A sighting here without a cursor
      // would be a change the client has applied and will never be told about
      // again, which is how a logbook quietly stops agreeing with the service.
      final rows = await db.select(db.sightings).get();
      expect(rows, isEmpty);
    });
  });

  group('applying a page', () {
    test('stores a new sighting and advances the cursor', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      final outcome = await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([changeOf(revision: 3)]),
      );

      expect(outcome.applied, 1);
      expect(outcome.conflicts, 0);
      expect(outcome.cursorAdvanced, isTrue);
      expect(await engine.cursorFor('kiswahili'), 'cursor-2');

      final row = await (db.select(
        db.sightings,
      )..where((t) => t.localId.equals('local-1'))).getSingle();
      expect(row.revision, 3);
      expect(row.speciesCode, 'ANTH');
      expect(row.count, 3);
      // GeoJSON stores [longitude, latitude]. Reading it the other way round puts
      // the sighting in the Indian Ocean.
      expect(row.locationLat, closeTo(-1.2921, 1e-9));
      expect(row.locationLng, closeTo(36.8219, 1e-9));
    });

    test('a re-delivered page changes nothing', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([changeOf(revision: 3)]),
      );
      final second = await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([changeOf(revision: 3)]),
      );

      expect(second.applied, 1, reason: 'the same page is idempotent');
      final row = await (db.select(
        db.sightings,
      )..where((t) => t.localId.equals('local-1'))).getSingle();
      expect(row.revision, 3);
    });

    test('an older revision never walks a record backwards', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([changeOf(revision: 7)]),
      );

      // A page delivered out of order. Revision is the only thing that
      // arbitrates, so revision 5 must not overwrite revision 7.
      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([
          changeOf(
            revision: 5,
            state: wireStateOf(aSighting(revision: 5, notes: 'stale note')),
          ),
        ]),
      );

      final row = await (db.select(
        db.sightings,
      )..where((t) => t.localId.equals('local-1'))).getSingle();
      expect(row.revision, 7);
      expect(row.notes, 'three on the track');
    });
  });

  group('a deletion', () {
    test('is marked on the row rather than removing it', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([changeOf(revision: 1)]),
      );
      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([changeOf(revision: 2, tombstone: true, state: null)]),
      );

      final row = await (db.select(
        db.sightings,
      )..where((t) => t.localId.equals('local-1'))).getSingle();
      expect(row.isTombstone, isTrue);
      expect(row.deletedAt is DateTime, isTrue);
      // Rule 9 is about the audit trail surviving, so the values stay put.
      expect(row.speciesCode, 'ANTH');
      expect(row.revision, 2);
    });

    test('tombstones only the record it names', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([
          changeOf(id: 'local-1', revision: 1),
          changeOf(id: 'local-2', revision: 1),
        ]),
      );
      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([
          changeOf(id: 'local-1', revision: 2, tombstone: true, state: null),
        ]),
      );

      final rows = await db.select(db.sightings).get();
      expect(rows.where((r) => r.isTombstone).map((r) => r.localId), [
        'local-1',
      ]);
    });
  });

  group('a record with unaccepted local edits', () {
    test('is held rather than overwritten, and both sides are kept', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await db.into(db.sightings).insert(pendingSighting());

      final outcome = await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([
          changeOf(
            revision: 4,
            state: wireStateOf(
              aSighting(revision: 4, notes: 'from the service'),
            ),
          ),
        ]),
      );

      expect(outcome.applied, 0);
      expect(outcome.conflicts, 1);

      final row = await (db.select(
        db.sightings,
      )..where((t) => t.localId.equals('local-1'))).getSingle();
      expect(
        row.notes,
        'three on the track',
        reason: 'the local edit survives',
      );

      final conflict = await db.select(db.conflicts).getSingle();
      expect(conflict.serverRevision, 4);
      expect(conflict.baseRevision, 0);
      expect(conflict.resolvedAt, equals(null), reason: 'unresolved');
      expect(conflict.clientPayload, contains('three on the track'));
      expect(conflict.serverState, contains('from the service'));
    });

    test('holding the same page twice does not stack conflicts', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await db.into(db.sightings).insert(pendingSighting());
      final page = pageOf([changeOf(revision: 4)]);

      await engine.applyPage(scope: 'kiswahili', page: page);
      await engine.applyPage(scope: 'kiswahili', page: page);

      final conflicts = await db.select(db.conflicts).get();
      expect(conflicts, hasLength(1));
    });
  });

  group('a sparse page', () {
    test('leaves out fields alone instead of blanking them', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([changeOf(revision: 1)]),
      );

      // Only the status moved. Rule 21 means an absent species_code is not a
      // species of null; it means the service did not mention it.
      await engine.applyPage(
        scope: 'kiswahili',
        page: pageOf([
          PullChange(
            entity: EntityKind.sighting,
            entityId: 'local-1',
            revision: 2,
            isTombstone: false,
            state: {'status': 'verified', 'revision': 2},
          ),
        ]),
      );

      final row = await (db.select(
        db.sightings,
      )..where((t) => t.localId.equals('local-1'))).getSingle();
      expect(row.status, SightingStatus.verified);
      expect(row.speciesCode, 'ANTH');
      expect(row.count, 3);
      expect(row.notes, 'three on the track');
    });
  });
}
