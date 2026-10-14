import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/tables.dart' show OperationState;
import 'package:field_log/models/sync_operation.dart';
import 'package:field_log/design/components.dart';
import 'package:field_log/design/field_scaffold.dart'
    show FieldScaffold; // Only need FieldScaffold, not the old tokens import
import 'package:field_log/design/tokens.dart';
import 'package:field_log/design/theme.dart';
import 'package:flutter/material.dart';

/// What the queue is waiting to do.
///
/// Most of this screen exists to tell the truth about a machine: what is
/// queued, when it last tried, and which refusals need a person. One button is
/// offered — sync now — because an empty-queued-but-failing phone is exactly
/// the moment pressing it tells the reader something they would not otherwise
/// know.
class SyncLedgerScreen extends StatefulWidget {
  const SyncLedgerScreen({
    super.key,
    this.database,
    this.entries,
    required this.online,
    this.onClose,
    this.onSyncNow,
    this.lastSyncedAt,
  });

  final FieldLogDatabase? database;
  final List<LedgerEntry>? entries;
  final bool online;
  final VoidCallback? onClose;

  /// Starts a sync from the queue screen. The queue itself is never touched
  /// here; the host is handed the button and does the sending.
  final VoidCallback? onSyncNow;

  /// When the last sync finished cleanly, for the stamp under the title.
  /// Null until the first successful sync.
  final DateTime? lastSyncedAt;

  @override
  State<SyncLedgerScreen> createState() => _SyncLedgerScreenState();
}

class _SyncLedgerScreenState extends State<SyncLedgerScreen> {
  late final OperationQueue _queue;
  List<LedgerEntry> _entries = const [];
  bool _loading = true;

  /// Settled operations the service refused, waiting for a person to read
  /// them. A refusal is not a queue row any more — the engine settled it —
  /// so it can only be found in the conflicts table.
  List<ConflictRow> _conflicts = const [];

