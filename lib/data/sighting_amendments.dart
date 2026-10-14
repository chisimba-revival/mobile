import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/sighting.dart';
import 'package:field_log/models/sync_operation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// What kind of thing was added to a record.
///
/// The names are the ones the record screen uses when it reports an addition,
/// so the two cannot drift apart by accident.
///
/// [wire] is the word the screen speaks. [key] is the field the service writes.
/// They are deliberately not the same value: the screen says "a note" while the
/// contract calls the field `notes`, and an operation that corrects a record has
/// to speak the contract or the service accepts the addition and never writes
/// it. The first version used [wire] for both, which is exactly that bug — a
/// note arrived as `note`, a column nothing reads, and the record was
/// acknowledged as corrected without changing.
enum AmendmentKind {
  note('note', 'notes'),
  behaviour('behaviour', 'behaviour'),
  ageSex('age_sex', 'age_sex_class');

  const AmendmentKind(this.wire, this.field);

  /// The screen's word for this addition.
  final String wire;

  /// The field the service reads it into.
  ///
  /// Not called `key`, which is a Dart keyword: an enum constructor parameter
  /// parsed as one gives an error that points at nothing.
  final String field;

  /// Reads the screen's word. Returns null for anything unrecognised rather
  /// than guessing, because a guessed amendment would be written to somebody's
  /// record as though they had said it.
  static AmendmentKind? fromWire(String value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

class SightingAmendment {
  const SightingAmendment(this.kind, this.value);

  final AmendmentKind kind;
  final String value;
}

/// A set of changes to a record, every field optional.
///
/// An absent field is one the client did not mention, and it must stay as it
/// is. That distinction is the whole point of the shape: a nullable field that
/// always carried a value would let a form which left the species blank wipe
/// the species on a record a reviewer can see.
class SightingCorrection {
  const SightingCorrection({
    this.speciesCode,
    this.count,
    this.behaviour,
    this.ageSexClass,
    this.notes,
    this.reason,
  });

  final String? speciesCode;
  final int? count;
  final String? behaviour;
  final String? ageSexClass;
  final String? notes;

  /// Rule 15: a change to what was claimed needs one, and the service refuses
  /// the operation without it. It is asked for on the form that makes the
  /// change rather than afterwards, because a correction nobody can explain
  /// teaches nothing.
  final String? reason;

  /// Whether the trainee's claim about which animal and how many is being
  /// moved. Decided here rather than by the screen, because the rule and the
  /// service live in different places and must not disagree.
  bool get changesClaim => speciesCode != null || count != null;

  bool get isEmpty =>
      speciesCode == null &&
      count == null &&
      behaviour == null &&
      ageSexClass == null &&
      notes == null &&
      reason == null;
}

/// The outcome a mentor or reviewer gives to a record.
///
/// The service accepts exactly these three. A fourth would be a status the
/// rest of the system has no handling for.
enum VerificationOutcome {
  @JsonValue('verified')
  verified,
  @JsonValue('rejected')
  rejected,
  @JsonValue('needs_review')
  needsReview,
}

/// A set of changes that constitute a verification decision.
///
/// A verification is a mentor's answer to a record: the outcome (verified,
/// rejected, needs_review), optional corrections to species/count, and the
/// mentor's reasoning notes. The service requires a correction_reason when
/// species or count is changed.
class SightingVerification {
  const SightingVerification({
    required this.outcome,
    this.speciesCode,
    this.count,
    this.behaviour,
    this.ageSexClass,
    this.notes,
    this.verificationNotes,
    this.reason,
  });

  final VerificationOutcome outcome;
  final String? speciesCode;
  final int? count;
  final String? behaviour;
  final String? ageSexClass;
  final String? notes;
  final String? verificationNotes;
  final String? reason;

  /// Whether the trainee's claim about which animal and how many is being
  /// moved. Decided here rather than by the screen, because the rule and the
  /// service live in different places and must not disagree.
  bool get changesClaim => speciesCode != null || count != null;

  bool get isEmpty =>
      outcome == VerificationOutcome.needsReview &&
      speciesCode == null &&
      count == null &&
      behaviour == null &&
      ageSexClass == null &&
      notes == null &&
      verificationNotes == null &&
      reason == null;
}

/// Writes an addition to a record and queues it, in one transaction.
///
/// The record screen can add a note, a behaviour or an age and sex to a
/// sighting, and can correct what was recorded. Both are somebody's
/// observation, so each has to survive the screen closing and each has to reach
/// the service eventually. Both are writes, and doing them separately leaves a
/// window where the record shows the addition and the queue has never heard of
/// it — which is a change the client believes it has made and will never send.
class SightingAmender {
  const SightingAmender(this._db, this._queue);

  final FieldLogDatabase _db;
  final OperationQueue _queue;

  /// Returns the queued operation's id, or null when there is no such record.
  ///
  /// Null rather than an exception: the map only draws pins for rows it has
  /// read, so this should not happen, and a screen that crashed because a
  /// record vanished underneath it would be worse than one that reports
  /// quietly that it could not add anything.
  Future<String?> amend(String localId, SightingAmendment amendment) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.sightings,
      )..where((t) => t.localId.equals(localId))).getSingleOrNull();
      if (row == null) {
        return null;
      }

