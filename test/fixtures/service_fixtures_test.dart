import 'dart:convert';
import 'dart:io';

import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/pull_engine.dart';
import 'package:field_log/data/push_engine.dart';
import 'package:field_log/models/geo_point.dart';
import 'package:field_log/models/sighting.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/pull_engine_test.dart' show memoryStore;

/// The fixtures stand in for a service that does not exist yet.
///
/// Contract delivery steps 1 to 10 are unimplemented, so every envelope here is
/// this client's guess. The value of these tests is not that they prove the
/// client right against the service. It is that they pin the shapes, so that when
/// the service is built and answers differently, the difference shows up as a
/// failing test naming a field rather than as a record full of zeros in the
/// field.
///
/// Each fixture carries `_guessed` listing what had to be invented. Check those
/// keys first when reconciling against the real service.
void main() {
  late Map<String, dynamic> wire;

  setUpAll(() {
    wire = jsonDecode(
      File('test/fixtures/service/service_fixtures.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  /// The service's page envelope carries a cursor echo and a scope. Neither
  /// belongs to the page itself: the cursor is what we will send next time, and
  /// the scope is ours, because a context grant changes the visible set.
  PullPage pageFrom(String key) {
    final envelope = Map<String, dynamic>.from(wire[key] as Map);
    return PullPage.fromJson(envelope);
  }

  group('a page from the service', () {
    late PullPage page;

    setUp(() => page = pageFrom('pull_page'));

    test('parses into the page the pull engine consumes', () {
      expect(page.nextCursor, 'cur_01J8Z4N2QF');
      expect(page.hasMore, isTrue);
      expect(page.serverTime, DateTime.utc(2026, 10, 4, 5, 42, 11));
      expect(page.changes, hasLength(5));
    });

    test('a record with no species is still a whole record', () {
      // Rule 21. This is the case the contract could not previously express,
      // and the reason a sighting may be verified as observed.
      final noSpecies = page.changes.firstWhere(
        (c) => c.entityId == 'c93d5a72-8e40-4b19-a6c8-3f5b1e9d7a20',
      );
      expect(noSpecies.state, isNot(contains('species_code')));
      expect(noSpecies.state, isNot(contains('count')));
      expect(noSpecies.state?['status'], 'pending');
      expect(noSpecies.state?['notes'], contains('Tracks heading north'));
    });

    test('needs_review survives as distinct from pending', () {
      // Not a synonym for rejected. Somebody competent looked and declined to
      // decide, which is different from nobody having looked.
      final states = page.changes
          .map((c) => c.state?['status'])
          .whereType<String>();
      expect(states, containsAll(['pending', 'verified', 'needs_review']));
    });

    test('a tombstone carries no state and is still a record', () {
      final tombstone = page.changes.singleWhere((c) => c.isTombstone);
      expect(tombstone.state, isNull);
      expect(tombstone.revision, 2);
      expect(tombstone.entityId, isNotEmpty);
    });

    test('a correction arrives with its original retained', () {
      // Rule 15. The reason and the original values travel with the record
      // rather than in a separate history the client has to ask for.
      final corrected = page.changes.singleWhere(
        (c) => c.entityId == 'b7e2d480-5a13-4f6b-8e22-1c9a4d7f0b56',
      );
      expect(corrected.state?['recorded_count'], 7);
      expect(corrected.state?['count'], 4);
      expect(
        corrected.state?['verification_notes'],
        contains('four on the second'),
      );
      expect(corrected.state?['recorded_species_code'], 'ELEP');
    });

    test('late_arrival is present and false rather than absent', () {
      // It has to be distinguishable from "the service did not say".
      final sighting = page.changes.first.state!;
      expect(sighting.containsKey('late_arrival'), isTrue);
      expect(sighting['late_arrival'], isFalse);
    });

    test('location arrives as a GeoJSON Point with longitude first', () {
      // GeoPoint.fromJson is NOT the GeoJSON reader: it reads the flat
      // {longitude, latitude} form this client uses internally. GeoJSON only
      // ever reaches the client through the mapper, so this asserts the order
      // the wire uses and then checks that the client's own writer agrees.
      final location =
          page.changes.first.state!['location'] as Map<String, dynamic>;
      expect(location['type'], 'Point');
      final coordinates = (location['coordinates'] as List).cast<num>();

      // Reading this the other way round puts a sighting in the ocean.
      expect(coordinates[0], closeTo(36.8219, 1e-9), reason: 'longitude');
      expect(coordinates[1], closeTo(-1.2921, 1e-9), reason: 'latitude');

      final round = GeoPoint(
        longitude: coordinates[0].toDouble(),
        latitude: coordinates[1].toDouble(),
      ).toGeoJson();
      expect(
        (round['coordinates'] as List).cast<num>()[0],
        closeTo(coordinates[0], 1e-9),
        reason: 'the client writes longitude first too',
      );
    });
  });

  group('the service wire, applied', () {
    test('lands every record in the local store', () async {
      final db = memoryStore();
      addTearDown(db.close);

      final outcome = await PullEngine(db)
          .applyPage(scope: 'kiswahili', page: pageFrom('pull_page'));

      expect(outcome.cursorAdvanced, isTrue);
      // One change does need a person: the fifth is a deletion of a record this
      // client has never seen, and there is nothing here to mark.
      expect(outcome.conflicts, 1);

      final held = await db.select(db.conflicts).get();
      expect(held, hasLength(1));
      expect(held.single.entityId, 'aa12bd34-77c9-4d0e-b3a5-2f8e6c1d9047');
      expect(held.single.errorCode, 'pull_held');
      expect(
        held.single.resolvedAt,
        equals(null),
        reason: 'nothing has resolved it yet',
      );
      expect(
        decodePayload(held.single.serverState)!['held_because'],
        contains('ever saw it'),
      );

      final rows = await db.select(db.sightings).get();
      // Four, not five. The page's fifth change is a deletion of a record this
      // client has never seen. Creating a row for it would mean inventing a
      // drive, a time and a position for something nobody here observed, so
      // the engine holds it instead and the count is short by one.
      expect(rows, hasLength(4));

      // A pulled row carries only localId. serverId is filled in by
      // _acceptServerRevision on the push path, never by the feed.
      final rowsById = {for (final r in rows) r.localId: r};

      final named = rowsById['0f3a9c11-7b2e-4c8a-9f10-2d5e6b8a1c34']!;
      expect(named.speciesCode, 'LEOP');
      expect(named.count, 1);
      expect(named.status, SightingStatus.verified);
      expect(named.revision, 3);

      final note = rowsById['c93d5a72-8e40-4b19-a6c8-3f5b1e9d7a20']!;
      expect(note.speciesCode, isNull);
      expect(note.count, isNull);
      expect(note.status, SightingStatus.pending);

      final review = rowsById['e5a0f3d1-2c68-4e93-b7a4-6d9c8e1f0b23']!;
      expect(review.status, SightingStatus.needsReview);

      // The deletion of an unseen record produced no row at all. What it did
      // produce is a held conflict naming the revision it arrived with, so a
      // person can see that a record exists on the service and not here.
      expect(
        rowsById.containsKey('aa12bd34-77c9-4d0e-b3a5-2f8e6c1d9047'),
        isFalse,
      );
    });

    test('and a sparse page moves only what it names', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final engine = PullEngine(db);

      await engine.applyPage(scope: 'kiswahili', page: pageFrom('pull_page'));

      final before =
          await (db.select(db.sightings)..where(
                (t) => t.localId.equals('0f3a9c11-7b2e-4c8a-9f10-2d5e6b8a1c34'),
              ))
              .getSingle();
      expect(before.status, SightingStatus.verified);
      expect(before.speciesCode, 'LEOP');

      await engine.applyPage(
        scope: 'kiswahili',
        page: pageFrom('pull_page_sparse'),
      );

      final after =
          await (db.select(db.sightings)..where(
                (t) => t.localId.equals('0f3a9c11-7b2e-4c8a-9f10-2d5e6b8a1c34'),
              ))
              .getSingle();
      expect(after.status, SightingStatus.rejected);
      expect(after.revision, 4);
      // Untouched. A page that treated itself as a whole record blanks these.
      expect(after.speciesCode, 'LEOP');
      expect(after.count, 1);
      expect(after.notes, isNotEmpty);
      expect(after.locationLat, closeTo(before.locationLat, 1e-9));
    });
  });

  group('a push result from the service', () {
    test('carries one of the four outcomes', () {
      final results = wire['push_results_mixed'] as Map<String, dynamic>;
      final outcomes = [
        for (final r in results['results'] as List)
          PushResult.fromJson(Map<String, dynamic>.from(r as Map)),
      ];

      expect(outcomes.map((r) => r.outcome), [
        PushOutcome.applied,
        PushOutcome.refused,
      ]);
      expect(outcomes.first.newRevision, 1);
      expect(outcomes.last.errorCode, 'context_grant_missing');
      expect(outcomes.last.isConflict, isFalse);
    });

    test('a no-op is not a conflict', () {
      // A retry after an ambiguous response. Showing this as a conflict would
      // tell the trainee their record collided with something when nothing
      // actually went wrong.
      final result = PushResult.fromJson(
        Map<String, dynamic>.from(wire['push_result_noop'] as Map),
      );
      expect(result.outcome, PushOutcome.noop);
      expect(result.outcome.isTerminal, isTrue);
      expect(result.isConflict, isFalse);
      expect(result.serverRevision, 1);
      expect(result.serverState?['id'], 'srv_7c1a');
    });

    test('a deferral carries no revision and is not terminal', () {
      final result = PushResult.fromJson(
        Map<String, dynamic>.from(wire['push_result_deferred'] as Map),
      );
      expect(result.outcome, PushOutcome.deferred);
      expect(result.outcome.isTerminal, isFalse);
      expect(result.errorCode, 'dependency_unsettled');
    });

    test('a conflict returns the current server record', () {
      // Rule 6. The client is shown what the service holds so both sides can be
      // kept, rather than being told only that it lost.
      final result = PushResult.fromJson(
        Map<String, dynamic>.from(wire['push_result_conflict'] as Map),
      );
      expect(result.isConflict, isTrue);
      expect(result.serverRevision, 5);
      expect(result.serverState?['count'], 4);
      expect(result.serverState?['notes'], contains('waterhole'));
    });

    test('a refused verification and a refused correction are distinguishable', () {
      // Same outcome, different meaning and different next step. A client that
      // only reads the outcome cannot tell them apart.
      final verification = PushResult.fromJson(
        Map<String, dynamic>.from(
          wire['push_result_verification_refused'] as Map,
        ),
      );
      final correction = PushResult.fromJson(
        Map<String, dynamic>.from(
          wire['push_result_correction_refused'] as Map,
        ),
      );

      expect(verification.outcome, PushOutcome.refused);
      expect(correction.outcome, PushOutcome.refused);
      expect(verification.errorCode, 'stale_revision');
      expect(correction.errorCode, 'correction_reason_required');
      expect(verification.errorCode, isNot(correction.errorCode));
    });
  });

  group('a push batch we would send', () {
    test('survives a round trip through the wire form', () {
      final batch = wire['push_batch'] as Map<String, dynamic>;
      final operations = [
        for (final op in batch['operations'] as List)
          PendingOperation.fromJson(Map<String, dynamic>.from(op as Map)),
      ];

      expect(operations, hasLength(2));
      expect(operations.first.operationId, 'op_01J8ZC4T7M');
      expect(operations.first.entity, EntityKind.sighting);
      expect(operations.first.baseRevision, 0);
      expect(operations.last.dependsOn, 'op_01J8ZC4T6L');

      // Re-encoding must reproduce the same bytes, because a retry that
      // rebuilds the payload is a different operation wearing the same id.
      for (final op in operations) {
        expect(
          operationToWire(op)['payload'],
          op.payload,
          reason: 'a round trip must be lossless',
        );
      }
    });

    test('the second operation depends on one outside the batch', () {
      // A declared prerequisite may be an operation from an earlier push, so
      // depends_on is not necessarily resolvable from this batch alone.
      final batch = wire['push_batch'] as Map<String, dynamic>;
      final ids = {
        for (final op in batch['operations'] as List)
          (op as Map)['operation_id'] as String,
      };
      final dependsOn =
          (batch['operations'] as List)[1]['depends_on'] as String;
      expect(ids.contains(dependsOn), isFalse);
    });
  });

  group('reference data', () {
    late Map<String, dynamic> reference;

    setUpAll(() => reference = wire['reference_data'] as Map<String, dynamic>);

    test('every provisional species code is four uppercase letters or is flagged', () {
      // The contract says four uppercase letters. The design's own data uses
      // HIPPO, which is five. Rather than assert a rule the design breaks, the
      // test states what is actually true and names the exception, so that if
      // the codes are corrected the test says so.
      final species = reference['species'] as List;
      final odd = <String>{};
      for (final entry in species) {
        final code = (entry as Map)['code'] as String;
        final isFourUpper = code.length == 4 && code == code.toUpperCase();
        if (!isFourUpper) {
          odd.add(code);
        }
      }
      expect(odd, {'HIPPO', 'VOX'});
    });

    test('behaviour and age_sex_class are recorded as unsettled', () {
      // The contract enumerates rifle_role but not these two, so these lists are
      // the design prototype's, not the service's.
      expect(reference['_unsettled'], isNotEmpty);
      expect(reference['behaviour'], contains('drinking'));
      expect(reference['age_sex_class'], contains('adult_female'));
    });

    test('rifle_role is the one list the contract does enumerate', () {
      expect(reference['rifle_role'], ['first', 'second', 'none']);
    });
  });
}
