import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/trail_log_writer.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

FieldLogDatabase _memoryStore() =>
    FieldLogDatabase(NativeDatabase.memory(logStatements: false));

void main() {
  late FieldLogDatabase db;
  late OperationQueue queue;
  late TrailLogWriter writer;

  setUp(() {
    db = _memoryStore();
    queue = OperationQueue(db);
    writer = TrailLogWriter(db, queue: queue);
  });
  tearDown(() => db.close());

  final start = DateTime.utc(2026, 10, 4, 6);

  Future<String> aWalk() => writer.startLog(
    driveId: 'drive-1',
    contextCode: 'kiswahili',
    trailCode: 'TRL-04',
    startedAt: start,
    rifleRole: 'second',
    walkLengthKm: 4.2,
  );

  test('a local trail is written without queuing anything', () async {
    final local = TrailLogWriter(db);
    final id = await local.startLog(
      driveId: 'drive-1',
      contextCode: 'kiswahili',
      trailCode: 'TRL-04',
      startedAt: start,
      rifleRole: 'second',
      walkLengthKm: 4.2,
    );
    expect(await queue.pending(), isEmpty);
    final row = await (db.select(
      db.trailLogs,
    )..where((t) => t.localId.equals(id))).getSingle();
    expect(row.serverId, isNull);
  });

  test('the first save with the required facts queues one create', () async {
    await aWalk();

    final pending = await queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.entity, EntityKind.trailLog);
    expect(pending.single.kind, OperationKind.create);
    final payload = jsonDecode(pending.single.payload) as Map<String, dynamic>;
    expect(payload['outing_kind'], 'hike');
    expect(payload['rifle_role'], 'second');
    expect(payload['walk_length_km'], 4.2);
  });

  test('a save without new facts is absorbed, not doubled', () async {
    final id = await aWalk();
    await writer.save(id, status: 'completed');

    final pending = await queue.pending();
    expect(
      pending,
      hasLength(1),
      reason: 'the waiting create is rewritten in place',
    );
  });

  test('two saves before the create sends are one operation', () async {
    final id = await aWalk();
    await writer.save(id, guideRole: 'lead');
    await writer.save(id, rifleDetails: 'scope');

    final pending = await queue.pending();
    expect(
      pending,
      hasLength(1),
      reason: 'the waiting create is rewritten, not appended',
    );
    final payload = jsonDecode(pending.single.payload) as Map<String, dynamic>;
    expect(payload['guide_role'], 'lead');
    expect(payload['rifle_details'], 'scope');
  });

  test(
    'once accepted, a save queues an update against the held revision',
    () async {
      final id = await aWalk();
      final create = (await queue.pending()).single;

      await queue.recordResult(
        PushResult(
          operationId: create.operationId,
          outcome: PushOutcome.applied,
          newRevision: 1,
        ),
      );
      await (db.update(db.trailLogs)..where((t) => t.localId.equals(id))).write(
        const TrailLogsCompanion(serverId: Value('srv-1'), revision: Value(1)),
      );

      await writer.save(id, notes: 'changed my mind');

      final pending = await queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.kind, OperationKind.update);
      expect(
        pending.single.baseRevision,
        1,
        reason: 'the update names the revision the service holds',
      );
      final payload =
          jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(payload['notes'], 'changed my mind');
    },
  );
}
