import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/sync_operation.dart';
import 'database.dart';
import 'mappers.dart';
import 'tables.dart';

/// The client's queue of changes it intends to make.
///
/// Every method here is written around one rule: **a change is persisted before
/// it is attempted.** An app kill between the moment a guide records something
/// and the moment the service hears about it must lose nothing, because the
/// observation is already on disk and nothing has been sent yet.
///
/// The second rule is that the queue is keyed by [PendingOperation.operationId]
/// and never by entity id. Idempotency on the wire is keyed by operation
/// identifier, so a retry of `start` must not be mistaken for a retry of the
/// `create` that made the drive it starts. A queue keyed by entity would
/// collapse those two operations into one row and silently drop one of them.
class OperationQueue {
  OperationQueue(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final FieldLogDatabase _db;
  final Uuid _uuid;

  /// Write a change to disk and return the row id, which is its operation id.
  ///
  /// Returns only once the write has committed. Nothing is sent from here, and
  /// that is deliberate: the caller decides when to attempt a push, and by then
  /// the observation is already durable.
  Future<String> enqueue(PendingOperation operation) async {
    await _db
        .into(_db.queuedOperations)
        .insert(
          QueuedOperationsCompanion.insert(
            operationId: operation.operationId,
            entityId: operation.entityId,
            entity: operation.entity,
            kind: operation.kind,
            baseRevision: operation.baseRevision,
            capturedAt: operation.capturedAt,
            recordedAt: operation.recordedAt,
            payload: jsonEncode(operation.payload),
            dependsOn: Value(operation.dependsOn),
            enqueuedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return operation.operationId;
  }

  /// Queue a change, minting the operation id here.
  ///
  /// The id is generated before the row is written rather than by the database,
  /// because the caller needs it to link a prerequisite with [dependsOn] in the
  /// same breath as the operation it depends on.
  Future<String> enqueueNew({
    required String entityId,
    required EntityKind entity,
    required OperationKind kind,
    required int baseRevision,
    required DateTime capturedAt,
    required DateTime recordedAt,
    required Map<String, dynamic> payload,
    String? dependsOn,
  }) {
    return enqueue(
      PendingOperation(
        operationId: _uuid.v4(),
        entityId: entityId,
        entity: entity,
        kind: kind,
        baseRevision: baseRevision,
        capturedAt: capturedAt,
        recordedAt: recordedAt,
        payload: payload,
        dependsOn: dependsOn,
      ),
    );
  }

  /// The next batch to offer the service, oldest first.
  ///
  /// Only rows in [OperationState.pending] are returned. An [OperationState
  /// .inflight] row is deliberately excluded: it was handed to a batch whose
  /// answer never arrived, and re-sending it blindly would be guessing. It
  /// becomes eligible again through [recoverInterrupted], which runs at startup
  /// where a person is not yet waiting on a result.
  ///
  /// Operations whose [QueuedOperations.dependsOn] has not settled are held
  /// back, because the contract lets the service defer an operation whose
  /// declared prerequisite is unsettled and there is no point provoking that.
  Future<List<QueuedOperationRow>> nextBatch({int limit = 20}) async {
    final all =
        await (_db.select(_db.queuedOperations)
              ..where((t) => t.state.equals(OperationState.pending.name))
              ..orderBy([(t) => OrderingTerm.asc(t.enqueuedAt)]))
            .get();

    final settled = await _settledOperationIds();
    final ready = <QueuedOperationRow>[];
    for (final row in all) {
      final dependency = row.dependsOn;
      if (dependency != null && !settled.contains(dependency)) {
        continue;
      }
      ready.add(row);
      if (ready.length == limit) {
        break;
      }
    }
    return ready;
  }

  /// Mark rows as handed to a batch, so an interrupted push is recoverable.
  ///
  /// The attempt counter is read and rewritten per row rather than incremented
  /// in a single statement, so a count always belongs to a row that exists. The
  /// batch is bounded by the contract at a few dozen operations, so the round
  /// trip is not worth optimising away.
  Future<void> markInflight(Iterable<String> operationIds) async {
    for (final id in operationIds) {
      final row = await (_db.select(
        _db.queuedOperations,
      )..where((t) => t.operationId.equals(id))).getSingleOrNull();
      if (row == null) {
        continue;
      }
      await (_db.update(
        _db.queuedOperations,
      )..where((t) => t.operationId.equals(id))).write(
        QueuedOperationsCompanion(
          state: Value(OperationState.inflight),
          attempts: Value(row.attempts + 1),
        ),
      );
    }
  }

  /// Record the service's answer for one operation.
  ///
  /// [PushOutcome.deferred] puts the row back to pending and **leaves the
  /// payload untouched**. The contract says a deferral means a declared
  /// prerequisite has not settled yet, so the same payload will be correct once
  /// it has. Rebuilding the payload on the way out would risk quietly changing
  /// what the guide actually asked for.
  /// Record what the service said about one operation.
  ///
  /// A [PushOutcome.deferred] result goes back to pending: its prerequisite is
  /// expected to settle, and the same bytes should then be sent.
  ///
  /// A [PushOutcome.refused] result is settled even though
  /// [PushOutcome.isTerminal] is false for it. The two answer different
  /// questions. `isTerminal` asks whether anything more will happen without a
  /// person, and a refusal genuinely needs a person. The queue asks whether
  /// re-sending the same bytes could produce a different answer, and for a
  /// refusal it cannot: the request was well formed and the service declined it,
  /// so an identical retry is refused identically. Re-queueing it would retry
  /// every refusal on every push forever.
  ///
  /// The refusal itself is not lost. [PushEngine._retainRefusal] has already
  /// written it to the conflicts table with the submitted and current values
  /// side by side, and that is where a person meets it. This queue tracks
  /// transport-level work; the conflicts table tracks the work that needs a
  /// decision. Settling the row is what stops the two being confused.
  Future<void> recordResult(PushResult result) async {
    final settled =
        result.outcome.isTerminal || result.outcome == PushOutcome.refused;
    await (_db.update(
      _db.queuedOperations,
    )..where((t) => t.operationId.equals(result.operationId))).write(
      QueuedOperationsCompanion(
        state: Value(settled ? OperationState.settled : OperationState.pending),
        outcome: Value(result.outcome),
        errorCode: Value(result.errorCode),
        errorMessage: Value(
          result.errorCode == null ? null : 'refused: ${result.errorCode}',
        ),
        serverRevision: Value(result.newRevision ?? result.serverRevision),
        settledAt: Value(settled ? DateTime.now().toUtc() : null),
      ),
    );
  }

  /// Return rows left [OperationState.inflight] to pending.
  ///
  /// Called once at startup. A row in that state means a batch was sent and its
  /// answer never reached the device, which is exactly the ambiguous case rule 7
  /// exists for: re-sending it is safe, because the operation id is unchanged
  /// and the service will answer `noop` if it already processed it.
  Future<int> recoverInterrupted() async {
    return (_db.update(
      _db.queuedOperations,
    )..where((t) => t.state.equals(OperationState.inflight.name))).write(
      QueuedOperationsCompanion(state: const Value(OperationState.pending)),
    );
  }

  /// Operation ids that have reached a terminal outcome.
  Future<Set<String>> _settledOperationIds() async {
    final rows = await (_db.select(
      _db.queuedOperations,
    )..where((t) => t.state.equals(OperationState.settled.name))).get();
    return rows.map((r) => r.operationId).toSet();
  }

  /// Everything still waiting, for the ledger screen.
  Future<List<QueuedOperationRow>> pending() {
    return (_db.select(_db.queuedOperations)
          ..where((t) => t.state.equals(OperationState.settled.name).not())
          ..orderBy([(t) => OrderingTerm.asc(t.enqueuedAt)]))
        .get();
  }

  /// One row by operation id, or null.
  Future<QueuedOperationRow?> byId(String operationId) {
    return (_db.select(
      _db.queuedOperations,
    )..where((t) => t.operationId.equals(operationId))).getSingleOrNull();
  }
}

/// Recover the operation a queued row stands for.
///
/// Returns null when the stored payload will not decode. That is a device-side
/// integrity failure rather than a server answer, and the two are handled very
/// differently: an unreadable payload cannot be made readable by retrying, so it
/// is surfaced to a person and settled instead of being sent or re-queued.
extension QueuedOperationRowMapping on QueuedOperationRow {
  PendingOperation? toOperation() {
    final payload = decodePayload(this.payload);
    if (payload == null) {
      return null;
    }
    return PendingOperation(
      operationId: operationId,
      entityId: entityId,
      entity: entity,
      kind: kind,
      baseRevision: baseRevision,
      capturedAt: capturedAt,
      recordedAt: recordedAt,
      dependsOn: dependsOn,
      payload: payload,
    );
  }
}
