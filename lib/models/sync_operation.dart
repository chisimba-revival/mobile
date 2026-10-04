import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_operation.freezed.dart';
part 'sync_operation.g.dart';

/// What a queued change is trying to do.
///
/// The contract is explicit that an operation is expressed as an intent and
/// not as a whole-entity replacement, because a replacement is a
/// last-writer-wins edit wearing a disguise, and rule 6 forbids resolving
/// conflicts any other way than by revision.
enum OperationKind {
  @JsonValue('create')
  create,

  @JsonValue('update')
  update,

  @JsonValue('delete')
  delete,

  @JsonValue('start')
  start,

  @JsonValue('end')
  end,

  @JsonValue('verify')
  verify,
}

/// Which kind of record an operation applies to.
enum EntityKind {
  @JsonValue('drive')
  drive,

  @JsonValue('trail_log')
  trailLog,

  @JsonValue('sighting')
  sighting,

  @JsonValue('sign_off')
  signOff,

  @JsonValue('media')
  media,
}

/// A change the client intends to make, queued locally before it is attempted.
///
/// Every field here is one the contract requires a client to carry, and each is
/// load-bearing:
///
///   * [operationId] is the retry identity. Idempotency is keyed by operation
///     identifier and never by entity identifier, so retrying a start is not
///     mistaken for retrying the creation of the drive it starts.
///   * [baseRevision] is the only input to conflict resolution. Timestamps
///     never arbitrate.
///   * [capturedAt] is when the observation happened in the field, which is not
///     [recordedAt] and never interchangeable with it.
@freezed
abstract class PendingOperation with _$PendingOperation {
  const factory PendingOperation({
    required String operationId,

    /// Device-generated entity id. A client mints its own ids from the start,
    /// so that a queued operation can name its subject before the service has
    /// ever heard of it.
    required String entityId,
    required EntityKind entity,
    required OperationKind kind,
    required int baseRevision,
    required DateTime capturedAt,
    required DateTime recordedAt,
    String? dependsOn,
    required Map<String, dynamic> payload,
  }) = _PendingOperation;

  const PendingOperation._();

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      _$PendingOperationFromJson(json);
}

/// How the service resolved one operation in a pushed batch.
///
/// A batch is not all-or-nothing, and [PushOutcome] is the type that makes that
/// visible. Every operation in the request gets exactly one of these, so a
/// client never has to infer a result from the absence of a failure.
enum PushOutcome {
  /// Applied, and the record now carries [PushResult.newRevision].
  @JsonValue('applied')
  applied,

  /// The operation identifier was already processed. Not an error: a retry
  /// after an ambiguous response lands here, and reporting it as a conflict
  /// would train a client to retry forever.
  @JsonValue('noop')
  noop,

  /// A declared prerequisite has not settled yet. Re-queue rather than fail,
  /// and do not rewrite the payload.
  @JsonValue('deferred')
  deferred,

  /// Refused, with a stable [PushResult.errorCode].
  @JsonValue('refused')
  refused;

  bool get isTerminal => switch (this) {
    PushOutcome.applied || PushOutcome.noop => true,
    PushOutcome.deferred || PushOutcome.refused => false,
  };
}

/// The service's answer for one operation.
///
/// A refusal carries the current server state and its revision alongside the
/// values the client submitted, so the two can be shown side by side. The
/// server never merges automatically and never discards the client edit
/// silently, which is what makes a conflict something a person can resolve
/// rather than something they have to be told about.
@freezed
abstract class PushResult with _$PushResult {
  const factory PushResult({
    required String operationId,
    required PushOutcome outcome,
    int? newRevision,
    String? errorCode,
    Map<String, dynamic>? serverState,
    int? serverRevision,
  }) = _PushResult;

  const PushResult._();

  factory PushResult.fromJson(Map<String, dynamic> json) =>
      _$PushResultFromJson(json);

  /// Whether this refusal was a revision conflict, as opposed to a validation
  /// or permission failure.
  ///
  /// A conflict is the one refusal the client can offer to resolve, by showing
  /// both sides. A validation refusal has nothing to show.
  bool get isConflict => errorCode == 'revision_conflict';
}

/// A page of change feed.
@freezed
abstract class PullPage with _$PullPage {
  const factory PullPage({
    required List<PullChange> changes,
    String? nextCursor,
    required bool hasMore,
    required DateTime serverTime,
  }) = _PullPage;

  const PullPage._();

  factory PullPage.fromJson(Map<String, dynamic> json) =>
      _$PullPageFromJson(json);
}

/// One change from the feed, or a tombstone.
///
/// Deletion is a soft delete with a retained audit trail, so a removal arrives
/// as a record rather than as an absence. A client that treated it as an
/// absence would quietly re-send the deleted record on its next edit, because
/// nothing local ever said it was gone.
@freezed
abstract class PullChange with _$PullChange {
  const factory PullChange({
    required EntityKind entity,
    required String entityId,
    required int revision,
    required bool isTombstone,
    Map<String, dynamic>? state,
  }) = _PullChange;

  const PullChange._();

  factory PullChange.fromJson(Map<String, dynamic> json) =>
      _$PullChangeFromJson(json);
}
