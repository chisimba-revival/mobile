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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
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
