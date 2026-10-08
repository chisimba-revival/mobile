import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:uuid/uuid.dart';

/// Writes a dangerous-game encounter and queues it, in one transaction.
///
/// An encounter is the one record that is written once and never edited:
/// there is no update and no correction, because a distance and an action
/// taken are what happened and not a claim to be revised. The row and its
/// operation are written together for the same reason as everywhere else — a
/// record that exists locally with no route to the service is a change the
/// client believes it has made and will never send.
class EncounterWriter {
  EncounterWriter(this._db, this._queue, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final FieldLogDatabase _db;
  final OperationQueue _queue;
  final Uuid _uuid;

  /// Records an encounter and returns its local id.
  ///
  /// [outingId] is the local id of the drive or trail log the encounter
  /// happened on. The service uses the client-minted id for both, so the same
  /// string addresses it there. When that outing's create has not settled
  /// yet, this operation names the create as its prerequisite and waits
  /// behind it, rather than being refused for meeting a record that is still
  /// on its way.
  ///
  /// [distanceM] may be absent: an estimate the trainee did not make is left
  /// unstated rather than recorded as zero, because zero asserts the animal
  /// was at the vehicle.
  Future<String> record({
    required String contextCode,
    required String outingId,
    required String speciesCode,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    double? distanceM,
    String? animalBehaviour,
    String? actionTaken,
    double? accuracyM,
    String? note,
    String? createdBy,
    DateTime? recordedAt,
  }) {
    return _db.transaction(() async {
      final recorded = (recordedAt ?? DateTime.now()).toUtc();
      final localId = _uuid.v4();

      await _db
          .into(_db.dangerousGameEncounters)
          .insert(
            DangerousGameEncountersCompanion.insert(
              localId: localId,
              contextCode: contextCode,
              outingId: outingId,
              speciesCode: speciesCode,
              latitude: latitude,
              longitude: longitude,
              capturedAt: capturedAt.toUtc(),
              recordedAt: recorded,
              serverId: const Value(null),
              distanceM: Value(distanceM),
              animalBehaviour: Value(animalBehaviour),
              actionTaken: Value(actionTaken),
              accuracyM: Value(accuracyM),
              createdBy: Value(createdBy),
              note: Value(note),
              revision: const Value(0),
              isTombstone: const Value(false),
            ),
          );

      final row = await (_db.select(
        _db.dangerousGameEncounters,
      )..where((t) => t.localId.equals(localId))).getSingle();
      final pending = await _queue.unsettledCreate(outingId);
      await _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.dangerousGame,
        kind: OperationKind.create,
        baseRevision: 0,
        capturedAt: capturedAt.toUtc(),
        recordedAt: recorded,
        payload: encounterToState(row),
        dependsOn: pending?.operationId,
      );
      return localId;
    });
  }
}