      // Exactly one column is written, chosen by the kind of addition. The
      // others are left absent rather than blanked, because a write that blanked
      // everything it did not name would erase the record.
      final write = switch (amendment.kind) {
        // Appended, never replaced. Rule 6 forbids discarding what the trainee
        // wrote, and a screen offering "add a note" that then overwrote the
        // previous one would be doing exactly that.
        AmendmentKind.note => SightingsCompanion(
          notes: Value(_append(row.notes, amendment.value)),
          hasPendingChanges: const Value(true),
        ),
        AmendmentKind.behaviour => SightingsCompanion(
          behaviour: Value(amendment.value),
          hasPendingChanges: const Value(true),
        ),
        AmendmentKind.ageSex => SightingsCompanion(
          ageSexClass: Value(amendment.value),
          hasPendingChanges: const Value(true),
        ),
      };

      await (_db.update(
        _db.sightings,
      )..where((t) => t.localId.equals(localId))).write(write);

      // The sentence is sent, not the addition. The service replaces the column
      // with what it is handed rather than adding to what it holds, so sending
      // only the new sentence would drop the notes already on the record.
      final payload = <String, dynamic>{
        amendment.kind.field: amendment.kind == AmendmentKind.note
            ? _append(row.notes, amendment.value)
            : amendment.value,
      };

