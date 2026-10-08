import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/drive_writer.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

FieldLogDatabase _memoryStore() =>
    FieldLogDatabase(NativeDatabase.memory(logStatements: false));

void main() {
  late FieldLogDatabase db;
  late OperationQueue queue;
  late DriveWriter writer;

  setUp(() {
    db = _memoryStore();
    queue = OperationQueue(db);
    writer = DriveWriter(db, queue);
  });
  tearDown(() => db.close());

  final start = DateTime.utc(2026, 10, 4, 5, 30);

  Future<String> aStartedDrive() => writer.startDrive(
    contextCode: 'kiswahili',
    startedAt: start,
    guideId: 'usr_trainee',
    vehicleId: 'KAB 123X',
  );

  test('a started drive exists locally and queues nothing', () async {
    final id = await aStartedDrive();

    final row = await (db.select(
      db.drives,
    )..where((t) => t.localId.equals(id))).getSingle();
    expect(row.status, 'planned');
    expect(row.vehicleId, 'KAB 123X');
    expect(row.revision, 0);
    // The service refuses a create with no duration and no head count, so
    // queueing now would only manufacture a certain refusal.
    expect(await queue.pending(), isEmpty);
  });

  test(
    'a save without the facts the service needs still queues nothing',
    () async {
      final id = await aStartedDrive();
      await writer.save(id, status: 'active');
      await writer.save(id, weather: 'clear');
      expect(await queue.pending(), isEmpty);
    },
  );

  test('the first complete save queues one create', () async {
    final id = await aStartedDrive();
    await writer.save(
      id,
      status: 'completed',
      endedAt: DateTime.utc(2026, 10, 4, 11),
      durationHours: 5.5,
      guestCount: 2,
    );

    final pending = await queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.entity, EntityKind.drive);
    expect(pending.single.kind, OperationKind.create);
    final payload = jsonDecode(pending.single.payload) as Map<String, dynamic>;
    expect(payload['outing_kind'], 'drive');
    expect(payload['duration_hours'], 5.5);
    expect(payload['guest_count'], 2);
    expect(payload['vehicle_id'], 'KAB 123X');
  });

  test(
    'two saves before the create sends are one operation, not two',
    () async {
      final id = await aStartedDrive();
      await writer.save(
        id,
        durationHours: 5.5,
        guestCount: 2,
        weather: 'clear',
      );
      await writer.save(id, durationHours: 5.5, guestCount: 2, notes: 'dust');

      final pending = await queue.pending();
      expect(pending, hasLength(1), reason: 'the waiting create is rewritten');
      final payload =
          jsonDecode(pending.single.payload) as Map<String, dynamic>;
      expect(payload['notes'], 'dust');
      expect(payload['weather'], 'clear');
    },
  );

  test(
    'once accepted, a save queues an update against the held revision',
    () async {
      final id = await aStartedDrive();
      await writer.save(id, durationHours: 5.5, guestCount: 2);
      final create = (await queue.pending()).single;

      // The service took the create; the engine records that by settling the
      // operation and stamping the id and revision it answered with.
      await queue.recordResult(
        PushResult(
          operationId: create.operationId,
          outcome: PushOutcome.applied,
          newRevision: 1,
        ),
      );
      await (db.update(db.drives)..where((t) => t.localId.equals(id))).write(
        const DrivesCompanion(serverId: Value('srv-1'), revision: Value(1)),
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
