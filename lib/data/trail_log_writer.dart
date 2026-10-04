import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';

/// The path walked, written one waypoint at a time.
///
/// This class has no method that edits or deletes a waypoint, and that absence
/// is the design. The contract is explicit:
///
/// > "Appends are additive; a trail log is not rewritten, because the sequence
/// > of observations is itself the record. This is the one entity where
/// > ordering is the content, so a revision conflict on a waypoint list is
/// > resolved by appending rather than by refusing."
///
/// An API that offered `updateWaypoint` or `deleteWaypoint` would be an offer
/// somebody would eventually accept, and the acceptance would be invisible. So
/// the capability is absent rather than merely discouraged. The table's
/// composite primary key of (trailLogId, ordinal) enforces the same rule one
/// level down: there is no surrogate key to renumber.
class TrailLogWriter {
  TrailLogWriter(this._db);

  final FieldLogDatabase _db;

  /// Start a log, returning its client-minted id.
  ///
  /// The id is minted here rather than by the caller so that the queue can name
  /// the log in the same breath as the first waypoint appended to it.
  Future<String> startLog({
    required String driveId,
    required String contextCode,
    required String trailCode,
    required DateTime startedAt,
    String? localId,
  }) async {
    final id = localId ?? _mintId();
    await _db
        .into(_db.trailLogs)
        .insert(
          TrailLogsCompanion.insert(
            localId: id,
            contextCode: contextCode,
            driveId: driveId,
            trailCode: trailCode,
            startedAt: startedAt,
            // A local log has never been seen by the service, so it has no
            // revision and no server id.
            revision: const Value(0),
            serverId: const Value(null),
          ),
        );
    return id;
  }

  /// Append one position.
  ///
  /// The ordinal is assigned here as the current end of the sequence rather than
  /// being passed in, so a caller cannot insert at a position that would
  /// renumber what is already recorded.
  Future<void> appendWaypoint({
    required String trailLogId,
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    double? accuracyMetres,
    String? note,
  }) async {
    final next = await _nextOrdinal(trailLogId);
    await _db
        .into(_db.trailWaypoints)
        .insert(
          TrailWaypointsCompanion.insert(
            trailLogId: trailLogId,
            ordinal: next,
            latitude: latitude,
            longitude: longitude,
            recordedAt: recordedAt,
            accuracyMetres: Value(accuracyMetres),
            note: Value(note),
          ),
        );
  }

  /// The whole path, in the order it was walked.
  Future<List<TrailWaypoint>> pathOf(String trailLogId) {
    return (_db.select(_db.trailWaypoints)
          ..where((t) => t.trailLogId.equals(trailLogId))
          ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
        .get();
  }

  /// How many waypoints a log holds.
  Future<int> lengthOf(String trailLogId) async {
    final query = _db.selectOnly(_db.trailWaypoints)
      ..addColumns([_db.trailWaypoints.ordinal.count()])
      ..where(_db.trailWaypoints.trailLogId.equals(trailLogId));
    final row = await query.getSingle();
    return row.read(_db.trailWaypoints.ordinal.count()) ?? 0;
  }

  /// Close a log.
  ///
  /// Ending is not sealing. The contract keeps those apart for a reason, so this
  /// only records the end time and the log can still receive late waypoints from
  /// a walk that has finished but whose record is not yet closed to new
  /// observations.
  Future<void> endLog(String trailLogId, {required DateTime endedAt}) async {
    await (_db.update(_db.trailLogs)
          ..where((t) => t.localId.equals(trailLogId)))
        .write(TrailLogsCompanion(endedAt: Value(endedAt)));
  }

  /// The position after the last recorded one.
  ///
  /// Deliberately derived from the data rather than held in a counter, because a
  /// counter is a second answer to the same question as the rows themselves and
  /// would be free to disagree with them after a failed write.
  Future<int> _nextOrdinal(String trailLogId) async {
    final row =
        await (_db.selectOnly(_db.trailWaypoints)
              ..addColumns([_db.trailWaypoints.ordinal.max()])
              ..where(_db.trailWaypoints.trailLogId.equals(trailLogId)))
            .getSingle();
    final highest = row.read(_db.trailWaypoints.ordinal.max());
    return highest == null ? 0 : highest + 1;
  }

  static int _nextSerial = 0;

  String _mintId() {
    // A timestamp plus a per-process counter. Unique within a device without
    // pulling in a uuid dependency for the one identifier that only has to be
    // unique locally: it is replaced by the service's own id on acceptance.
    _nextSerial++;
    return 'log-${DateTime.now().microsecondsSinceEpoch}-$_nextSerial';
  }
}
