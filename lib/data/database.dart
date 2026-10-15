import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Imported for the generated part below. Drift emits the row classes into
// database.g.dart, which is a part of *this* file, so the enum types the
// columns are keyed by must be in scope here rather than only in tables.dart.
// A part shares this library's namespace, so importers of this file also see
// SightingRow, QueuedOperationRow and the rest.
import '../models/sighting.dart';
import '../models/sync_operation.dart';
import 'tables.dart';
import 'trail_log_tables.dart';
import 'route_tables.dart';

part 'database.g.dart';

/// The client's local store, which is the replica of record.
///
/// The service is something this database reconciles with, not the other way
/// round. Every rule that shapes this schema comes from that: the queue is
/// written before anything is attempted (rule 7), a deletion is a row and not an
/// absence (rule 9), capture time and record time are separate columns that
/// never stand in for each other (rule 13), and a cursor is only advanced once
/// the page it came with has been applied.
@DriftDatabase(
  tables: [
    Sightings,
    Drives,
    TrailLogs,
    TrailWaypoints,
    DangerousGameEncounters,
    PlannedRoutes,
    RouteWaypoints,
    QueuedOperations,
    Conflicts,
    SyncCursors,
    ReferenceData,
  ],
)
class FieldLogDatabase extends _$FieldLogDatabase {
  FieldLogDatabase(super.e);

  /// Opens the on-device database.
  ///
  /// Separate from the constructor above so tests can pass an in-memory
  /// connection without touching the filesystem, which is the only reason the
  /// executor is a parameter rather than being built here.
  factory FieldLogDatabase.open({String fileName = 'field_log.sqlite'}) {
    return FieldLogDatabase(_openConnection(fileName));
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Schema 2 added trail_waypoints.
      if (from < 2) {
        await m.createTable(trailWaypoints);
      }
      // Schema 3 added planned_routes and route_waypoints for outing route planning.
      if (from < 3) {
        await m.createTable(plannedRoutes);
        await m.createTable(routeWaypoints);
      }
      // Schema 4 carries the drive's logbook fields (vehicle, inspection,
      // hours and off-road rollup), the hike's fields (rifle role, guide role
      // and the rest), the waypoint's id and elevation, and the dangerous-game
      // encounter table. Every added column is nullable, so existing rows —
      // including a drive started before this schema existed — stay valid
      // without a default being invented for them.
      if (from < 4) {
        await m.addColumn(drives, drives.status);
        await m.addColumn(drives, drives.guideId);
        await m.addColumn(drives, drives.vehicleId);
        await m.addColumn(drives, drives.durationHours);
        await m.addColumn(drives, drives.guestCount);
        await m.addColumn(drives, drives.inspectionOilOk);
        await m.addColumn(drives, drives.inspectionWaterOk);
        await m.addColumn(drives, drives.inspectionTyresOk);
        await m.addColumn(drives, drives.daylightHours);
        await m.addColumn(drives, drives.nightHours);
        await m.addColumn(drives, drives.offRoadSeconds);
        await m.addColumn(drives, drives.offTrackUsed);
        await m.addColumn(drives, drives.weather);
        await m.addColumn(drives, drives.notes);

        await m.addColumn(trailLogs, trailLogs.status);
        await m.addColumn(trailLogs, trailLogs.rifleRole);
        await m.addColumn(trailLogs, trailLogs.guideRole);
        await m.addColumn(trailLogs, trailLogs.rifleDetails);
        await m.addColumn(trailLogs, trailLogs.walkLengthKm);
        await m.addColumn(trailLogs, trailLogs.hoursWalked);
        await m.addColumn(trailLogs, trailLogs.description);
        await m.addColumn(trailLogs, trailLogs.lessonsLearned);
        await m.addColumn(trailLogs, trailLogs.weather);

        await m.addColumn(trailWaypoints, trailWaypoints.serverId);
        await m.addColumn(trailWaypoints, trailWaypoints.elevationM);

        await m.createTable(dangerousGameEncounters);
      }
      // Schema 5 drops the foreign key on planned_routes.outing_id. A route can
      // be planned for an outing the client has no drives row for — an outing
      // the service lists lives only in reference data — and the key rejected
      // every such save with a foreign-key failure. The route still needs an
      // owner id; it does not need the owner's row to exist locally. The table
      // is re-created without the constraint (SQLite cannot drop one in place).
      if (from < 5) {
        // 8a54c9b added revision/deleted_at (planned_routes) and
        // revision/is_tombstone/deleted_at (route_waypoints) to the table
        // classes without a schema bump, so databases created before that commit
        // may be missing these columns entirely. Add whatever is missing before
        // rebuilding planned_routes, which copies every current column.
        await _ensureColumns(m, plannedRoutes, [
          plannedRoutes.revision,
          plannedRoutes.deletedAt,
        ]);
        await _ensureColumns(m, routeWaypoints, [
          routeWaypoints.revision,
          routeWaypoints.isTombstone,
          routeWaypoints.deletedAt,
        ]);
        await m.alterTable(TableMigration(plannedRoutes));
      }
    },
    beforeOpen: (details) async {
      // A client that has been offline long enough to receive a resync-required
      // must still be able to read its own queue, so foreign keys are enabled
      // only where they cannot strand a pending operation.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection(String fileName) {
    if (Platform.isAndroid || Platform.isIOS) {
      return LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        return NativeDatabase.createInBackground(
          File(p.join(dir.path, fileName)),
        );
      });
    }
    // Desktop and test runs. A file in the working directory keeps the door
    // open for inspecting a real database after a session.
    return LazyDatabase(() async {
      return NativeDatabase.createInBackground(File(fileName));
    });
  }

  /// Adds each column that [table] is missing, comparing against PRAGMA
  /// table_info. Drift's generated schema is the source of truth; this
  /// reconciles databases created before a column was added to a table class
  /// without a migration.
  Future<void> _ensureColumns(
    Migrator m,
    TableInfo table,
    Iterable<GeneratedColumn> columns,
  ) async {
    final existing = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    final names = existing.map((r) => r.read<String>('name')).toSet();
    for (final column in columns) {
      if (!names.contains(column.name)) {
        await m.addColumn(table, column);
      }
    }
  }
}
