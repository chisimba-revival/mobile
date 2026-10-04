import 'package:field_log/models/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a push batch is not all or nothing', () {
    test('every outcome a client can be handed is modelled', () {
      expect(PushOutcome.values, hasLength(4));
      expect(PushOutcome.values.map((PushOutcome o) => o.name), <String>[
        'applied',
        'noop',
        'deferred',
        'refused',
      ]);
    });

    test('deferred and refused are not terminal', () {
      // Deferred re-queues. Refused needs a person. Neither is done, and a
      // client that treated either as settled would drop the observation.
      expect(PushOutcome.deferred.isTerminal, isFalse);
      expect(PushOutcome.refused.isTerminal, isFalse);
      expect(PushOutcome.applied.isTerminal, isTrue);
      expect(PushOutcome.noop.isTerminal, isTrue);
    });

    test('a no-op retry is not a failure', () {
      // Retrying after an ambiguous response lands here. Reporting it as a
      // conflict would train a client to retry forever.
      const result = PushResult(operationId: 'op-1', outcome: PushOutcome.noop);
      expect(result.outcome, PushOutcome.noop);
      expect(result.errorCode, isNull);
      expect(result.isConflict, isFalse);
    });
  });

  group('a refusal carries both sides', () {
    test(
      'a revision conflict is distinguishable from a validation refusal',
      () {
        const conflict = PushResult(
          operationId: 'op-2',
          outcome: PushOutcome.refused,
          errorCode: 'revision_conflict',
          serverRevision: 7,
          serverState: <String, dynamic>{'count': 5},
        );
        const validation = PushResult(
          operationId: 'op-3',
          outcome: PushOutcome.refused,
          errorCode: 'notes_too_long',
        );
        expect(conflict.isConflict, isTrue);
        expect(validation.isConflict, isFalse);
        expect(conflict.serverState, isNotNull);
      },
    );

    test('a refusal round-trips with its server state intact', () {
      const original = PushResult(
        operationId: 'op-4',
        outcome: PushOutcome.refused,
        errorCode: 'revision_conflict',
        serverRevision: 12,
        serverState: <String, dynamic>{'species_code': 'KOPH', 'count': 4},
      );
      expect(PushResult.fromJson(original.toJson()), original);
    });
  });

  group('an applied operation reports the revision it produced', () {
    test('newRevision is carried', () {
      const result = PushResult(
        operationId: 'op-5',
        outcome: PushOutcome.applied,
        newRevision: 8,
      );
      expect(result.newRevision, 8);
      expect(PushResult.fromJson(result.toJson()).newRevision, 8);
    });
  });

  group('a queued operation carries what conflict resolution needs', () {
    PendingOperation build({
      String? dependsOn,
      DateTime? recordedAt,
      int baseRevision = 3,
    }) {
      return PendingOperation(
        operationId: 'op-6',
        entityId: 'device-entity-1',
        entity: EntityKind.sighting,
        kind: OperationKind.update,
        baseRevision: baseRevision,
        capturedAt: DateTime.utc(2026, 10, 4, 5, 42),
        recordedAt: recordedAt ?? DateTime.utc(2026, 10, 4, 9, 15),
        dependsOn: dependsOn,
        payload: <String, dynamic>{'notes': 'Moving east.'},
      );
    }

    test('base_revision is present and is not a timestamp', () {
      // Rule 6: conflicts are decided by revision, never by comparing
      // timestamps. So the revision is carried explicitly and separately.
      final operation = build();
      expect(operation.baseRevision, 3);
      expect(operation.baseRevision, isNot(isA<DateTime>()));
    });

    test('depends_on is optional but carried when present', () {
      expect(build().dependsOn, isNull);
      expect(build(dependsOn: 'op-5').dependsOn, 'op-5');
    });

    test('an operation round-trips', () {
      final operation = build(dependsOn: 'op-5', baseRevision: 0);
      expect(PendingOperation.fromJson(operation.toJson()), operation);
    });

    test('the operation kind is an intent, not a replacement', () {
      // A whole-entity replacement is a last-writer-wins edit in disguise.
      expect(OperationKind.values.map((OperationKind k) => k.name), <String>[
        'create',
        'update',
        'delete',
        'start',
        'end',
        'verify',
      ]);
      // A whole-entity replacement is a last-writer-wins edit in disguise, so
      // there is deliberately no such kind: asserted by name, because referring
      // to a non-existent constant would not compile.
      expect(
        OperationKind.values.map((OperationKind k) => k.name),
        isNot(contains('replace')),
      );
      expect(
        OperationKind.values.map((OperationKind k) => k.name),
        isNot(contains('replaced')),
      );
    });
  });

  group('a deletion arrives as a tombstone', () {
    test('a tombstone is distinguishable from a change', () {
      const tombstone = PullChange(
        entity: EntityKind.sighting,
        entityId: 'device-entity-1',
        revision: 9,
        isTombstone: true,
      );
      final restored = PullChange.fromJson(tombstone.toJson());
      expect(restored.isTombstone, isTrue);
      expect(restored.state, isNull);
      expect(restored.entity, EntityKind.sighting);
    });

    test('a page reports whether more remains', () {
      final page = PullPage(
        changes: <PullChange>[],
        nextCursor: 'cursor-2',
        hasMore: true,
        serverTime: DateTime.utc(2026, 10, 4, 12),
      );
      final restored = PullPage.fromJson(page.toJson());
      expect(restored.hasMore, isTrue);
      expect(restored.nextCursor, 'cursor-2');
      expect(restored.serverTime, DateTime.utc(2026, 10, 4, 12));
    });
  });
}
