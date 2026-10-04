import 'package:drift/drift.dart';

import '../models/sighting.dart';
import '../models/sync_operation.dart';

// No `part` directive here on purpose: drift emits one shared part file for
// the whole store (data/database.g.dart) rather than one per table file. A
// `part 'tables.g.dart'` would be an unsatisfiable import, because nothing
// generates it.

/// A sighting as the client holds it, which is not the same as how the service
/// sends it.
///
/// Two deliberate departures from the wire shape:
///
///   * [locationLat] and [locationLng] are stored as plain reals rather than as
///     a GeoJSON `Point`. A point is the right *transport* form and the wrong
///     *storage* form: the map screen has to sort and filter by latitude, and
///     splitting the pair at the boundary is cheaper than parsing a geometry on
///     every row. [toGeoJsonPoint] in `mappers.dart` puts the `Point` back
///     together on the way out, so nothing on the wire ever sees the split.
///   * `behaviour` and `ageSexClass` are free text, not enums. The contract
///     declares both fields but enumerates neither, so encoding a Dart enum here
///     would make the database reject values the service might legitimately
///     send. The provisional enums in `models/sighting.dart` are what the UI
///     offers; this column stores whatever arrives. When the contract settles
///     the value lists, only the model changes and no migration is needed.
@DataClassName('SightingRow')
class Sightings extends Table {
  /// The id the *client* minted, from the very first save.
  ///
  /// This is the primary key rather than the server's id because a queued
  /// operation has to be able to name its subject before the service has ever
  /// heard of it. [serverId] stays null until the service assigns one.
  TextColumn get localId => text()();

  /// The service's id for this record, once it has one.
  TextColumn get serverId => text().nullable()();

  /// Carried by every record. Access needs both scope and a context grant, so a
  /// sighting without one is not merely incomplete, it is unaddressable.
  TextColumn get contextCode => text()();

  TextColumn get driveId => text()();

  /// Null until verified. Rule 21: a trainee who saw something they could not
  /// name records a sighting with neither this nor [count], and forcing a guess
  /// at capture trains guessing.
  TextColumn get speciesCode => text().nullable()();

  /// Null until verified. An absent count is not a zero: a zero asserts the
  /// animal was looked for and there were none.
  IntColumn get count => integer().nullable()();

  RealColumn get locationLat => real()();
  RealColumn get locationLng => real()();

  /// How sure the device was of its own position, in metres.
  ///
  /// Carried on the sighting rather than discarded after the fact so a reviewer
  /// can tell a precise fix from a coarse one.
  RealColumn get locationAccuracyM => real().nullable()();

  /// Distance and bearing exist so a reviewer can distinguish a genuinely new
  /// sighting from the same animals logged twice from a different seat, which is
  /// the most common error in a sighting log.
  IntColumn get distanceM => integer().nullable()();
  IntColumn get bearingDeg => integer().nullable()();

  /// Free text: the contract does not enumerate the allowed values.
  TextColumn get behaviour => text().nullable()();
  TextColumn get ageSexClass => text().nullable()();

  TextColumn get notes => text().nullable()();

  /// Enumerated by the contract, so it is constrained rather than free text.
  TextColumn get status => textEnum<SightingStatus>()();

  TextColumn get verifiedBy => text().nullable()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  TextColumn get verificationNotes => text().nullable()();

  /// The values before a correction, retained permanently.
  ///
  /// Rule 15 requires a reason for a correction *and* retention of the
  /// originals. Without these two columns a mentor cannot show a trainee what
  /// they originally said, which is the only way the correction teaches anything.
  TextColumn get recordedSpeciesCode => text().nullable()();
  IntColumn get recordedCount => integer().nullable()();

  /// Why a correction happened, when there is one.
  ///
  /// Rule 15 makes the reason mandatory with the correction, so it is stored
  /// beside the retained originals rather than being inferred from them.
  TextColumn get correctionReason => text().nullable()();

  BoolColumn get lateArrival => boolean().withDefault(const Constant(false))();

  /// When the observation happened. Rule 13: never interchangeable with
  /// [recordedAt], and neither arbitrates anything.
  DateTimeColumn get capturedAt => dateTime()();

  /// When this device recorded it. Diverges from [capturedAt] exactly when the
  /// device was offline, and conflating them makes an honest offline entry look
  /// late when it is not.
  DateTimeColumn get recordedAt => dateTime()();

  /// The service's revision, or 0 while the record has never been accepted.
  ///
  /// Rule 6: conflicts are decided by revision and never by timestamps, so this
  /// is the only field that participates in conflict resolution.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  TextColumn get createdBy => text()();

  /// Rule 9: deletion is a soft delete and a removal arrives as a record rather
  /// than as an absence. A client that treated it as an absence would re-send
  /// the deleted record on its next edit, because nothing local ever said it
  /// was gone.
  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Whether this row has local changes the service has not accepted.
  BoolColumn get hasPendingChanges =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

/// A drive. Rule 14: ending a drive does not close it, so [endedAt] and
/// [sealedAt] are separate and only a seal closes a drive to late observations.
@DataClassName('DriveRow')
class Drives extends Table {
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get contextCode => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Set only by an explicit seal. A drive can be ended and still accept a
  /// sighting that was genuinely observed on it.
  DateTimeColumn get sealedAt => dateTime().nullable()();

