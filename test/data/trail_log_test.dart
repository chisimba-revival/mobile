import 'package:drift/native.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/trail_log_writer.dart';
import 'package:flutter_test/flutter_test.dart';

FieldLogDatabase _memoryStore() =>
    FieldLogDatabase(NativeDatabase.memory(logStatements: false));

final _start = DateTime.utc(2026, 10, 4, 6, 0);

void main() {
  late FieldLogDatabase db;
  late TrailLogWriter writer;

  setUp(() {
    db = _memoryStore();
    writer = TrailLogWriter(db);
  });
  tearDown(() => db.close());

  Future<String> aWalk() => writer.startLog(
    driveId: 'drive-1',
    contextCode: 'kiswahili',
    trailCode: 'TRL-04',
    startedAt: _start,
    // The service refuses a hike without both, so the start form collects
    // them; the writer takes the same pair.
    rifleRole: 'second',
    walkLengthKm: 4.2,
  );

  group('the path walked', () {
    test('is recorded in the order it was walked', () async {
      final id = await aWalk();
      for (var step = 0; step < 4; step++) {
        await writer.appendWaypoint(
          trailLogId: id,
          latitude: -1.2921 - step * 0.001,
          longitude: 36.8219 + step * 0.001,
          recordedAt: _start.add(Duration(minutes: step)),
        );
      }

      final path = await writer.pathOf(id);
      expect(path, hasLength(4));
      expect(path.map((w) => w.ordinal), [
        0,
        1,
        2,
        3,
      ], reason: 'the sequence is the record, so it must read in order');
      // Latitude increases with the step, so the stored order is the walked
      // order rather than merely ascending by accident.
      expect(
        path.first.latitude,
        greaterThan(path.last.latitude),
        reason: 'the walk runs south, so latitude falls as the ordinal rises',
      );
    });

    test('cannot be renumbered, because the position is the identity', () async {
      final id = await aWalk();
      await writer.appendWaypoint(
        trailLogId: id,
        latitude: 1,
        longitude: 1,
        recordedAt: _start,
      );

      // There is no update method, so an attempt to renumber has to go through
      // the database directly. It fails, because (trailLogId, ordinal) is the
      // primary key: a second row cannot claim the same position, and there is
      // no surrogate key to move the existing one under.
      await expectLater(
        db
            .into(db.trailWaypoints)
            .insert(
              TrailWaypointsCompanion.insert(
                trailLogId: id,
                ordinal: 0,
                latitude: 2,
                longitude: 2,
                recordedAt: _start,
              ),
            ),
        throwsA(anything),
        reason: 'a waypoint may not be replaced in place',
      );

      expect(await writer.lengthOf(id), 1);
    });

    test('appends after a correction rather than over it', () async {
      final id = await aWalk();
      await writer.appendWaypoint(
        trailLogId: id,
        latitude: 1,
        longitude: 1,
        recordedAt: _start,
      );
      // The trainee realises the position was wrong. The contract forbids
      // rewriting the log, so the honest move is another waypoint saying so.
      await writer.appendWaypoint(
        trailLogId: id,
        latitude: 1.5,
        longitude: 1.5,
        recordedAt: _start.add(const Duration(minutes: 1)),
        note: 'Position above was wrong. This is where we actually stood.',
      );

      final path = await writer.pathOf(id);
      expect(path, hasLength(2));
      expect(path.first.note, equals(null), reason: 'the original stands');
      expect(path.last.note, contains('actually stood'));
    });

    test(
      'carries accuracy as measured rather than as a tidier number',
      () async {
        final id = await aWalk();
        await writer.appendWaypoint(
          trailLogId: id,
          latitude: 1,
          longitude: 1,
          recordedAt: _start,
          accuracyMetres: 6.4,
        );

        final waypoint = (await writer.pathOf(id)).single;
        expect(waypoint.accuracyMetres, 6.4);
      },
    );

    test('keeps a note that names nothing', () async {
      final id = await aWalk();
      await writer.appendWaypoint(
        trailLogId: id,
        latitude: 1,
        longitude: 1,
        recordedAt: _start,
        note: 'Could not say whose. Fresh, heading north.',
      );

      expect((await writer.pathOf(id)).single.note, contains('Could not say'));
    });
  });

  group('ending a walk', () {
    test('records when it ended without closing it to late waypoints', () async {
      final id = await aWalk();
      final ended = _start.add(const Duration(hours: 3));
      await writer.endLog(id, endedAt: ended);

      final log = await (db.select(
        db.trailLogs,
      )..where((t) => t.localId.equals(id))).getSingle();
      // The instant survives the round trip; the UTC flag does not, so the
      // comparison is between moments rather than between DateTime objects.
      expect(log.endedAt!.isAtSameMomentAs(ended), isTrue);

      // Ending is not sealing. A logbook is not closed to a late observation by
      // the walk finishing.
      await writer.appendWaypoint(
        trailLogId: id,
        latitude: 2,
        longitude: 2,
        recordedAt: ended.add(const Duration(minutes: 5)),
      );
      expect(await writer.lengthOf(id), 1);
    });
  });

  group('a local log', () {
    test(
      'has no server id and no revision until the service accepts it',
      () async {
        final id = await aWalk();
        final log = await (db.select(
          db.trailLogs,
        )..where((t) => t.localId.equals(id))).getSingle();

        expect(log.serverId, equals(null));
        expect(log.revision, 0);
      },
    );
  });
}