  @override
  void initState() {
    super.initState();
    // If entries are provided (for testing), use them directly
    if (widget.entries != null) {
      _entries = widget.entries!;
      _loading = false;
    } else if (widget.database != null) {
      _queue = OperationQueue(widget.database!);
      _loadEntries();
      _loadConflicts();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadConflicts() async {
    final db = widget.database;
    if (db == null) {
      return;
    }
    final rows =
        await (db.select(db.conflicts)
              ..where((t) => t.resolvedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
              ..limit(50))
            .get();
    if (mounted) {
      setState(() => _conflicts = rows);
    }
  }

  /// Marks a refusal as read. The row stays in the table for the record —
  /// this is a logbook — but a "needs attention" list that shows the same
  /// refusal forever would stop meaning anything.
  Future<void> _resolveConflict(ConflictRow row) async {
    final db = widget.database;
    if (db == null) {
      return;
    }
    await (db.update(db.conflicts)
          ..where((t) => t.operationId.equals(row.operationId)))
        .write(ConflictsCompanion(resolvedAt: Value(DateTime.now().toUtc())));
    await _loadConflicts();
  }

  Future<void> _loadEntries() async {
    // `pending()` and not `nextBatch()`. `nextBatch` is a send-prep reader: it
    // withholds an inflight row, and it withholds a row whose prerequisite has
    // not settled. Both are correct for the batch it exists to assemble, and
    // both are wrong here — this screen reports what is outstanding, and a
    // record waiting behind a prerequisite that has not sent is still a record
    // waiting. Reading the batch instead hid exactly those rows, which is how
    // this screen could say "everything has been sent" while the map badge
    // beside it counted two.
    final rows = await _queue.pending(limit: 100);
    final entries = rows.map(_toLedgerEntry).toList();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  LedgerEntry _toLedgerEntry(QueuedOperationRow row) {
    final operation = row.toOperation();
    final title = _entityTitle(row.entity);
    final detail = _operationDetail(row, operation);
    final state = _ledgerState(row.state);
    final attemptNote = _attemptNote(row);

    return LedgerEntry(
      title: title,
      detail: detail,
      state: state,
      attemptNote: attemptNote,
    );
  }

  String _entityTitle(EntityKind entity) {
    switch (entity) {
      case EntityKind.sighting:
        return 'Sighting';
      case EntityKind.drive:
        return 'Drive';
      case EntityKind.trailLog:
        return 'Trail log';
      case EntityKind.signOff:
        return 'Sign-off';
      case EntityKind.media:
        return 'Media';
      case EntityKind.outing:
        return 'Outing';
      case EntityKind.dangerousGame:
        return 'Dangerous game';
      case EntityKind.plannedRoute:
        return 'Planned route';
      case EntityKind.routeWaypoint:
        return 'Route waypoint';
      case EntityKind.trailWaypoint:
        return 'Waypoint';
      case EntityKind.unknown:
        return 'Unknown record';
    }
  }

  String _operationDetail(QueuedOperationRow row, PendingOperation? op) {
    final kind = row.kind.name;
    final entityId = row.entityId.substring(0, 8);
    if (op != null) {
      final speciesCode = op.payload['species_code'] as String?;
      if (speciesCode != null && speciesCode.isNotEmpty) {
        return '$kind $entityId… ($speciesCode)';
      }
    }
    return '$kind $entityId…';
  }

  LedgerState _ledgerState(OperationState state) {
    switch (state) {
      case OperationState.pending:
        return LedgerState.queued;
      case OperationState.inflight:
        return LedgerState.deferred;
      case OperationState.settled:
        return LedgerState.applied;
    }
  }

  String? _attemptNote(QueuedOperationRow row) {
    if (row.attempts > 0) {
      return 'Tried ${row.attempts}x${row.settledAt != null ? " — settled" : ""}';
    }
    if (row.errorCode != null && row.errorCode!.isNotEmpty) {
      return 'Error: ${row.errorCode}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;

    if (_loading) {
      return FieldScaffold(
        eyebrow: 'Offline queue',
        title: 'What is waiting to upload',
        body: Center(child: FieldCircularProgress(valueColor: colours.moss)),
      );
    }

    if (_entries.isEmpty && _conflicts.isEmpty) {
      return FieldScaffold(
        eyebrow: 'Offline queue',
        title: 'What is waiting to upload',
        actions: [
          if (widget.onClose != null)
            FieldIconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose!,
              tooltip: 'Close',
            ),
        ],
        body: _EmptyLedger(
          online: widget.online,
          onClose: widget.onClose,
          onSyncNow: widget.onSyncNow,
          lastSyncedAt: widget.lastSyncedAt,
        ),
      );
    }

    return FieldScaffold(
      eyebrow: 'Offline queue',
      title: 'What is waiting to upload',
      actions: [
        if (widget.onClose != null)
          FieldIconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose!,
            tooltip: 'Close',
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          0,
          Insets.lg,
          Insets.xxxl,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.md),
            child: Text(
              widget.online
                  ? 'This queue retries itself. Nothing here needs pressing '
                        'in a moving vehicle.'
                  : 'No signal. Everything below is safe on this phone and '
                        'goes on its own when there is.',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                height: 1.4,
                color: colours.ash3,
              ),
            ),
          ),
          if (_conflicts.isNotEmpty) ...[
            FieldSectionHeader(label: 'Needs attention', uppercase: false),
            ..._conflicts.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: _ConflictRow(
                  row: row,
                  colours: colours,
                  onKeep: () => _resolveConflict(row),
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),
          ],
          if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Insets.xl),
              child: _NothingWaiting(colours: colours),
            )
          else ...[
            FieldSectionHeader(label: 'Waiting to upload', uppercase: false),
            ..._entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: _LedgerRow(entry: entry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A ruled heading inside the ledger's list.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: colours.ash2),
            const SizedBox(width: Insets.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.stamp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colours.ash3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A settled operation the service refused, with its reason and a resolution.
class _ConflictRow extends StatelessWidget {
  const _ConflictRow({
    required this.row,
    required this.colours,
    required this.onKeep,
    super.key,
  });

  final ConflictRow row;
  final FieldColours colours;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: FieldCard(
        elevation: FieldCardElevation.raised,
        borderColor: colours.dust,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sync_problem, size: 16, color: colours.dust),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _entityName(row.entity),
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.label,
                      color: colours.bone,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.reason ?? row.errorCode,
                    style: TextStyle(
                      fontFamily: Faces.book.first,
                      fontSize: Faces.supporting,
                      height: 1.35,
                      color: colours.ash2,
                    ),
                  ),
                ],
              ),
            ),
            FieldGhostButton(label: 'Keep as is', onPressed: onKeep),
          ],
        ),
      ),
    );
  }

  static String _entityName(EntityKind entity) {
    switch (entity) {
      case EntityKind.sighting:
        return 'Sighting';
      case EntityKind.drive:
        return 'Drive';
      case EntityKind.trailLog:
        return 'Trail log';
      case EntityKind.signOff:
        return 'Sign-off';
      case EntityKind.media:
        return 'Media';
      case EntityKind.outing:
        return 'Outing';
      case EntityKind.dangerousGame:
        return 'Dangerous game';
      case EntityKind.plannedRoute:
        return 'Planned route';
      case EntityKind.routeWaypoint:
        return 'Route waypoint';
      case EntityKind.trailWaypoint:
        return 'Waypoint';
      case EntityKind.unknown:
        return 'Unknown record';
    }
  }
}

