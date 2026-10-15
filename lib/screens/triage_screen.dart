import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/design/components.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/models/sighting.dart';
import 'package:field_log/models/sync_operation.dart';

/// Why an item is on the triage screen. The reason decides which section it
/// lands in and how the row leads, not what colour it is painted.
enum TriageReason {
  /// A record written in words that nobody has identified yet. The one thing a
  /// trainee can actually finish here.
  unidentified,

  /// A mentor looked and has not decided. Not a task for the trainee, but the
  /// record is not settled either, so it belongs in "needs me".
  needsReview,

  /// The service refused a change and the two sides disagree. A person has to
  /// read both before either is discarded.
  conflict,

  /// A record captured today, listed for orientation rather than action.
  today,
}

/// One row on the triage screen: either something waiting on a person or a
/// record captured today.
class TriageItem {
  const TriageItem({
    required this.id,
    required this.reason,
    required this.title,
    required this.detail,
    this.visual,
    this.localId,
    this.capturedAt,
  });

  /// Unique within the list, so a row keeps its identity across rebuilds.
  final String id;

  final TriageReason reason;
  final String title;
  final String detail;

  /// The pin's tab, drawn small for a record. Null for a conflict, which has no
  /// pin of its own.
  final PinVisual? visual;

  /// The record to open, when there is one. Null for a conflict, which is
  /// resolved on the queue screen.
  final String? localId;

  /// When the record happened, for ordering. Null for conflicts.
  final DateTime? capturedAt;
}

/// Everything the triage screen shows, read in one pass.
///
/// A value object so the screen can be driven entirely from a fixture in a
/// test, the way [SyncLedgerScreen] and [ObservationsScreen] can.
class TriageSnapshot {
  const TriageSnapshot({
    required this.needsMe,
    required this.capturedToday,
    required this.queuedCount,
    this.lastSyncedAt,
    this.syncError,
  });

  const TriageSnapshot.empty()
    : needsMe = const <TriageItem>[],
      capturedToday = const <TriageItem>[],
      queuedCount = 0,
      lastSyncedAt = null,
      syncError = null;

  final List<TriageItem> needsMe;
  final List<TriageItem> capturedToday;
  final int queuedCount;
  final DateTime? lastSyncedAt;
  final String? syncError;
}

/// The one screen that answers "is anything waiting on me?".
///
/// It reads the local replica and nothing else — three questions over the same
/// store the map and the logbooks write to: what has not been identified, what
/// the service refused, and what this device captured today. It writes nothing
/// itself; the rows hand off to the screen that owns the write (the pin detail
/// for a record, the queue for a conflict). That is what keeps it honest: a
/// triage list that could edit a record would be a fourth place the record's
/// rules live.
class TriageScreen extends StatefulWidget {
  const TriageScreen({
    super.key,
    this.database,
    this.snapshot,
    this.onOpenSighting,
    this.onOpenLedger,
    this.onSyncNow,
    this.onBack,
  });

  /// The local replica to read. Optional so the screen can also be driven
  /// entirely by [snapshot], which is how it is tested.
  final FieldLogDatabase? database;

  /// A prebuilt snapshot, bypassing the database.
  final TriageSnapshot? snapshot;

  /// Opens one record by local id. When null the row is not tappable.
  final void Function(String localId)? onOpenSighting;

  /// Opens the queue, where a conflict is read and resolved.
  final VoidCallback? onOpenLedger;

  /// Starts a sync from the "Sync now" action. Optional; the queue screen is
  /// still the place to watch it.
  final VoidCallback? onSyncNow;

