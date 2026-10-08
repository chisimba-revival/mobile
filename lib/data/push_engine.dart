import 'package:drift/drift.dart';

import '../models/sync_operation.dart';
import 'database.dart';
import 'mappers.dart';
import 'operation_queue.dart';
import 'tables.dart';

/// The wire form of one pushed operation, as the service expects it.
Map<String, dynamic> operationToWire(PendingOperation operation) {
  // Wire kinds are not a copy of the local ones. The service accepts exactly
  // two kinds of change to an existing record: 'correct' for a sighting
  // (evidence is never rewritten, it is corrected) and 'update' for an
  // outing. An amendment queued as a local update therefore goes out as
  // 'correct', carrying its amendment payload through as-is — the service
  // applies what it understands of that payload and the rest stays visible
  // rather than being reshaped into a claim the amendment never made.
  final kind =
      operation.entity == EntityKind.sighting &&
          operation.kind == OperationKind.update
      ? 'correct'
      : operation.kind.name;
  return <String, dynamic>{
    'operation_id': operation.operationId,
    'entity': wireEntityFor(operation.entity),
    'entity_id': operation.entityId,
    'kind': kind,
    // A base of zero is no base at all: the service refuses any create that
    // carries one, so a create omits the key entirely rather than sending a
    // number that means "nothing has been established yet".
    if (operation.baseRevision > 0) 'base_revision': operation.baseRevision,
    'captured_at': operation.capturedAt.toUtc().toIso8601String(),
    'recorded_at': operation.recordedAt.toUtc().toIso8601String(),
    if (operation.dependsOn != null) 'depends_on': operation.dependsOn,
    'payload': operation.payload,
  };
}

/// What one push attempt achieved.
///
/// The batch is not all-or-nothing, so this reports the outcome per operation
/// rather than one verdict for the request.
class PushOutcomeReport {
  const PushOutcomeReport({
    required this.applied,
    required this.noop,
    required this.deferred,
    required this.refused,
    required this.conflictsRetained,
    required this.unreadable,
    required this.sentOperationIds,
  });

  final int applied;
  final int noop;
  final int deferred;
  final int refused;

  /// Refusals kept for a person to resolve rather than discarded.
  final int conflictsRetained;

  /// Queued operations this device could not decode, and therefore never sent.
  ///
  /// Counted separately from [deferred] because they are not waiting on the
  /// service; nothing about a retry will fix them.
  final int unreadable;

  /// Exactly what went on the wire, so a failure can be diagnosed without
  /// guessing what was sent.
  final List<String> sentOperationIds;

  /// Whether anything is still waiting on the service.
  bool get hasOutstandingWork => deferred > 0 || refused > 0;
}

/// Sends queued operations and applies the service's answers.
class PushEngine {
  PushEngine(this._db, this._queue);

  final FieldLogDatabase _db;
  final OperationQueue _queue;

  /// Push one bounded batch.
  ///
  /// The three stages are ordered deliberately, and the ordering is the contract:
  ///
  ///   1. read the batch and mark it inflight, so a crash mid-push leaves
  ///      something recoverable rather than losing the operations;
  ///   2. send it;
  ///   3. record every result.
  ///
  /// Results are applied per operation and independently. One refusal does not
  /// undo its neighbours, and a batch refused in part still settles in part. That
  /// is what it means for a batch not to be all-or-nothing.
  ///
  /// [send] receives the operations in wire order and returns one result per
  /// operation. A result naming an operation this client did not send is
  /// ignored rather than trusted.
  Future<PushOutcomeReport> push({
    required Future<List<PushResult>> Function(List<PendingOperation> batch)
    send,
    int limit = 20,
  }) async {
    final rows = await _queue.nextBatch(limit: limit);
    if (rows.isEmpty) {
      return const PushOutcomeReport(
        applied: 0,
        noop: 0,
        deferred: 0,
        refused: 0,
        conflictsRetained: 0,
        unreadable: 0,
        sentOperationIds: [],
      );
    }

    // A payload this device cannot decode is settled rather than queued again:
    // retrying unreadable bytes cannot succeed, and leaving it pending would
    // block every operation that declares a dependency on it. It is recorded for
    // a person because nothing else can fix it.
    final batch = <PendingOperation>[];
    var unreadable = 0;
    for (final row in rows) {
      final operation = row.toOperation();
      if (operation == null) {
        unreadable++;
        await _holdUnreadable(row);
        continue;
      }
      batch.add(operation);
    }

    if (batch.isEmpty) {
      return PushOutcomeReport(
        applied: 0,
        noop: 0,
        deferred: 0,
        refused: 0,
        conflictsRetained: 0,
        unreadable: unreadable,
        sentOperationIds: const [],
      );
    }

    final sentIds = batch.map((operation) => operation.operationId).toList();
    await _queue.markInflight(sentIds);

    final results = await send(batch);
    final byId = {for (final result in results) result.operationId: result};

    var applied = 0;
    var noop = 0;
    var deferred = 0;
    var refused = 0;
    var retained = 0;

    for (final operation in batch) {
      final result = byId[operation.operationId];
      if (result == null) {
        // The contract says every operation gets exactly one outcome, so a
        // missing one is a malformed response. The operation goes back to
        // pending rather than being marked done, because marking it done would
        // drop a change nobody has confirmed.
        await _queue.recordResult(
          PushResult(
            operationId: operation.operationId,
            outcome: PushOutcome.deferred,
            errorCode: 'no_result_returned',
          ),
        );
        deferred++;
        continue;
      }

      await _queue.recordResult(result);

      switch (result.outcome) {
        case PushOutcome.applied:
          applied++;
          await _acceptServerRevision(operation, result);
        case PushOutcome.noop:
          // Not a conflict. The operation id was already processed, which is
          // exactly what a retry after an ambiguous response looks like.
          // Reporting it as a failure is how a client learns to retry forever.
          noop++;
          await _acceptServerRevision(operation, result);
        case PushOutcome.deferred:
          deferred++;
        case PushOutcome.refused:
          refused++;
          if (await _retainRefusal(operation, result)) retained++;
      }
    }

    return PushOutcomeReport(
      applied: applied,
      noop: noop,
      deferred: deferred,
      refused: refused,
      conflictsRetained: retained,
      unreadable: unreadable,
      sentOperationIds: sentIds,
    );
  }