  IntColumn get revision => integer().withDefault(const Constant(0))();
  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get hasPendingChanges =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

/// A stretch of a named trail within a drive.
///
/// The design's field card makes this block conditional on the drive having one,
/// which is a UI concern; the row exists regardless because a drive without
/// trails is normal, not exceptional.
@DataClassName('TrailLogRow')
class TrailLogs extends Table {
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get contextCode => text()();
  TextColumn get driveId => text()();
  TextColumn get trailCode => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Where an operation is in its life.
enum OperationState {
  /// Written and waiting. The payload has not been offered to the service yet.
  pending,

  /// Handed to a batch that has not come back.
  ///
  /// This state exists so a crash mid-push is recoverable. Without it a row
  /// would be either "never sent" or "done", and an interrupted push would be
  /// indistinguishable from one that never ran.
  inflight,

  /// The service returned a terminal answer.
  settled,
}

/// A change the client intends to make, persisted before it is attempted.
///
/// The primary key is [operationId], not the entity it concerns. Rule 7 keys
/// idempotency by operation identifier and never by entity identifier, so
/// retrying a `start` must not be mistaken for retrying the `create` of the
/// drive it starts. A table keyed by entity would collapse those two into one
/// and silently drop one of them.
@DataClassName('QueuedOperationRow')
class QueuedOperations extends Table {
  /// The retry identity, and the idempotency key the service will see.
  TextColumn get operationId => text()();

  /// The device-minted id of the record this operation concerns.
  TextColumn get entityId => text()();

  TextColumn get entity => textEnum<EntityKind>()();

  /// An intent, never a whole-entity replacement.
  TextColumn get kind => textEnum<OperationKind>()();

  /// The revision this edit was made against. Rule 6: the only input to
  /// conflict resolution.
  IntColumn get baseRevision => integer()();

  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime()();

  /// A declared prerequisite that must settle first, named by its own
  /// operation id.
  TextColumn get dependsOn => text().nullable()();

  /// The operation payload as JSON.
  ///
  /// Kept as the exact bytes that will be sent, because a `deferred` outcome
  /// re-queues the same payload rather than rebuilding it. Rebuilding would
  /// risk quietly changing what the guide actually asked for.
  TextColumn get payload => text()();

  TextColumn get state =>
      textEnum<OperationState>().withDefault(const Constant('pending'))();

  /// How many times this has been offered. Diagnostic only: nothing in the
  /// contract makes a retry count significant.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  DateTimeColumn get enqueuedAt => dateTime()();
  DateTimeColumn get settledAt => dateTime().nullable()();

  /// The terminal answer, if there is one.
  TextColumn get outcome => textEnum<PushOutcome>().nullable()();

  IntColumn get serverRevision => integer().nullable()();

  /// The stable error code from a refusal.
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// A refused edit, kept whole.
///
/// The contract is unambiguous that the client keeps the rejected version of a
/// conflict rather than discarding it, so a guide can see what their offline
/// edit said and why it did not apply. Silently dropping it is indistinguishable
/// from losing the observation.
///
/// [clientPayload] and [serverState] are held side by side for that reason, and
/// [resolvedAt] stays null until a person has dealt with it. A conflict that
/// auto-resolved would be a conflict the trainee never saw.
@DataClassName('ConflictRow')
class Conflicts extends Table {
  TextColumn get operationId => text()();

  TextColumn get entityId => text()();
  TextColumn get entity => textEnum<EntityKind>()();

  /// What the offline edit said.
  TextColumn get clientPayload => text()();

  /// What the service holds instead, as returned with the refusal.
  TextColumn get serverState => text()();

  IntColumn get serverRevision => integer()();

  /// The revision the edit was made against, so the gap is legible.
  IntColumn get baseRevision => integer()();

  TextColumn get errorCode => text()();

  /// Why the guide gave for the edit, when the change was a correction.
  TextColumn get reason => text().nullable()();

  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// How far this client has consumed the change feed.
///
/// One row per accessible scope, because a context grant can change the set of
/// records the client may even see.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  TextColumn get scope => text()();

  /// The opaque cursor for the next pull. Null before the first pull.
  TextColumn get cursor => text().nullable()();

  /// The server time of the page most recently applied.
  DateTimeColumn get serverTimeAtApply => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {scope};
}

/// Cached reference data, keyed by kind and code.
///
/// Cached aggressively and refreshed in the background, because a guide needs a
/// species name with no connectivity at all. Stored as the raw payload so a new
/// field on the service does not need a migration.
@DataClassName('ReferenceRow')
class ReferenceData extends Table {
  TextColumn get kind => text()();
  TextColumn get code => text()();
  TextColumn get label => text().nullable()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {kind, code};
}
