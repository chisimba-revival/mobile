import 'package:drift/drift.dart';

import '../models/sync_operation.dart';
import 'database.dart';
import 'mappers.dart';

/// What one page of the change feed did to the local store.
///
/// Returned rather than logged, because the counts are the only way a caller can
/// tell a page that genuinely changed nothing from a page that was quietly
/// dropped. A resync-required response is a normal path through this engine, not
/// an error.
class PullOutcome {
  const PullOutcome({
    required this.applied,
    required this.conflicts,
    required this.cursorAdvanced,
    required this.nextCursor,
  });

  /// Changes written to the store.
  final int applied;

  /// Changes deliberately not written, each recorded in the conflicts table.
  ///
  /// Non-zero is not itself a failure. A record carrying unaccepted local edits
  /// alongside a newer server revision is a conflict, and the contract is
  /// explicit that neither side may be discarded to make it go away.
  final int conflicts;

  /// Whether the cursor moved.
  ///
  /// True whenever the transaction commits, which is the entire point: the
  /// cursor is written in the same transaction as the page, so it can only ever
  /// become true once the page it arrived with is durable.
  final bool cursorAdvanced;

  /// The cursor for the next pull, or null at the end of the feed.
  final String? nextCursor;
}

/// Applies pages of the change feed to the local store.
///
/// The contract states the cursor rule in one sentence and it is load-bearing:
/// *the client writes a new cursor only after the page it arrived with has been
/// applied.* Those are two writes. Done separately they leave a window in which a
/// crash keeps the cursor and loses the page, and a client in that state stops
/// receiving changes it has never seen and cannot tell anything is wrong.
class PullEngine {
  PullEngine(this._db);

  final FieldLogDatabase _db;

  /// Apply one page for one scope, and advance that scope's cursor atomically.
  ///
  /// [scope] is a grant or context scope rather than one global cursor, because
  /// the set of changes a client may see changes when a context grant does.
  Future<PullOutcome> applyPage({
    required String scope,
    required PullPage page,
  }) {
    // The whole body is one transaction. Either the changes and the cursor both
    // land or neither does. Re-delivery is harmless because every change is
    // applied by revision, so the same page twice is the same page once.
    return _db.transaction(() async {
      var applied = 0;
      var conflicts = 0;

      for (final change in page.changes) {
        if (await _applyChange(change, page.serverTime)) {
          applied++;
        } else {
          conflicts++;
        }
      }

      await _writeCursor(scope, page);

      return PullOutcome(
        applied: applied,
        conflicts: conflicts,
        cursorAdvanced: true,
        nextCursor: page.nextCursor,
      );
    });
  }

  /// The cursor for one scope, or null before the first successful pull.
  Future<String?> cursorFor(String scope) async {
    final query = _db.select(_db.syncCursors)
      ..where((t) => t.scope.equals(scope));
    final row = await query.getSingleOrNull();
    return row?.cursor;
  }

  Future<void> _writeCursor(String scope, PullPage page) {
    return _db
        .into(_db.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(
            scope: scope,
            // Null at the end of the feed, which is a real value and not the same as
            // "never pulled". The row existing at all is what tells them apart.
            cursor: Value(page.nextCursor),
            serverTimeAtApply: Value(page.serverTime.toUtc()),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  /// Returns true when the change reached the store, false when it was held back.
  Future<bool> _applyChange(PullChange change, DateTime serverTime) async {
    if (change.entity != EntityKind.sighting) {
      // Other kinds are not merged yet. Ignoring them outright would let the
      // cursor advance past changes that were never stored, so each one is
      // recorded as outstanding instead of dropped, and the gap shows up in the
      // returned counts rather than hiding behind a zero.
      await _hold(
        change,
        'entity kind ${change.entity.name} is not merged yet',
      );
      return false;
    }

    final existing = await _rowFor(change.entityId);

    // Rule 6: revision is the only thing that arbitrates. An out-of-order or
    // re-delivered page must never walk a record backwards, so a revision that
    // is not strictly greater is ignored.
    if (existing != null && change.revision <= existing.revision) {
      return true;
    }

    // A record with unaccepted local edits cannot simply be overwritten; doing so
    // discards the trainee's edit silently, which rule 6 forbids.
    if (existing != null && existing.hasPendingChanges) {
      await _hold(
        change,
        'local record carries unaccepted changes at revision '
        '${existing.revision}',
      );
      return false;
    }

    if (change.isTombstone) {
      // Rule 9: a deletion is a row, not an absence. The values stay so the
      // audit trail survives, and the row is marked so the client stops offering
      // it for editing.
      await (_db.update(
        _db.sightings,
      )..where((t) => t.localId.equals(change.entityId))).write(
        SightingsCompanion(
          isTombstone: const Value(true),
          deletedAt: Value(serverTime.toUtc()),
          // The tombstone carries the revision at which the record was deleted.
          // Recording it is what stops a later page arriving at the same revision
          // from reapplying the record it has just removed.
          revision: Value(change.revision),
          hasPendingChanges: const Value(false),
        ),
      );
      return true;
    }

    final state = change.state;
    if (state == null) {
      await _hold(change, 'change carried no state and was not a tombstone');
      return false;
    }

    if (existing == null) {
      final missing = _missingForNewRow(state);
      if (missing.isNotEmpty) {
        // A new row needs what the schema declares non-null. Supplying defaults
        // here would put a record in the logbook that nobody observed.
        await _hold(change, 'new sighting missing ${missing.join(', ')}');
        return false;
      }
      await _db
          .into(_db.sightings)
          .insert(
            sightingPatchFromState(state, fallbackLocalId: change.entityId),
          );
      return true;
    }

    await (_db.update(_db.sightings)
          ..where((t) => t.localId.equals(change.entityId)))
        .write(sightingPatchFromState(state, fallbackLocalId: change.entityId));
    return true;
  }

  static const _requiredForNewRow = <String>[
    'context_code',
    'drive_id',
    'status',
    'captured_at',
    'recorded_at',
    'created_by',
  ];

  List<String> _missingForNewRow(Map<String, dynamic> state) {
    final missing = <String>[];
    for (final key in _requiredForNewRow) {
      if (!state.containsKey(key) || state[key] == null) {
        missing.add(key);
      }
    }
    if (state['location'] == null) {
      missing.add('location');
    }
    return missing;
  }

  Future<SightingRow?> _rowFor(String localId) {
    final query = _db.select(_db.sightings)
      ..where((t) => t.localId.equals(localId));
    return query.getSingleOrNull();
  }

  /// Keep both sides of a disagreement rather than settling it locally.
  ///
  /// Keyed by a synthetic operation id because this conflict did not come from a
  /// push. Re-delivering the same page must not stack duplicates that a person
  /// then has to dismiss one at a time, hence insertOrIgnore.
  Future<void> _hold(PullChange change, String why) async {
    // No transaction wrapper here. Every caller is already inside applyPage's
    // transaction, and nesting one would be at best redundant and at worst a
    // deadlock against the same connection.
    final localId = change.entityId;
    final local = await _rowFor(localId);
    await _db
        .into(_db.conflicts)
        .insert(
          ConflictsCompanion.insert(
            operationId: 'pull:$localId:${change.revision}',
            entityId: localId,
            entity: change.entity,
            clientPayload: local == null
                ? ''
                : encodePayload(sightingToState(local.toModel())),
            serverState: encodePayload({...?change.state, 'held_because': why}),
            serverRevision: change.revision,
            baseRevision: local?.revision ?? 0,
            errorCode: 'pull_held',
            recordedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