  /// Record the revision the service settled on.
  ///
  /// Rule 6: the server's revision is the only thing that becomes the new local
  /// revision. Timestamps never arbitrate.
  ///
  /// The id written into `serverId` is the id this client minted. That is not
  /// an assumption: the service takes the client's uuid as its own — a create
  /// whose entity_id is not a uuid is refused outright — so client id, wire id
  /// and server id are one identifier with three names, and `serverId` is
  /// marked "the service has seen this record", not "some other identifier".
  ///
  /// Not every entity has every column. A waypoint keeps no revision and a
  /// pending flag of its own — its row is already addressed by the uuid it was
  /// written with, so there is nothing to update. An encounter has a revision
  /// but no pending flag, because encounters are written once and never
  /// amended. A table without a column is not a column set to a default; the
  /// update simply does not mention it.
  Future<void> _acceptServerRevision(
    PendingOperation operation,
    PushResult result,
  ) async {
    final revision = result.newRevision ?? result.serverRevision;
    final serverId = Value(operation.entityId);
    final revisionValue = revision == null
        ? const Value<int>.absent()
        : Value(revision);

    switch (operation.entity) {
      case EntityKind.sighting:
        await (_db.update(
          _db.sightings,
        )..where((t) => t.localId.equals(operation.entityId))).write(
          SightingsCompanion(
            serverId: serverId,
            revision: revisionValue,
            hasPendingChanges: const Value(false),
          ),
        );
      case EntityKind.drive:
      case EntityKind.outing:
        // Both name the same local row: 'outing' is the wire's word for the
        // drive record, and there is one table, not two.
        await (_db.update(
          _db.drives,
        )..where((t) => t.localId.equals(operation.entityId))).write(
          DrivesCompanion(
            serverId: serverId,
            revision: revisionValue,
            hasPendingChanges: const Value(false),
          ),
        );
      case EntityKind.trailLog:
        await (_db.update(
          _db.trailLogs,
        )..where((t) => t.localId.equals(operation.entityId))).write(
          TrailLogsCompanion(serverId: serverId, revision: revisionValue),
        );
      case EntityKind.dangerousGame:
        await (_db.update(
          _db.dangerousGameEncounters,
        )..where((t) => t.localId.equals(operation.entityId))).write(
          DangerousGameEncountersCompanion(
            serverId: serverId,
            revision: revisionValue,
          ),
        );
      case EntityKind.trailWaypoint:
      // The row already carries this uuid in its serverId column — it was
      // minted there, and the service adopted it. Nothing local changes when
      // the service confirms what it already says.
      case EntityKind.signOff:
      case EntityKind.media:
      case EntityKind.unknown:
        // No local table stands behind these kinds. Settling the operation
        // itself is the queue's job and has already happened; inventing a row
        // for a record this client does not keep would be a second invention.
        break;
    }
  }

  /// Keep a refusal for a person rather than discarding or auto-resolving it.
  ///
  /// A verification is marked specially. The contract is unambiguous that
  /// verification is never resolved by revision and that a stale-revision
  /// verification is refused unconditionally, so retrying one would send the same
  /// bytes to be refused again for the same reason indefinitely. Recording it
  /// with its reason is the only thing that moves it forward.
  Future<bool> _retainRefusal(
    PendingOperation operation,
    PushResult result,
  ) async {
    final isVerification = operation.kind == OperationKind.verify;

    await _db
        .into(_db.conflicts)
        .insert(
          ConflictsCompanion.insert(
            operationId: operation.operationId,
            entityId: operation.entityId,
            entity: operation.entity,
            clientPayload: encodePayload(operationToWire(operation)),
            serverState: encodePayload(result.serverState ?? const {}),
            serverRevision: result.serverRevision ?? 0,
            baseRevision: operation.baseRevision,
            errorCode: result.errorCode ?? 'refused',
            reason: Value(
              isVerification ? 'verification_requires_a_person' : null,
            ),
            recordedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    return true;
  }

  /// Record a queued operation whose payload this device cannot read.
  Future<void> _holdUnreadable(QueuedOperationRow row) async {
    await _db
        .into(_db.conflicts)
        .insert(
          ConflictsCompanion.insert(
            operationId: row.operationId,
            entityId: row.entityId,
            entity: row.entity,
            clientPayload: row.payload,
            serverState: '{}',
            serverRevision: 0,
            baseRevision: row.baseRevision,
            errorCode: 'payload_unreadable',
            reason: const Value('the stored payload will not decode'),
            recordedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    // Settled so it stops blocking dependent operations. Retrying cannot repair
    // bytes this device cannot read.
    await (_db.update(
      _db.queuedOperations,
    )..where((t) => t.operationId.equals(row.operationId))).write(
      QueuedOperationsCompanion(
        state: const Value(OperationState.settled),
        settledAt: Value(DateTime.now().toUtc()),
        errorCode: const Value('payload_unreadable'),
      ),
    );
  }
}