  /// Overrides the back arrow, for a host that pushes this as a dialog.
  final VoidCallback? onBack;

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  TriageSnapshot _snapshot = const TriageSnapshot.empty();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) {
      _snapshot = widget.snapshot!;
      _loading = false;
    } else {
      _read();
    }
  }

  Future<void> _read() async {
    final db = widget.database;
    if (db == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final snapshot = await _readSnapshot(db);
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  /// The one read pass. Kept a static function so it can be exercised without
  /// a widget, and so the classification rules live in a single place.
  static Future<TriageSnapshot> _readSnapshot(FieldLogDatabase db) async {
    final session = db.select(db.sightings)
      ..where((t) => t.isTombstone.equals(false));
    final rows = await session.get();

    final conflicts =
        await (db.select(db.conflicts)
              ..where((t) => t.resolvedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
            .get();
    final queuedCount = (await OperationQueue(db).pending(limit: 500)).length;

    final needsMe = <TriageItem>[];
    for (final row in rows) {
      final reason = switch (row) {
        _ when (row.speciesCode?.trim().isEmpty ?? true) =>
          TriageReason.unidentified,
        _ when row.status == SightingStatus.needsReview =>
          TriageReason.needsReview,
        _ => null,
      };
      if (reason == null) continue;
      needsMe.add(_itemFor(row, reason));
    }
    for (final conflict in conflicts) {
      needsMe.add(_itemForConflict(conflict));
    }
    needsMe.sort((a, b) {
      final at = a.capturedAt;
      final bt = b.capturedAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    final startOfToday = _startOfToday();
    final capturedToday = <TriageItem>[
      for (final row in rows)
        if (!row.capturedAt.toLocal().isBefore(startOfToday))
          _itemFor(row, TriageReason.today),
    ]..sort((a, b) => b.capturedAt!.compareTo(a.capturedAt!));

    return TriageSnapshot(
      needsMe: needsMe,
      capturedToday: capturedToday,
      queuedCount: queuedCount,
    );
  }

  static TriageItem _itemFor(SightingRow row, TriageReason reason) {
    final visual = pinVisualFor(row, commonNameFor: _nameOf);
    return TriageItem(
      id: row.localId,
      reason: reason,
      title: _titleFor(row),
      detail: _detailFor(row, reason),
      visual: visual,
      localId: row.localId,
      capturedAt: row.capturedAt,
    );
  }

  static TriageItem _itemForConflict(ConflictRow conflict) {
    return TriageItem(
      id: 'conflict:${conflict.operationId}',
      reason: TriageReason.conflict,
      title: 'Refused: ${_entityTitle(conflict.entity)}',
      detail:
          '${conflict.errorCode} · base r${conflict.baseRevision} vs '
          'server r${conflict.serverRevision} · ${_when(conflict.recordedAt)}',
      capturedAt: conflict.recordedAt,
    );
  }

  /// The record's honest name: the species code, or "Unidentified" when it was
  /// recorded in words. A code is what the client holds; the service supplies
  /// the common name later.
  static String _titleFor(SightingRow row) {
    final code = row.speciesCode?.trim() ?? '';
    if (code.isEmpty) {
      final note = (row.notes ?? '').trim();
      return note.isEmpty ? 'Unidentified record' : '“${_excerpt(note)}”';
    }
    return code;
  }

  static String _detailFor(SightingRow row, TriageReason reason) {
    final count = row.count;
    return switch (reason) {
      TriageReason.unidentified =>
        'Not yet identified · ${_when(row.capturedAt)}',
      TriageReason.needsReview =>
        'A mentor has not decided yet · ${_when(row.capturedAt)}',
      TriageReason.today =>
        '${count == null ? 'Not counted' : '$count seen'} · '
            '${_when(row.capturedAt)}',
      TriageReason.conflict => _when(row.capturedAt),
    };
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return FieldScaffold(
      eyebrow: 'Today',
      title: 'What is waiting on me',
      onBack: widget.onBack,
      actions: [
        if (widget.onOpenLedger != null)
          FieldIconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: widget.onOpenLedger!,
            tooltip: 'Queue',
          ),
      ],
      body: _loading
          ? const Center(child: FieldCircularProgress())
          : RefreshIndicator(
              onRefresh: _read,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  Insets.md,
                  Insets.md,
                  Insets.xl,
                ),
                children: [
                  _queueCard(context, colours),
                  if (_snapshot.needsMe.isEmpty &&
                      _snapshot.capturedToday.isEmpty)
                    _allClear(context, colours),
                  _section(
                    context,
                    colours,
                    'Needs me',
                    _snapshot.needsMe,
                    'Nothing is waiting on you.',
                  ),
                  _section(
                    context,
                    colours,
                    'Captured today',
                    _snapshot.capturedToday,
                    'No records captured yet today.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _queueCard(BuildContext context, FieldColours colours) {
    final queued = _snapshot.queuedCount;
    final String state;
    final Color tint;
    if (_snapshot.syncError != null) {
      state = 'Sync failed — will retry';
      tint = colours.blood;
    } else if (queued == 0) {
      state = _snapshot.lastSyncedAt == null
          ? 'Nothing waiting · never synced'
          : 'All sent · last synced ${_ago(_snapshot.lastSyncedAt!)}';
      tint = colours.moss;
    } else {
      state = queued == 1
          ? '1 change waiting to upload'
          : '$queued changes waiting to upload';
      tint = colours.straw;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.lg),
      child: FieldCard(
        elevation: FieldCardElevation.raised,
        child: Row(
          children: [
            Icon(Icons.cloud_outlined, color: tint, size: IconSizes.md),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offline queue',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.stamp,
                      letterSpacing: 1.1,
                      color: colours.ash2,
                    ),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    state,
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.body,
                      color: colours.bone,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onSyncNow != null)
              FieldIconButton(
                icon: const Icon(Icons.sync),
                onPressed: widget.onSyncNow!,
                tooltip: 'Sync now',
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    FieldColours colours,
    String title,
    List<TriageItem> items,
    String emptyLine,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldSectionHeader(
          label: title,
          trailing: items.isEmpty
              ? null
              : Text(
                  '${items.length}',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    color: colours.ash2,
                  ),
                ),
        ),
        const SizedBox(height: Insets.sm),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: Insets.md, bottom: Insets.lg),
            child: Text(
              emptyLine,
              style: TextStyle(
                fontFamily: Faces.book.first,
                fontStyle: FontStyle.italic,
                color: colours.ash3,
              ),
            ),
          )
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: FieldListTile(
                key: ValueKey(item.id),
                leading: item.visual == null
                    ? _ReasonGlyph(reason: item.reason, colours: colours)
                    : _Glyph(visual: item.visual!),
                title: item.title,
                subtitle: item.detail,
                trailing: item.reason == TriageReason.conflict
                    ? Icon(Icons.chevron_right, color: colours.ash2)
                    : null,
                onTap: _tapFor(item),
              ),
            ),
      ],
    );
  }

  VoidCallback? _tapFor(TriageItem item) {
    if (item.reason == TriageReason.conflict) {
      return widget.onOpenLedger;
    }
    final localId = item.localId;
    final open = widget.onOpenSighting;
    if (localId == null || open == null) return null;
    return () => open(localId);
  }

  Widget _allClear(BuildContext context, FieldColours colours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: colours.moss, size: 32),
          const SizedBox(height: Insets.sm),
          Text(
            'Nothing needs you',
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontStyle: FontStyle.italic,
              color: colours.ash2,
            ),
          ),
        ],
      ),
    );
  }

  /// Species names are the reference data's job; without a loader the code is
  /// the honest name rather than an invented one.
  static String _nameOf(String code) => code;

  static String _entityTitle(EntityKind entity) => switch (entity) {
    EntityKind.sighting => 'Sighting',
    EntityKind.drive => 'Drive',
    EntityKind.trailLog => 'Trail log',
    EntityKind.signOff => 'Sign-off',
    EntityKind.media => 'Media',
    EntityKind.outing => 'Outing',
    EntityKind.dangerousGame => 'Dangerous game',
    EntityKind.plannedRoute => 'Planned route',
    EntityKind.routeWaypoint => 'Route waypoint',
    EntityKind.trailWaypoint => 'Waypoint',
    EntityKind.unknown => 'Unknown record',
  };
}