/// What the empty ledger says when there's no queue but maybe a last sync.
class _NothingWaiting extends StatelessWidget {
  const _NothingWaiting({required this.colours, super.key});

  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.cloud_done_outlined, size: 32, color: colours.moss),
        const SizedBox(height: Insets.md),
        Text(
          'Nothing is waiting',
          style: TextStyle(
            fontFamily: Faces.book.first,
            fontSize: Faces.cardTitle,
            color: colours.bone,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          'Everything recorded has been sent.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.supporting,
            color: colours.ash2,
          ),
        ),
      ],
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger({
    required this.online,
    required this.onClose,
    required this.onSyncNow,
    required this.lastSyncedAt,
    super.key,
  });

  final bool online;
  final VoidCallback? onClose;
  final VoidCallback? onSyncNow;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_done_outlined, size: 32, color: colours.moss),
            const SizedBox(height: Insets.md),
            Text(
              'Nothing is waiting',
              style: TextStyle(
                fontFamily: Faces.book.first,
                fontSize: Faces.cardTitle,
                color: colours.bone,
              ),
            ),
            const SizedBox(height: Insets.sm),
            Text(
              'Everything recorded has been sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                color: colours.ash2,
              ),
            ),
            const SizedBox(height: Insets.sm),
            // An empty queue is exactly where a reader wonders whether
            // anything is being tried at all, so it says so here too.
            Text(
              online
                  ? 'This queue retries itself. Nothing here needs '
                        'pressing in a moving vehicle.'
                  : 'No signal. Anything recorded from here on is safe on '
                        'this phone and goes on its own when there is.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                height: 1.4,
                color: colours.ash3,
              ),
            ),
            if (lastSyncedAt != null) ...[
              const SizedBox(height: Insets.xs),
              Text(
                'Last synced ${_stamp(lastSyncedAt!)}',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.stamp,
                  color: colours.ash3,
                ),
              ),
            ],
            if (onSyncNow != null && online) ...[
              const SizedBox(height: Insets.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 18,
                    color: colours.bone,
                  ),
                  const SizedBox(width: Insets.sm),
                  FieldSecondaryButton(label: 'Sync now', onPressed: onSyncNow),
                ],
              ),
            ],
            if (onClose != null) ...[
              const SizedBox(height: Insets.md),
              FieldGhostButton(label: 'Back to the map', onPressed: onClose!),
            ],
          ],
        ),
      ),
    );
  }

  /// The clock as the local time reads: "14:32".
  static String _stamp(DateTime utc) {
    final local = utc.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, super.key});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    final stamp = entry.state.stampFor(colours);

    return FieldListTile(
      leading: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(color: stamp, shape: BoxShape.circle),
      ),
      title: entry.title,
      subtitle: [
        entry.detail,
        if (entry.attemptNote != null) entry.attemptNote!,
      ].join('\n'),
      trailing: Text(
        entry.state.wired,
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.stamp,
          color: colours.ash3,
        ),
      ),
      onTap: () {},
    );
  }
}

/// One line in the ledger.
class LedgerEntry {
  const LedgerEntry({
    required this.title,
    required this.detail,
    required this.state,
    this.attemptNote,
  });

  /// A sighting, a drive, or a walk. Shown as the app's own word for it, not as
  /// an entity type from the contract.
  final String title;

  final String detail;
  final LedgerState state;

  /// How many times this has been tried, or why it stopped. Only shown when it
  /// tells the reader something they would otherwise wonder about.
  final String? attemptNote;
}

enum LedgerState {
  queued('queued'),
  deferred('waiting'),
  refused('needs a person'),
  applied('sent'),
  held('needs a person');

  const LedgerState(this.wired);

  final String wired;
}

/// Ledger rows carry a stamp, not a coloured word, for the same reason the pins
/// do: an accent is a fill, and a word in an accent hue would fall below a
/// legible contrast against the light surface in midday.
extension LedgerStateStamp on LedgerState {
  Color stampFor(FieldColours colours) => switch (this) {
    LedgerState.queued => colours.ash3,
    LedgerState.deferred => colours.straw,
    LedgerState.refused || LedgerState.held => colours.dust,
    LedgerState.applied => colours.moss,
  };
}
