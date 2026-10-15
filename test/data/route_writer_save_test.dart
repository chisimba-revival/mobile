import 'package:drift/native.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/route_writer.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

FieldLogDatabase _memoryStore() =>
    FieldLogDatabase(NativeDatabase.memory(logStatements: false));

/// A database as schema 4 left it: `planned_routes.outing_id` carried a foreign
/// key to `drives`, which is exactly the constraint schema 5 removes.
///
/// The rest of the schema is taken from a freshly created v5 database so this
/// fixture does not drift from the real one; only `planned_routes` is replaced
/// with its v4 shape, and the version is set back to 4 so opening it exercises
/// the upgrade.
const _plannedRoutesV4 = '''
  CREATE TABLE planned_routes (
    local_id TEXT NOT NULL,
    server_id TEXT NULL,
    outing_id TEXT NOT NULL REFERENCES drives (local_id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    revision INTEGER NOT NULL DEFAULT 0,
    has_pending_changes INTEGER NOT NULL DEFAULT 0,
    is_tombstone INTEGER NOT NULL DEFAULT 0,
    deleted_at INTEGER NULL,
    PRIMARY KEY (local_id)
  );
''';

Future<FieldLogDatabase> _v4Store() async {
  final template = _memoryStore();
  await template.customSelect('SELECT 1').get();
  final rows = await template
      .customSelect(
        "SELECT sql FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' AND name != 'planned_routes';",
      )
      .get();
  final statements = rows
      .map((r) => r.read<String>('sql'))
      .toList(growable: false);
  await template.close();

  final upgraded = FieldLogDatabase(
    NativeDatabase.memory(
      logStatements: false,
      setup: (db) {
        db.execute(_plannedRoutesV4);
        for (final statement in statements) {
          db.execute(statement);
        }
        // A route saved under schema 4, owned by a drive that does exist. The
        // upgrade must carry it across untouched.
        db.execute(
          "INSERT INTO drives (local_id, context_code, started_at) "
          "VALUES ('drive-1', 'kiswahili', 0);",
        );
        db.execute(
          "INSERT INTO planned_routes (local_id, outing_id, created_at, updated_at) "
          "VALUES ('route-old', 'drive-1', 0, 0);",
        );
        db.execute('PRAGMA user_version = 4;');
      },
    ),
  );
  // The first query opens the database and runs the v4 -> v5 upgrade.
  await upgraded.customSelect('SELECT 1').get();
  return upgraded;
}

List<RouteWaypoint> _twoWaypoints(String routeId) => [
  RouteWaypoint(
    routeId: routeId,
    ordinal: 0,
    latitude: -25.29,
    longitude: 30.79,
    label: 'start',
    kind: 'vertex',
    revision: 0,
    isTombstone: false,
  ),
  RouteWaypoint(
    routeId: routeId,
    ordinal: 1,
    latitude: -25.30,
    longitude: 30.80,
    label: 'end',
    kind: 'vertex',
    revision: 0,
    isTombstone: false,
  ),
];

void main() {
  late FieldLogDatabase db;
  late OperationQueue queue;
  late RouteWriter writer;

  setUp(() {
    db = _memoryStore();
    queue = OperationQueue(db);
    writer = RouteWriter(db, queue, 'kiswahili');
  });
  tearDown(() => db.close());

  test(
    'a route for an outing with no drives row is saved and queued',
    () async {
      // The outing is one the service lists: the client holds no drives row for
      // it, only reference data. The route must still be written.
      await writer.saveRoute(
        outingId: 'service-outing-1',
        routeLocalId: 'route-1',
        waypoints: _twoWaypoints('route-1'),
      );

      final routes = await db.select(db.plannedRoutes).get();
      expect(routes, hasLength(1));
      expect(routes.single.outingId, 'service-outing-1');
      expect(routes.single.isTombstone, isFalse);

      final waypoints = await db.select(db.routeWaypoints).get();
      expect(waypoints, hasLength(2));
      expect(waypoints.map((w) => w.ordinal).toList()..sort(), [0, 1]);

      final pending = await queue.pending();
      expect(pending, hasLength(3));
      expect(
        pending.where((p) => p.entity == EntityKind.plannedRoute),
        hasLength(1),
      );
      expect(
        pending.where((p) => p.entity == EntityKind.routeWaypoint),
        hasLength(2),
      );
      expect(pending.every((p) => p.kind == OperationKind.create), isTrue);
    },
  );

  test(
    'saving again replaces the outing route rather than piling up',
    () async {
      await writer.saveRoute(
        outingId: 'outing-1',
        routeLocalId: 'route-1',
        waypoints: _twoWaypoints('route-1'),
      );
      await writer.saveRoute(
        outingId: 'outing-1',
        routeLocalId: 'route-2',
        waypoints: _twoWaypoints('route-2'),
      );

      final live = await (db.select(
        db.plannedRoutes,
      )..where((t) => t.isTombstone.equals(false))).get();
      expect(live, hasLength(1));
      expect(live.single.localId, 'route-2');

      // The replaced route is tombstoned and queued as a delete, not erased.
      final replaced = await (db.select(
        db.plannedRoutes,
      )..where((t) => t.localId.equals('route-1'))).getSingle();
      expect(replaced.isTombstone, isTrue);
      final deletions = (await queue.pending())
          .where((p) => p.kind == OperationKind.delete)
          .toList();
      expect(deletions, hasLength(1));
      expect(deletions.single.entityId, 'route-1');
    },
  );

  test('a v4 database upgrades and then saves a route for any outing', () async {
    final upgraded = await _v4Store();
    addTearDown(upgraded.close);
    final upgradedQueue = OperationQueue(upgraded);
    final upgradedWriter = RouteWriter(upgraded, upgradedQueue, 'kiswahili');

    // Schema 4 keyed the route's outing to drives; schema 5 drops that key so a
    // route can name an outing the client has no drives row for.
    final foreignKeys = await upgraded
        .customSelect('PRAGMA foreign_key_list(planned_routes)')
        .get();
    expect(foreignKeys, isEmpty);

    // The route the v4 database already held survived the table re-creation.
    final existing = await (upgraded.select(
      upgraded.plannedRoutes,
    )..where((t) => t.localId.equals('route-old'))).getSingle();
    expect(existing.outingId, 'drive-1');

    await upgradedWriter.saveRoute(
      outingId: 'service-outing-1',
      routeLocalId: 'route-1',
      waypoints: _twoWaypoints('route-1'),
    );
    expect(await upgraded.select(upgraded.plannedRoutes).get(), hasLength(2));
    expect(await upgraded.select(upgraded.routeWaypoints).get(), hasLength(2));
  });
}
