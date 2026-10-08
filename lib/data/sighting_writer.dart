import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/geo_point.dart';
import 'package:field_log/models/sighting.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:uuid/uuid.dart';

/// Writes a new sighting and queues it to reach the service, in one
/// transaction.
///
/// The row and the queue entry are one unit of work for the same reason they
/// are in [SightingAmender]: a sighting that exists locally but was never
/// queued is a change the client believes it has made and will never send,
/// which is a logbook that lies by omission.
class SightingWriter {
  SightingWriter(this._db, this._queue, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final FieldLogDatabase _db;
  final OperationQueue _queue;
  final Uuid _uuid;

  /// Records a sighting and returns its local id.
  ///
  /// [speciesCode] and [count] may both be absent: rule 21 lets a trainee who
  /// saw something they could not name record a sighting with neither, and
  /// forcing a guess at capture trains a guess.
  Future<String> record({
    required String contextCode,
    required String driveId,
    required GeoPoint location,
    required DateTime capturedAt,
    String? speciesCode,
    int? count,
    double? locationAccuracyM,
    int? distanceMetres,
    int? bearingDegrees,
    String? behaviour,
    String? ageSexClass,
    String? notes,
    String? createdBy,
    DateTime? recordedAt,
  }) {
    return _db.transaction(() async {
      final recorded = (recordedAt ?? DateTime.now()).toUtc();
      final localId = _uuid.v4();

      final model = WildlifeSighting(
        id: localId,
        contextCode: contextCode,
        driveId: driveId,
        status: SightingStatus.pending,
        location: location,
        capturedAt: capturedAt.toUtc(),
        recordedAt: recorded,
        revision: 0,
        createdBy: createdBy ?? '',
        speciesCode: speciesCode,
        count: count,
        locationAccuracyM: locationAccuracyM,
        distanceM: distanceMetres,
        bearingDeg: bearingDegrees,
        behaviour: _behaviourOf(behaviour),
        ageSexClass: _ageSexOf(ageSexClass),
        notes: notes,
      );

      await _db
          .into(_db.sightings)
          .insert(
            SightingsCompanion(
              localId: Value(localId),
              contextCode: Value(model.contextCode),
              driveId: Value(model.driveId),
              speciesCode: Value(model.speciesCode),
              count: Value(model.count),
              locationLat: Value(location.latitude),
              locationLng: Value(location.longitude),
              locationAccuracyM: Value(model.locationAccuracyM),
              distanceM: Value(model.distanceM),
              bearingDeg: Value(model.bearingDeg),
              behaviour: Value(behaviour),
              ageSexClass: Value(ageSexClass),
              notes: Value(model.notes),
              status: Value(SightingStatus.pending),
              capturedAt: Value(model.capturedAt),
              recordedAt: Value(recorded),
              revision: const Value(0),
              createdBy: Value(model.createdBy),
              isTombstone: const Value(false),
              hasPendingChanges: const Value(true),
            ),
          );

      // No outing, no operation. The service refuses a sighting without one —
      // create_without_outing_id — so queueing it would only manufacture a
      // refusal for a record that was correctly captured and merely not yet
      // filed. The row keeps its pending flag and [fileAgainst] queues it once
      // an outing has been chosen. Recording never waits for that choice;
      // sending does.
      if (driveId.isEmpty) return localId;

      await _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.sighting,
        kind: OperationKind.create,
        baseRevision: 0,
        capturedAt: model.capturedAt,
        recordedAt: recorded,
        // The full wire state is the payload, so a pull conflict can be shown
        // against the same shape the service used when it refused it. The
        // queue encodes it; see SightingAmender for why it is not pre-encoded.
        //
        // The service addresses the parent as outing_id; drive_id stays in the
        // body because the local patches and the old wire name both read it.
        payload: sightingToState(model)..['outing_id'] = driveId,
      );

      return localId;
    });
  }

  /// File every sighting recorded without an outing against [driveId].
  ///
  /// Capture never blocks on a choice — rule 19 — so rows exist with an empty
  /// drive id until one is made. This sweeps them up: the id is written and
  /// the create is queued in one transaction, so there is no moment where a
  /// row is filed but unsent. Called when an outing is picked and after a
  /// save that named one; idempotent, because a row that has been filed no
  /// longer matches.
  ///
  /// Returns how many were filed.
  Future<int> fileAgainst(String driveId) async {
    if (driveId.isEmpty) return 0;
    return _db.transaction(() async {
      final unfiled = await (_db.select(
        _db.sightings,
      )..where((t) => t.driveId.equals(''))).get();
      for (final row in unfiled) {
        await (_db.update(_db.sightings)
              ..where((t) => t.localId.equals(row.localId)))
            .write(SightingsCompanion(driveId: Value(driveId)));
        final state = sightingToState(row.toModel());
        state['drive_id'] = driveId;
        state['outing_id'] = driveId;
        await _queue.enqueueNew(
          entityId: row.localId,
          entity: EntityKind.sighting,
          kind: OperationKind.create,
          baseRevision: 0,
          capturedAt: row.capturedAt,
          recordedAt: row.recordedAt,
          payload: state,
        );
      }
      return unfiled.length;
    });
  }

  /// The enum for a behaviour the card offered, or null when the string is not
  /// one of the provisional wire names. Null stores an absent column: an
  /// unrecognised value is not invented, it is left unstated.
  static SightingBehaviour? _behaviourOf(String? value) {
    if (value == null) return null;
    for (final candidate in SightingBehaviour.values) {
      if (behaviourWireName(candidate) == value) return candidate;
    }
    return null;
  }

  /// The enum for an age and sex class the card offered, or null when the
  /// string is not one of the provisional wire names.
  static AgeSexClass? _ageSexOf(String? value) {
    if (value == null) return null;
    for (final candidate in AgeSexClass.values) {
      if (ageSexWireName(candidate) == value) return candidate;
    }
    return null;
  }
}
