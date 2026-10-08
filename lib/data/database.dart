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
  int get schemaVersion => 4;

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
}
