import 'package:drift/drift.dart';

import '../models/sync_operation.dart';
import 'database.dart';
import 'mappers.dart';
import 'tables.dart';

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
    this.resyncRequired = false,
  });

  /// The service declined to serve a page and asked for a full re-pull.
  ///
  /// This is a normal outcome rather than an error. A device that has been out
  /// of coverage for long enough will receive one eventually, and treating it
  /// as a failure would mean a device that has worked correctly for weeks
  /// suddenly stops receiving changes with nothing to tell the trainee why.
  final bool resyncRequired;

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
      // Nothing is applied and no cursor is written. Applying a partial page
      // would leave the store holding some of what the service has and none of
      // the rest, which is the one state a replica must never be in, and the
      // cursor in particular must not move: a cursor written against a page
      // that was never applied is how a client stops seeing changes for data
      // it has never seen.
      if (page.requiresResync) {
        return const PullOutcome(
          applied: 0,
          conflicts: 0,
          cursorAdvanced: false,
          nextCursor: null,
          resyncRequired: true,
        );
      }

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

  /// Forget every cursor, so the next pull starts from the beginning.
  ///
  /// This is the whole of a resync: discard the cursors and re-pull the full
  /// accessible scope. It is safe precisely because [applyPage] applies by
  /// revision, so re-delivering everything the client already holds is a no-op
  /// rather than a second copy. Nothing local is deleted, and nothing needs to
  /// be: deletions arrive as tombstones in the full pull, and this device's own
  /// unsent records are not the service's to remove.
  ///
  /// Returns the number of cursors dropped, so a caller can tell a resync from a
  /// scope it had never pulled.
  Future<int> forgetCursors() {
    return _db.transaction(() async {
      final dropped = await _db.delete(_db.syncCursors).go();
      return dropped;
    });
  }

  /// Whether the client has a cursor for [scope] at all.
  ///
  /// Distinct from a null cursor value: the row existing means this scope has
  /// been pulled, and a null cursor on an existing row means end of feed.
  Future<bool> hasPulled(String scope) async {
    final query = _db.select(_db.syncCursors)
      ..where((t) => t.scope.equals(scope));
    return await query.getSingleOrNull() != null;
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
  ///
  /// The feed names four entities, and an outing's body says which sort it is:
  /// an `outing` change is a drive or a hike by its `kind`, while the older
  /// names (`drive`, `trail_log`) are followed straight to their table. Every
  /// arm that does not merge records the change in the conflicts table rather
  /// than dropping it, because a change passed over in silence is a gap the
  /// client will never look for.
  Future<bool> _applyChange(PullChange change, DateTime serverTime) async {
    switch (change.entity) {
      case EntityKind.sighting:
        return _applySighting(change, serverTime);
      case EntityKind.outing:
        final kind = change.state?['kind'];
        if (kind == 'drive') return _applyDrive(change, serverTime);
        if (kind == 'hike') return _applyHike(change, serverTime);
        // A camp, or a kind this client has never heard of, has no table
        // here — and a tombstone of a legacy outing whose kind column predates
        // it cannot be told apart from a deletion of the other sort. Holding
        // keeps the fact visible instead of guessing.
        await _hold(
          change,
          'outing kind ${kind ?? 'unstated'} is not merged yet',
        );
        return false;
      case EntityKind.drive:
        return _applyDrive(change, serverTime);
      case EntityKind.trailLog:
        return _applyHike(change, serverTime);
      case EntityKind.dangerousGame:
        return _applyEncounter(change, serverTime);
      case EntityKind.trailWaypoint:
        return _applyWaypoint(change, serverTime);
      case EntityKind.signOff:
      case EntityKind.media:
      case EntityKind.unknown:
        await _hold(
          change,
          'entity kind ${change.entity.name} is not merged yet',
        );
        return false;
    }
  }

  Future<bool> _applySighting(PullChange change, DateTime serverTime) async {
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
      if (existing == null) {
        // The update below would match no rows and report success, so the
        // deletion would be discarded with nothing to show for it: no row, no
        // conflict, no trace. The client would never learn this record was
        // deleted, and a record created locally under that id later would be
        // wrong. Holding it keeps the fact that something was deleted, which is
        // the part rule 9 actually insists on.
        await _hold(
          change,
          'record was deleted before this client ever saw it',
        );
        return false;
      }

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

  /// Merge a drive outing.
  ///
  /// The body never carries the drive's detail — duration, guests, inspection
  /// — so a pull can only ever touch the outing itself. Device-computed facts
  /// the service does not hold survive a pull untouched, which is the right
  /// direction for facts one side measured and the other merely stores.
  Future<bool> _applyDrive(PullChange change, DateTime serverTime) async {
    final existing = await (_db.select(
      _db.drives,
    )..where((t) => t.localId.equals(change.entityId))).getSingleOrNull();

    if (existing != null && change.revision <= existing.revision) return true;
    if (existing != null && existing.hasPendingChanges) {
      await _hold(
        change,
        'local record carries unaccepted changes at revision '
        '${existing.revision}',
      );
      return false;
    }

    if (change.isTombstone) {
      if (existing == null) {
        await _hold(
          change,
          'record was deleted before this client ever saw it',
        );
        return false;
      }
      await (_db.update(
        _db.drives,
      )..where((t) => t.localId.equals(change.entityId))).write(
        DrivesCompanion(
          isTombstone: const Value(true),
          deletedAt: Value(serverTime.toUtc()),
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
      final missing = _missingKeys(state, const ['context_code', 'start_time']);
      if (missing.isNotEmpty) {
        await _hold(change, 'new drive outing missing ${missing.join(', ')}');
        return false;
      }
      await _db
          .into(_db.drives)
          .insert(drivePatchFromState(state, fallbackLocalId: change.entityId));
      return true;
    }

    await (_db.update(_db.drives)
          ..where((t) => t.localId.equals(change.entityId)))
        .write(drivePatchFromState(state, fallbackLocalId: change.entityId));
    return true;
  }

  /// Merge a trail log.
  ///
  /// Two local columns never arrive: the log's drive id and its trail code
  /// live on this device, and the service's outing has nowhere to keep them.
  /// An insert therefore takes empty placeholders — a label nobody has chosen
  /// yet, visible as unlabelled rather than invented — while an update keeps
  /// what this device already wrote.
  Future<bool> _applyHike(PullChange change, DateTime serverTime) async {
    final existing = await (_db.select(
      _db.trailLogs,
    )..where((t) => t.localId.equals(change.entityId))).getSingleOrNull();

    if (existing != null && change.revision <= existing.revision) return true;
    // A trail log keeps no pending flag of its own: every change it accepts is
    // queued as an operation, and an unsettled one is what this check would be
    // standing in for. Its start happened on one device, so a pull arriving
    // while an operation is outstanding belongs to the same exchange.
    if (existing != null && await _hasUnsettled(change.entityId)) {
      await _hold(
        change,
        'local record has an operation still waiting on the service',
      );
      return false;
    }

    if (change.isTombstone) {
      if (existing == null) {
        await _hold(
          change,
          'record was deleted before this client ever saw it',
        );
        return false;
      }
      await (_db.update(
        _db.trailLogs,
      )..where((t) => t.localId.equals(change.entityId))).write(
        TrailLogsCompanion(
          isTombstone: const Value(true),
          deletedAt: Value(serverTime.toUtc()),
          revision: Value(change.revision),
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
      final missing = _missingKeys(state, const ['context_code', 'start_time']);
      if (missing.isNotEmpty) {
        await _hold(change, 'new trail log missing ${missing.join(', ')}');
        return false;
      }
      await _db
          .into(_db.trailLogs)
          .insert(
            hikePatchFromState(
              state,
              fallbackLocalId: change.entityId,
              driveId: '',
              trailCode: '',
            ),
          );
      return true;
    }

    await (_db.update(
      _db.trailLogs,
    )..where((t) => t.localId.equals(change.entityId))).write(
      hikePatchFromState(
        state,
        fallbackLocalId: change.entityId,
        driveId: existing.driveId,
        trailCode: existing.trailCode,
      ),
    );
    return true;
  }

  /// Merge a dangerous-game encounter.
  ///
  /// An encounter is written once and never amended, so there is no local
  /// pending flag to consult: by the time the service can feed this id back,
  /// this device's own operation has already been accepted and the revision
  /// check above absorbs the echo.
  Future<bool> _applyEncounter(PullChange change, DateTime serverTime) async {
    final existing = await (_db.select(
      _db.dangerousGameEncounters,
    )..where((t) => t.localId.equals(change.entityId))).getSingleOrNull();

    if (existing != null && change.revision <= existing.revision) return true;

    if (change.isTombstone) {
      if (existing == null) {
        await _hold(
          change,
          'record was deleted before this client ever saw it',
        );
        return false;
      }
      await (_db.update(
        _db.dangerousGameEncounters,
      )..where((t) => t.localId.equals(change.entityId))).write(
        DangerousGameEncountersCompanion(
          isTombstone: const Value(true),
          deletedAt: Value(serverTime.toUtc()),
          revision: Value(change.revision),
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
      final missing = _missingKeys(state, const [
        'context_code',
        'outing_id',
        'species_code',
        'captured_at',
        'recorded_at',
      ]);
      if (state['location'] == null) missing.add('location');
      if (missing.isNotEmpty) {
        await _hold(change, 'new encounter missing ${missing.join(', ')}');
        return false;
      }
      await _db
          .into(_db.dangerousGameEncounters)
          .insert(
            encounterPatchFromState(state, fallbackLocalId: change.entityId),
          );
      return true;
    }

    await (_db.update(
      _db.dangerousGameEncounters,
    )..where((t) => t.localId.equals(change.entityId))).write(
      encounterPatchFromState(state, fallbackLocalId: change.entityId),
    );
    return true;
  }

  /// Merge a trail waypoint.
  ///
  /// A waypoint keeps no revision — its identity is the uuid both sides
  /// minted — so the arrival check is "have I seen this id", not "is this
  /// revision newer". Its parent log may arrive in a later page than its
  /// waypoints after a resync, so a missing parent is created as a
  /// placeholder: an empty trail code and context until the real log arrives
  /// to fill them, which it does, because the log's own change is still in the
  /// feed behind this one.
  Future<bool> _applyWaypoint(PullChange change, DateTime serverTime) async {
    final seen = await (_db.select(
      _db.trailWaypoints,
    )..where((t) => t.serverId.equals(change.entityId))).getSingleOrNull();
    if (seen != null) return true;

    if (change.isTombstone) {
      // The service's waypoint table has no deleted_at, so this cannot be a
      // real waypoint tombstone. Holding rather than ignoring keeps the
      // disagreement where a person can see it.
      await _hold(change, 'a waypoint deletion is not recognised here');
      return false;
    }

    final state = change.state;
    if (state == null) {
      await _hold(change, 'change carried no state and was not a tombstone');
      return false;
    }

    final missing = _missingKeys(state, const [
      'outing_id',
      'ordinal',
      'point',
      'captured_at',
    ]);
    if (missing.isNotEmpty) {
      await _hold(change, 'new waypoint missing ${missing.join(', ')}');
      return false;
    }

    final parentId = state['outing_id']! as String;
    final parent = await (_db.select(
      _db.trailLogs,
    )..where((t) => t.localId.equals(parentId))).getSingleOrNull();
    if (parent == null) {
      await _db
          .into(_db.trailLogs)
          .insert(
            TrailLogsCompanion(
              localId: Value(parentId),
              // The waypoint carries no context code and no trail name — the
              // service's waypoint table has no such columns — so the
              // placeholder is explicitly empty rather than guessed at.
              contextCode: const Value(''),
              driveId: const Value(''),
              trailCode: const Value(''),
              startedAt: Value(wireMoment(state['captured_at'])!),
              revision: const Value(0),
              serverId: const Value(null),
            ),
          );
    }

    // The primary key is (trail log, ordinal): two devices walking the same
    // outing and both at waypoint seven is a real disagreement, not a
    // duplicate. Inserting anyway would roll back the whole page, so the
    // loser is held as a conflict for a person to read.
    final ordinal = wireInt(state['ordinal'])!;
    final clash =
        await (_db.select(_db.trailWaypoints)..where(
              (t) => t.trailLogId.equals(parentId) & t.ordinal.equals(ordinal),
            ))
            .getSingleOrNull();
    if (clash != null) {
      await _hold(
        change,
        'waypoint #$ordinal already exists for this log under another identity',
      );
      return false;
    }

    await _db.into(_db.trailWaypoints).insert(waypointPatchFromState(state));
    return true;
  }

  /// Whether a queued operation for [entityId] has not settled yet.
  ///
  /// Used where a table has no pending column of its own. Settled operations
  /// — applied, refused, everything a person has already seen — do not hold
  /// anything back.
  Future<bool> _hasUnsettled(String entityId) async {
    final query = _db.select(_db.queuedOperations)
      ..where(
        (t) =>
            t.entityId.equals(entityId) &
            t.state.equals(OperationState.settled.name).not(),
      );
    return await query.getSingleOrNull() != null;
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
    // The service renamed the column: feed bodies carry outing_id, and a
    // transitional body may still carry drive_id. Either names the outing the
    // sighting belongs to; neither present means the record has no home and
    // a create without one is refused outright.
    if (missing.remove('drive_id') &&
        (state['outing_id'] == null && state['drive_id'] == null)) {
      missing.add('drive_id');
    }
    if (state['location'] == null) {
      missing.add('location');
    }
    return missing;
  }

  List<String> _missingKeys(Map<String, dynamic> state, List<String> keys) {
    return [
      for (final key in keys)
        if (!state.containsKey(key) || state[key] == null) key,
    ];
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
    final local = await _localSnapshot(change);
    await _db
        .into(_db.conflicts)
        .insert(
          ConflictsCompanion.insert(
            operationId: 'pull:$localId:${change.revision}',
            entityId: localId,
            entity: change.entity,
            clientPayload: local.payload,
            serverState: encodePayload({...?change.state, 'held_because': why}),
            serverRevision: change.revision,
            baseRevision: local.revision,
            errorCode: 'pull_held',
            recordedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// The local record as it stands, for the conflicts table.
  ///
  /// Whatever table the entity lives in, the conflict wants the same two
  /// things: this client's version of the record, and the revision it holds.
  /// A record this client does not have yields an empty payload and revision
  /// zero, which is the truth rather than a default.
  Future<({String payload, int revision})> _localSnapshot(
    PullChange change,
  ) async {
    final localId = change.entityId;
    switch (change.entity) {
      case EntityKind.sighting:
        final row = await _rowFor(localId);
        return (
          payload: row == null
              ? ''
              : encodePayload(sightingToState(row.toModel())),
          revision: row?.revision ?? 0,
        );
      case EntityKind.drive:
      case EntityKind.outing:
        final row = await (_db.select(
          _db.drives,
        )..where((t) => t.localId.equals(localId))).getSingleOrNull();
        return (
          payload: row == null ? '' : encodePayload(driveToState(row)),
          revision: row?.revision ?? 0,
        );
      case EntityKind.trailLog:
        final row = await (_db.select(
          _db.trailLogs,
        )..where((t) => t.localId.equals(localId))).getSingleOrNull();
        return (
          payload: row == null ? '' : encodePayload(hikeToState(row)),
          revision: row?.revision ?? 0,
        );
      case EntityKind.dangerousGame:
        final row = await (_db.select(
          _db.dangerousGameEncounters,
        )..where((t) => t.localId.equals(localId))).getSingleOrNull();
        return (
          payload: row == null ? '' : encodePayload(encounterToState(row)),
          revision: row?.revision ?? 0,
        );
      case EntityKind.trailWaypoint:
        final row = await (_db.select(
          _db.trailWaypoints,
        )..where((t) => t.serverId.equals(localId))).getSingleOrNull();
        return (
          payload: row == null
              ? ''
              : encodePayload(<String, dynamic>{
                  'outing_id': row.trailLogId,
                  'ordinal': row.ordinal,
                  'latitude': row.latitude,
                  'longitude': row.longitude,
                  'captured_at': row.recordedAt.toUtc().toIso8601String(),
                  if (row.elevationM != null) 'elevation_m': row.elevationM,
                  if (row.note != null) 'note': row.note,
                }),
          // A waypoint holds no revision; the conflict's server revision is
          // the only one the pair can show.
          revision: 0,
        );
      default:
        return (payload: '', revision: 0);
    }
  }
}
