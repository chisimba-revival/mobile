import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:field_log/data/tables.dart';
import 'package:uuid/uuid.dart';

/// Writes a drive's logbook record and queues it, in one transaction.
///
/// A drive starts before it can be described: the service will not accept a
/// drive without a duration and a guest count, so [startDrive] writes a local
/// row and queues nothing — an operation the service is certain to refuse
/// would only manufacture a conflict. [save] is the moment the record becomes
/// sendable: it writes the columns and then queues a create, an update, or a
/// rewrite of whichever of those is still waiting, whichever is the truth.
class DriveWriter {
  DriveWriter(this._db, this._queue, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final FieldLogDatabase _db;
  final OperationQueue _queue;
  final Uuid _uuid;

  /// Begin a drive: the row exists from the first moment so a route or a
  /// capture can name it.
  ///
  /// Nothing is queued here. The service requires a duration and a guest
  /// count on the create, and a drive just started has neither.
  Future<String> startDrive({
    required String contextCode,
    required DateTime startedAt,
    String? guideId,
    String? vehicleId,
  }) async {
    final localId = _uuid.v4();
    await _db
        .into(_db.drives)
        .insert(
          DrivesCompanion.insert(
            localId: localId,
            contextCode: contextCode,
            startedAt: startedAt.toUtc(),
            guideId: Value(guideId),
            vehicleId: Value(vehicleId),
            status: const Value('planned'),
            revision: const Value(0),
            serverId: const Value(null),
          ),
        );
    return localId;
  }

  /// Record what the drive turned into and queue the change.
  ///
  /// Every field is optional: a save that only ends the drive writes only the
  /// end. The payload queued alongside the row is sparse in the same way —
  /// see [driveToState] — so the service applies exactly what this form knew
  /// about and nothing else.
  ///
  /// The row and the queue move in one transaction: a saved drive whose
  /// operation was never written would be a change the client believes it has
  /// made and will never send.
  Future<void> save(
    String localId, {
    String? status,
    String? guideId,
    String? vehicleId,
    double? durationHours,
    int? guestCount,
    bool? inspectionOilOk,
    bool? inspectionWaterOk,
    bool? inspectionTyresOk,
    double? daylightHours,
    double? nightHours,
    int? offRoadSeconds,
    bool? offTrackUsed,
    String? weather,
    String? notes,
    DateTime? endedAt,
  }) async {
    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.drives,
      )..where((t) => t.localId.equals(localId))).getSingleOrNull();
      if (existing == null) return;

      await (_db.update(
        _db.drives,
      )..where((t) => t.localId.equals(localId))).write(
        DrivesCompanion(
          // Absent rather than null for a field the form did not change:
          // Value(null) would write a null over a fact the drive already
          // has. Each field is written only when its argument arrived —
          // the same sparseness as the payload below.
          status: status == null ? const Value.absent() : Value(status),
          guideId: guideId == null ? const Value.absent() : Value(guideId),
          vehicleId: vehicleId == null
              ? const Value.absent()
              : Value(vehicleId),
          durationHours: durationHours == null
              ? const Value.absent()
              : Value(durationHours),
          guestCount: guestCount == null
              ? const Value.absent()
              : Value(guestCount),
          inspectionOilOk: inspectionOilOk == null
              ? const Value.absent()
              : Value(inspectionOilOk),
          inspectionWaterOk: inspectionWaterOk == null
              ? const Value.absent()
              : Value(inspectionWaterOk),
          inspectionTyresOk: inspectionTyresOk == null
              ? const Value.absent()
              : Value(inspectionTyresOk),
          daylightHours: daylightHours == null
              ? const Value.absent()
              : Value(daylightHours),
          nightHours: nightHours == null
              ? const Value.absent()
              : Value(nightHours),
          offRoadSeconds: offRoadSeconds == null
              ? const Value.absent()
              : Value(offRoadSeconds),
          offTrackUsed: offTrackUsed == null
              ? const Value.absent()
              : Value(offTrackUsed),
          weather: weather == null ? const Value.absent() : Value(weather),
          notes: notes == null ? const Value.absent() : Value(notes),
          endedAt: endedAt == null
              ? const Value.absent()
              : Value(endedAt.toUtc()),
          hasPendingChanges: const Value(true),
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
  /// in-flight create gets an update behind it, and an accepted drive gets an
  /// update against the revision the service holds.
  Future<void> _sync(String localId) async {
    final row = await (_db.select(
      _db.drives,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    if (row == null) return;
    final payload = driveToState(row);
    final now = DateTime.now().toUtc();

    final create = await _queue.unsettledCreate(localId);
    if (create != null) {
      if (create.state == OperationState.pending) {
        await _queue.replacePendingCreate(
          entity: EntityKind.drive,
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
      await _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.drive,
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
      // one the service can take: without a duration or a guest count its
      // refusal is certain, and a certain refusal belongs in the ledger only
      // after it has actually happened.
      if (row.durationHours == null || row.guestCount == null) return;
      await _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.drive,
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
    if (await _queue.replacePendingUpdate(
      entity: EntityKind.drive,
      entityId: localId,
      payload: payload,
    )) {
      return;
    }
    final inflight = await _queue.unsettledUpdate(localId);
    await _queue.enqueueNew(
      entityId: localId,
      entity: EntityKind.drive,
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
}
