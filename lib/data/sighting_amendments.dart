import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/sync_operation.dart';

/// What kind of thing was added to a record.
///
/// The names are the ones the record screen uses when it reports an addition,
/// so the two cannot drift apart by accident.
enum AmendmentKind {
  note('note'),
  behaviour('behaviour'),
  ageSex('age_sex');

  const AmendmentKind(this.wire);

  final String wire;

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

/// Writes an addition to a record and queues it, in one transaction.
///
/// The record screen can add a note, a behaviour or an age and sex to a
/// sighting. That addition is somebody's observation, so it has to survive the
/// screen closing and it has to reach the service eventually. Both are writes,
/// and doing them separately leaves a window where the record shows the
/// addition and the queue has never heard of it — which is a change the client
/// believes it has made and will never send.
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

      // The base revision is the one this client holds, so the service can tell
      // an addition made on top of what we knew from one made on top of
      // something else entirely.
      return _queue.enqueueNew(
        entityId: localId,
        entity: EntityKind.sighting,
        kind: OperationKind.update,
        baseRevision: row.revision,
        capturedAt: row.capturedAt,
        recordedAt: DateTime.now().toUtc(),
        // The queue encodes it. Passing an already-encoded string here would
        // store the bytes of a JSON document inside the JSON document, which is
        // a payload nothing could ever read back.
        payload: <String, dynamic>{
          'amendment': amendment.kind.wire,
          'value': amendment.value,
        },
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