/// The reason a row is here, drawn as a small tab when the row has no pin.
class _ReasonGlyph extends StatelessWidget {
  const _ReasonGlyph({required this.reason, required this.colours});

  final TriageReason reason;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (reason) {
      TriageReason.conflict => (Icons.error_outline, colours.blood),
      TriageReason.needsReview => (Icons.hourglass_empty, colours.straw),
      TriageReason.unidentified => (Icons.help_outline, colours.ash1),
      TriageReason.today => (Icons.visibility_outlined, colours.ash1),
    };
    return Semantics(
      label: switch (reason) {
        TriageReason.conflict => 'Conflict',
        TriageReason.needsReview => 'Needs review',
        TriageReason.unidentified => 'Not yet identified',
        TriageReason.today => 'Captured today',
      },
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colours.canopyRaised,
          borderRadius: BorderRadius.circular(Corners.chip),
          border: Border.all(color: colours.rule),
        ),
        child: Icon(icon, color: tint, size: IconSizes.sm),
      ),
    );
  }
}

/// The pin's tab, drawn small, so a row leads with the same glyph the map does.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.visual});

  final PinVisual visual;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Semantics(
      label: visual.spoken,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colours.canopyRaised,
          borderRadius: BorderRadius.circular(Corners.chip),
          border: Border.all(color: colours.rule),
        ),
        child: Text(
          visual.glyph,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 15,
            color: colours.bone,
          ),
        ),
      ),
    );
  }
}

String _when(DateTime at) {
  final local = at.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

/// A coarse "how long ago" for the last clean sync. Coarse on purpose: the
/// difference between two minutes and three is not worth a second timer.
String _ago(DateTime at) {
  final delta = DateTime.now().difference(at);
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
  if (delta.inHours < 24) return '${delta.inHours} h ago';
  return '${delta.inDays} d ago';
}

/// A note's opening words, flattened and capped, so a long note does not push
/// the row past its line. The same cap the pin's spoken read-out uses.
String _excerpt(String note) {
  final flat = note.replaceAll(RegExp(r'\s+'), ' ');
  return flat.length <= 40 ? flat : '${flat.substring(0, 40)}…';
}