      // The base revision is the one this client holds, so the service can tell
      // an addition made on top of what we knew from one made on top of
      // something else entirely.
      //
      // The queue encodes it. Passing an already-encoded string here would
      // store the bytes of a JSON document inside the JSON document, which is
      // a payload nothing could ever read back.
      return _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.sighting,
        kind: OperationKind.update,
        baseRevision: row.revision,
        capturedAt: row.capturedAt,
        recordedAt: DateTime.now().toUtc(),
        payload: payload,
      );
    });
  }

  /// Applies a correction to a record and queues it.
  ///
  /// Separate from [amend] because the two write different things. An addition
  /// puts a little more into the record; a correction moves fields a reviewer
  /// compares against what was first claimed, and it carries the reason. The
  /// form that edits a record does both, and collapsing them would mean either
  /// losing the reason or demanding one where none is owed.
  ///
  /// Returns the queued operation's id, or null when there is no such record or
  /// the correction names nothing to write.
  Future<String?> correct(String localId, SightingCorrection correction) {
    return _db.transaction(() async {
      if (correction.isEmpty) {
        return null;
      }
      final row = await (_db.select(
        _db.sightings,
      )..where((t) => t.localId.equals(localId))).getSingleOrNull();
      if (row == null) {
        return null;
      }

      // Every field the correction leaves out is passed as Value.absent, which
      // drift omits from the statement entirely. A field written as an explicit
      // null would blank it, and the record would lose what the form never
      // asked about.
      final write = SightingsCompanion(
        hasPendingChanges: const Value(true),
        speciesCode: correction.speciesCode == null
            ? const Value.absent()
            : Value(correction.speciesCode),
        count: correction.count == null
            ? const Value.absent()
            : Value(correction.count),
        behaviour: correction.behaviour == null
            ? const Value.absent()
            : Value(correction.behaviour),
        ageSexClass: correction.ageSexClass == null
            ? const Value.absent()
            : Value(correction.ageSexClass),
        notes: correction.notes == null
            ? const Value.absent()
            : Value(correction.notes),
      );

      // Only the keys the correction names are sent. The service reads a key it
      // is given and leaves alone one it is not, so sending the whole record
      // would make a correction that mentioned nothing else look like it had.
      final payload = <String, dynamic>{
        if (correction.speciesCode != null)
          'species_code': correction.speciesCode,
        if (correction.count != null) 'count': correction.count,
        if (correction.behaviour != null) 'behaviour': correction.behaviour,
        if (correction.ageSexClass != null)
          'age_sex_class': correction.ageSexClass,
        if (correction.notes != null) 'notes': correction.notes,
        if (correction.reason != null) 'correction_reason': correction.reason,
      };

      await (_db.update(
        _db.sightings,
      )..where((t) => t.localId.equals(localId))).write(write);

      // The reason is not a column here: it is the service's to hold, against
      // the originals it also holds. A copy on this side would be a second
      // thing to keep in step with the first.

      return _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.sighting,
        kind: OperationKind.update,
        baseRevision: row.revision,
        capturedAt: row.capturedAt,
        recordedAt: DateTime.now().toUtc(),
        payload: payload,
      );
    });
  }

  /// Applies a verification decision to a record and queues it.
  ///
  /// A verification is a mentor's answer: the outcome (verified, rejected,
  /// needs_review), optional corrections to species/count, and the mentor's
  /// reasoning. The service requires a correction_reason when species or count
  /// is changed. Returns the queued operation's id, or null when there is no
  /// such record or the verification names nothing to write.
  Future<String?> verify(String localId, SightingVerification verification) {
    return _db.transaction(() async {
      if (verification.isEmpty) {
        return null;
      }
      final row = await (_db.select(
        _db.sightings,
      )..where((t) => t.localId.equals(localId))).getSingleOrNull();
      if (row == null) {
        return null;
      }

      // A verification must have an outcome. needs_review is allowed without
      // any other changes, but verified/rejected without any changes is a
      // valid "confirmation" that the record stands as-is.
      final hasOutcome =
          verification.outcome != VerificationOutcome.needsReview ||
          verification.verificationNotes != null ||
          verification.changesClaim;

      // Every field the verification leaves out is passed as Value.absent, which
      // drift omits from the statement entirely. A field written as an explicit
      // null would blank it, and the record would lose what the form never
      // asked about.
      final write = SightingsCompanion(
        hasPendingChanges: const Value(true),
        status: verification.outcome == VerificationOutcome.verified
            ? Value(SightingStatus.verified)
            : verification.outcome == VerificationOutcome.rejected
            ? Value(SightingStatus.rejected)
            : Value(SightingStatus.needsReview),
        verifiedBy: const Value.absent(), // Set by the server from the caller
        verifiedAt: const Value.absent(), // Set by the server
        verificationNotes: verification.verificationNotes == null
            ? const Value.absent()
            : Value(verification.verificationNotes),
        speciesCode: verification.speciesCode == null
            ? const Value.absent()
            : Value(verification.speciesCode),
        count: verification.count == null
            ? const Value.absent()
            : Value(verification.count),
        behaviour: verification.behaviour == null
            ? const Value.absent()
            : Value(verification.behaviour),
        ageSexClass: verification.ageSexClass == null
            ? const Value.absent()
            : Value(verification.ageSexClass),
        notes: verification.notes == null
            ? const Value.absent()
            : Value(verification.notes),
      );

      // Only the keys the verification names are sent. The service reads a key
      // it is given and leaves alone one it is not, so sending the whole record
      // would make a verification that mentioned nothing else look like it had.
      final payload = <String, dynamic>{
        'status': verification.outcome == VerificationOutcome.verified
            ? 'verified'
            : verification.outcome == VerificationOutcome.rejected
            ? 'rejected'
            : 'needs_review',
        if (verification.verificationNotes != null)
          'verification_notes': verification.verificationNotes,
        if (verification.reason != null)
          'correction_reason': verification.reason,
        if (verification.speciesCode != null)
          'species_code': verification.speciesCode,
        if (verification.count != null) 'count': verification.count,
        if (verification.behaviour != null) 'behaviour': verification.behaviour,
        if (verification.ageSexClass != null)
          'age_sex_class': verification.ageSexClass,
        if (verification.notes != null) 'notes': verification.notes,
      };

      await (_db.update(
        _db.sightings,
      )..where((t) => t.localId.equals(localId))).write(write);

      // The base revision is the one this client holds, so the service can tell
      // a verification made on top of what we knew from one made on top of
      // something else entirely.
      return _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.sighting,
        kind: OperationKind.update, // Maps to 'correct' wire for sightings
        baseRevision: row.revision,
        capturedAt: row.capturedAt,
        recordedAt: DateTime.now().toUtc(),
        payload: payload,
      );
    });
  }

  /// A note goes below the existing ones, separated so two additions do not run
  /// together into one sentence.
  static String _append(String? existing, String addition) {
    final before = existing?.trimRight() ?? '';
    if (before.isEmpty) {
      return addition;
    }
    return '$before\n\n$addition';
  }
}
