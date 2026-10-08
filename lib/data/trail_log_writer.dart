import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/tables.dart' show OperationState;
import 'package:field_log/models/sync_operation.dart';
import 'package:uuid/uuid.dart';

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
  TrailLogWriter._(this._db, this._queue, this._uuid);

  /// A writer with no [queue] is a local one: rows are written and nothing is
  /// queued. That mode exists for tests and library use; the app attaches a
  /// queue so every row and its route to the service are written together.
  factory TrailLogWriter(
    FieldLogDatabase db, {
    OperationQueue? queue,
    Uuid? uuid,
  }) => TrailLogWriter._(db, queue, uuid ?? const Uuid());

  final FieldLogDatabase _db;
  final OperationQueue? _queue;
  final Uuid _uuid;

  /// Start a log, returning its client-minted id.
  ///
  /// The id is a uuid rather than a local name because it is also the id the
  /// service will know the hike by: the queue pushes it as the entity id, and
  /// a `log-…` name would be refused as a malformed identifier.
  ///
  /// [rifleRole] and [walkLengthKm] are required because the service refuses a
  /// hike without them, so the form that starts a walk collects both where the
  /// facts are known — at the start — instead of demanding them later. With a
  /// queue attached, the hike's create is enqueued in the same transaction as
  /// the row: the row and its route to the service are one unit, and neither
  /// exists without the other.
  Future<String> startLog({
    required String driveId,
    required String contextCode,
    required String trailCode,
    required DateTime startedAt,
    required String rifleRole,
    required double walkLengthKm,
    String? localId,
  }) {
    return _db.transaction(() async {
      final id = localId ?? _uuid.v4();
      await _db
          .into(_db.trailLogs)
          .insert(
            TrailLogsCompanion.insert(
              localId: id,
              contextCode: contextCode,
              driveId: driveId,
              trailCode: trailCode,
              startedAt: startedAt,
              rifleRole: Value(rifleRole),
              walkLengthKm: Value(walkLengthKm),
              // A local log has never been seen by the service, so it has no
              // revision and no server id.
              revision: const Value(0),
              serverId: const Value(null),
            ),
          );

      final queue = _queue;
      if (queue == null) return id;
      final row = await (_db.select(
        _db.trailLogs,
      )..where((t) => t.localId.equals(id))).getSingle();
      await queue.enqueueNew(
        entityId: id,
        entity: EntityKind.trailLog,
        kind: OperationKind.create,
        baseRevision: 0,
        capturedAt: startedAt.toUtc(),
        recordedAt: DateTime.now().toUtc(),
        // trailCode is absent from the payload: the service's outing has no
        // such column, and sending keys it does not read would pretend an
        // agreement the contract does not make. See [hikeToState].
        payload: hikeToState(row),
      );
      return id;
    });
  }

  /// Append one position.
  ///
  /// The ordinal is assigned here as the current end of the sequence rather
  /// than being passed in, so a caller cannot insert at a position that would
  /// renumber what is already recorded.
  ///
  /// [serverId] is minted with the row so the row and its queued operation
  /// name the same entity; once the service accepts it, that same uuid comes
  /// back as its id. The operation waits for the hike's create to settle when
  /// the hike has not been accepted yet — a waypoint against a record the
  /// service has never heard of would be refused as a matter of course.
  Future<void> appendWaypoint({
    required String trailLogId,
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    double? accuracyMetres,
    double? elevationM,
    String? note,
  }) async {
    final next = await _nextOrdinal(trailLogId);
    final serverId = _uuid.v4();
    await _db
        .into(_db.trailWaypoints)
        .insert(
          TrailWaypointsCompanion.insert(
            trailLogId: trailLogId,
            ordinal: next,
            latitude: latitude,
            longitude: longitude,
            recordedAt: recordedAt,
            serverId: Value(serverId),
            accuracyMetres: Value(accuracyMetres),
            elevationM: Value(elevationM),
            note: Value(note),
          ),
        );

    final queue = _queue;
    if (queue == null) return;
    final log = await (_db.select(
      _db.trailLogs,
    )..where((t) => t.localId.equals(trailLogId))).getSingleOrNull();
    if (log == null) return;
    final create = await queue.unsettledCreate(trailLogId);
    if (create == null && log.serverId == null) {
      // The hike has no route to the service: it was written before this
      // writer carried a queue, or its create was refused. The waypoint stays
      // local rather than being sent against a record the service is certain
      // not to hold.
      return;
    }
    await queue.enqueueNew(
      entityId: serverId,
      entity: EntityKind.trailWaypoint,
      kind: OperationKind.create,
      baseRevision: 0,
      capturedAt: recordedAt.toUtc(),
      recordedAt: DateTime.now().toUtc(),
      payload: <String, dynamic>{
        'outing_id': trailLogId,
        'ordinal': next,
        'longitude': longitude,
        'latitude': latitude,
        'accuracy_m': ?accuracyMetres,
        'elevation_m': ?elevationM,
        'note': ?note,
        'captured_at': recordedAt.toUtc().toIso8601String(),
      },
      dependsOn: create?.operationId,
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
  /// Ending is not sealing. The contract keeps those apart for a reason, so
  /// this only records the end time and the log can still receive late
  /// waypoints from a walk that has finished but whose record is not yet
  /// closed to new observations.
  Future<void> endLog(String trailLogId, {required DateTime endedAt}) async {
    await (_db.update(_db.trailLogs)
          ..where((t) => t.localId.equals(trailLogId)))
        .write(TrailLogsCompanion(endedAt: Value(endedAt)));
  }

  /// Record what the walk turned into and queue the change.
  ///
  /// Every field is optional: a save that only ends the walk writes only the
  /// end. The payload queued alongside the row is sparse in the same way —
  /// see [hikeToState] — so the service applies exactly what the form knew
  /// about and nothing else.
  ///
  /// The row and the queue move in one transaction: a saved log whose
  /// operation was never written would be a change the client believes it has
  /// made and will never send.
  Future<void> save(
    String localId, {
    String? status,
    String? guideRole,
    String? rifleDetails,
    double? hoursWalked,
    String? description,
    String? lessonsLearned,
    String? weather,
    String? notes,
    DateTime? endedAt,
  }) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.trailLogs,
      )..where((t) => t.localId.equals(localId))).getSingleOrNull();
      if (existing == null) return;

      await (_db.update(
        _db.trailLogs,
      )..where((t) => t.localId.equals(localId))).write(
        TrailLogsCompanion(
          // Absent rather than null for a field the form did not change:
          // Value(null) would write a null over a fact the log already
          // has. Each field is written only when its argument arrived —
          // the same sparseness as the payload below.
          status: status == null ? const Value.absent() : Value(status),
          guideRole: guideRole == null
              ? const Value.absent()
              : Value(guideRole),
          rifleDetails: rifleDetails == null
              ? const Value.absent()
              : Value(rifleDetails),
          hoursWalked: hoursWalked == null
              ? const Value.absent()
              : Value(hoursWalked),
          description: description == null
              ? const Value.absent()
              : Value(description),
          lessonsLearned: lessonsLearned == null
              ? const Value.absent()
              : Value(lessonsLearned),
          weather: weather == null ? const Value.absent() : Value(weather),
          notes: notes == null ? const Value.absent() : Value(notes),
          endedAt: endedAt == null
              ? const Value.absent()
              : Value(endedAt.toUtc()),
        ),
      );

      await _sync(localId);
    });
  }

  /// Queue whatever operation the row's current state calls for.
  ///
  /// Runs inside [save]'s transaction so the row and its queue entry commit
  /// together. The decision is made from what the queue already holds rather
  /// than from guesswork: a create still waiting is rewritten in place, an
  /// in-flight create gets an update behind it, and an accepted log gets an
  /// update against the revision the service holds.
  Future<void> _sync(String localId) async {
    final queue = _queue;
    if (queue == null) return;
    final row = await (_db.select(
      _db.trailLogs,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    if (row == null) return;
    final payload = hikeToState(row);
    final now = DateTime.now().toUtc();

    final create = await queue.unsettledCreate(localId);
    if (create != null) {
      if (create.state == OperationState.pending) {
        await queue.replacePendingCreate(
          entity: EntityKind.trailLog,
          entityId: localId,
          payload: payload,
        );
        return;
      }
      // In flight: the create's bytes may already be on the wire, so they are
      // not rewritten under it. The update waits behind it instead, against
      // the revision the create will land at — a fresh create always lands at
      // revision 1. If the create is refused instead, the update is refused
      // as unknown_outing and the ledger says so plainly.
      await queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.trailLog,
        kind: OperationKind.update,
        baseRevision: 1,
        capturedAt: row.startedAt,
        recordedAt: now,
        payload: payload,
        dependsOn: create.operationId,
      );
      return;
    }

    if (row.serverId == null) {
      // Never accepted. The create is only worth queueing once the record is
      // one the service can take: without a rifle role or a walk length its
      // refusal is certain, and a certain refusal belongs in the ledger only
      // after it has actually happened.
      if (row.rifleRole == null ||
          row.walkLengthKm == null ||
          row.walkLengthKm! <= 0) {
        return;
      }
      await queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.trailLog,
        kind: OperationKind.create,
        baseRevision: 0,
        capturedAt: row.startedAt,
        recordedAt: now,
        payload: payload,
      );
      return;
    }

    // Accepted before, so this is an update. Two saves before the first one
    // reaches the service are one update, not two that would race each
    // other's revisions.
    if (await queue.replacePendingUpdate(
      entity: EntityKind.trailLog,
      entityId: localId,
      payload: payload,
    )) {
      return;
    }
    final inflight = await queue.unsettledUpdate(localId);
    await queue.enqueueNew(
      entityId: localId,
      entity: EntityKind.trailLog,
      kind: OperationKind.update,
      // When an update is on the wire it will land one revision above what
      // this client holds, so the follower names that revision. If the
      // in-flight one is refused instead, this one is refused as a revision
      // conflict, which is the truth: the record moved somewhere else.
      baseRevision: inflight == null ? row.revision : row.revision + 1,
      capturedAt: row.startedAt,
      recordedAt: now,
      payload: payload,
      dependsOn: inflight?.operationId,
    );
  }

  /// The position after the last recorded one.
  ///
  /// Deliberately derived from the data rather than held in a counter, because
  /// a counter is a second answer to the same question as the rows themselves
  /// and would be free to disagree with them after a failed write.
  Future<int> _nextOrdinal(String trailLogId) async {
    final row =
        await (_db.selectOnly(_db.trailWaypoints)
              ..addColumns([_db.trailWaypoints.ordinal.max()])
              ..where(_db.trailWaypoints.trailLogId.equals(trailLogId)))
            .getSingle();
    final highest = row.read(_db.trailWaypoints.ordinal.max());
    return highest == null ? 0 : highest + 1;
  }
}
