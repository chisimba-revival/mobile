import 'dart:convert';

import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/push_engine.dart';
import 'package:field_log/data/tables.dart';
import 'package:field_log/models/geo_point.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pull_engine_test.dart' show memoryStore, pendingSighting;

final captured = DateTime.utc(2026, 10, 4, 6, 30);
final recorded = DateTime.utc(2026, 10, 4, 18, 5);

PendingOperation anOperation({
  String operationId = 'op-1',
  String entityId = 'local-1',
  OperationKind kind = OperationKind.create,
  int baseRevision = 0,
  String? dependsOn,
  Map<String, dynamic>? payload,
}) {
  return PendingOperation(
    operationId: operationId,
    entityId: entityId,
    entity: EntityKind.sighting,
    kind: kind,
    baseRevision: baseRevision,
    capturedAt: captured,
    recordedAt: recorded,
    dependsOn: dependsOn,
    payload: payload ?? {'notes': 'three on the track'},
  );
}

void main() {
  group('a batch is not all-or-nothing', () {
    test('one refusal leaves its neighbours settled', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final queue = OperationQueue(db);
      await queue.enqueue(anOperation(operationId: 'op-good'));
      await queue.enqueue(anOperation(operationId: 'op-bad', baseRevision: 2));

      final report = await PushEngine(db, queue).push(
        send: (batch) async => [
          PushResult(
            operationId: 'op-good',
            outcome: PushOutcome.applied,
            newRevision: 4,
          ),
          PushResult(
            operationId: 'op-bad',
            outcome: PushOutcome.refused,
            errorCode: 'revision_conflict',
            serverRevision: 7,
            serverState: const {'id': 'srv-9', 'revision': 7},
          ),
        ],
      );

      expect(report.applied, 1);
      expect(report.refused, 1);
      expect(report.conflictsRetained, 1);

      // The refusal is settled, not left to fail again on every push.
      expect((await queue.byId('op-bad'))?.state, OperationState.settled);
      expect((await queue.byId('op-good'))?.state, OperationState.settled);
    });
  });

  group('a reused operation id', () {
    test('is a no-op rather than a conflict', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final queue = OperationQueue(db);
      await db.into(db.sightings).insert(pendingSighting());
      await queue.enqueue(anOperation());

      final report = await PushEngine(db, queue).push(
        send: (batch) async => [
          // What a retry after an ambiguous response looks like.
          PushResult(
            operationId: 'op-1',
            outcome: PushOutcome.noop,
            serverRevision: 4,
            serverState: const {'id': 'srv-1', 'revision': 4},
          ),
        ],
      );

      expect(report.noop, 1);
      expect(report.refused, 0);
      expect(report.conflictsRetained, 0);
      expect(await db.select(db.conflicts).get(), isEmpty);

      final row = await (db.select(
        db.sightings,
      )..where((t) => t.localId.equals('local-1'))).getSingle();
      expect(row.revision, 4);
      expect(row.serverId, 'srv-1');
      expect(row.hasPendingChanges, isFalse);
    });
  });

  group('a deferred operation', () {
    test('goes back to pending with its payload byte for byte', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final queue = OperationQueue(db);

      // The prerequisite settles first, otherwise nextBatch correctly declines
      // to send an operation whose dependency has not settled.
      await queue.enqueue(
        anOperation(operationId: 'op-drive', entityId: 'drive-1'),
      );
      await PushEngine(db, queue).push(
        send: (batch) async => [
          PushResult(
            operationId: 'op-drive',
            outcome: PushOutcome.applied,
            newRevision: 1,
          ),
        ],
      );

      final operation = anOperation(
        operationId: 'op-2',
        dependsOn: 'op-drive',
        payload: {'notes': 'a note with a quote in it: it\'s "fine"'},
      );
      await queue.enqueue(operation);

      // The bytes as they were first written.
      final before = (await queue.byId('op-2'))!.payload;

      await PushEngine(db, queue).push(
        send: (batch) async => const [
          PushResult(
            operationId: 'op-2',
            outcome: PushOutcome.deferred,
            errorCode: 'dependency_unsettled',
          ),
        ],
      );

      final row = await queue.byId('op-2');
      expect(row!.state, OperationState.pending);
      // Rebuilding the payload on a retry is how a deferral turns into a
      // different operation. These are the same bytes.
      expect(row.payload, before);
      expect(jsonDecode(row.payload), operation.payload);
      expect(row.attempts, 1, reason: 'an attempt was made');
    });
  });

  group('a refused verification', () {
    test('is kept for a person instead of being retried forever', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final queue = OperationQueue(db);
      await queue.enqueue(
        anOperation(kind: OperationKind.verify, baseRevision: 3),
      );

      await PushEngine(db, queue).push(
        send: (batch) async => const [
          PushResult(
            operationId: 'op-1',
            outcome: PushOutcome.refused,
            errorCode: 'stale_revision',
            serverRevision: 9,
          ),
        ],
      );

      final conflict = await db.select(db.conflicts).getSingle();
      expect(conflict.reason, 'verification_requires_a_person');
      expect(conflict.serverRevision, 9);
      expect(conflict.baseRevision, 3);
      expect(conflict.resolvedAt, equals(null));
    });
  });

  group('a missing result', () {
    test(
      'leaves the operation pending rather than dropping the change',
      () async {
        final db = memoryStore();
        addTearDown(db.close);
        final queue = OperationQueue(db);
        await queue.enqueue(anOperation());

        final report = await PushEngine(db, queue).push(
          // The contract says every operation gets exactly one outcome, so this is
          // a malformed response.
          send: (batch) async => const <PushResult>[],
        );

        expect(report.deferred, 1);
        final row = await queue.byId('op-1');
        expect(row!.state, OperationState.pending);
        expect(row.errorCode, 'no_result_returned');
      },
    );
  });

  group('an unreadable payload', () {
    test('is settled for a person rather than retried forever', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final queue = OperationQueue(db);

      await db
          .into(db.queuedOperations)
          .insert(
            QueuedOperationsCompanion.insert(
              operationId: 'op-broken',
              entityId: 'local-1',
              entity: EntityKind.sighting,
              kind: OperationKind.create,
              baseRevision: 0,
              capturedAt: captured,
              recordedAt: recorded,
              enqueuedAt: captured,
              payload: '{ this is not json',
            ),
          );

      var sent = 0;
      final report = await PushEngine(db, queue).push(
        send: (batch) async {
          sent += batch.length;
          return const <PushResult>[];
        },
      );

      expect(sent, 0, reason: 'unreadable bytes must not go on the wire');
      expect(report.unreadable, 1);

      final row = await queue.byId('op-broken');
      expect(row!.state, OperationState.settled);
      final conflict = await db.select(db.conflicts).getSingle();
      expect(conflict.errorCode, 'payload_unreadable');
    });
  });

  group('the wire form', () {
    test('carries the protocol fields the contract names', () {
      final wire = operationToWire(
        anOperation(dependsOn: 'op-drive', baseRevision: 2),
      );

      expect(wire['operation_id'], 'op-1');
      expect(wire['entity'], 'sighting');
      expect(wire['entity_id'], 'local-1');
      expect(wire['kind'], 'create');
      expect(wire['base_revision'], 2);
      expect(wire['depends_on'], 'op-drive');
      expect(wire['captured_at'], captured.toIso8601String());
      expect(wire['recorded_at'], recorded.toIso8601String());
      expect(wire['payload'], {'notes': 'three on the track'});
    });

    test('omits depends_on rather than sending null', () {
      final wire = operationToWire(anOperation());
      expect(wire.containsKey('depends_on'), isFalse);
    });

    test('keeps capture time and record time apart', () {
      final wire = operationToWire(anOperation());
      // Rule 13: these are different facts and neither stands in for the other.
      expect(wire['captured_at'], isNot(wire['recorded_at']));
    });
  });

  group('a sighting on the wire', () {
    test('carries location as a GeoJSON Point', () {
      final state = {
        ...{
          'id': 'local-1',
          'context_code': 'kiswahili',
          'drive_id': 'drive-1',
          'status': 'pending',
          'captured_at': captured.toIso8601String(),
          'recorded_at': recorded.toIso8601String(),
          'revision': 0,
          'created_by': 'usr_trainee',
        },
        'location': const GeoPoint(
          longitude: 36.8219,
          latitude: -1.2921,
        ).toGeoJson(),
      };
      expect(state['location'], {
        'type': 'Point',
        'coordinates': [36.8219, -1.2921],
      });
    });
  });

  group('a settled refusal', () {
    test('is not picked up by the next push', () async {
      final db = memoryStore();
      addTearDown(db.close);
      final queue = OperationQueue(db);
      await queue.enqueue(anOperation(operationId: 'op-1'));

      await PushEngine(db, queue).push(
        send: (batch) async => const [
          PushResult(
            operationId: 'op-1',
            outcome: PushOutcome.refused,
            errorCode: 'revision_conflict',
          ),
        ],
      );

      var offered = 0;
      final second = await PushEngine(db, queue).push(
        send: (batch) async {
          offered += batch.length;
          return const <PushResult>[];
        },
      );

      expect(
        offered,
        0,
        reason: 'the same bytes cannot be answered differently',
      );
      expect(second.hasOutstandingWork, isFalse);
      // The refusal is still on the ledger for a person, not discarded.
      expect((await queue.byId('op-1'))!.errorCode, 'revision_conflict');
    });
  });
}
