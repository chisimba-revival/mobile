import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/tables.dart' show OperationState;
import 'package:field_log/models/sync_operation.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/design/theme.dart';
import 'package:flutter/material.dart';

/// What the queue is waiting to do.
///
/// This screen exists to tell the truth about a machine rather than to be a
/// control panel. Nothing here can be pressed to make a queued change send
/// sooner, so nothing here is presented as a button.
class SyncLedgerScreen extends StatefulWidget {
  const SyncLedgerScreen({
    super.key,
    this.database,
    this.entries,
    required this.online,
    this.onClose,
  });

  final FieldLogDatabase? database;
  final List<LedgerEntry>? entries;
  final bool online;
  final VoidCallback? onClose;

  @override
  State<SyncLedgerScreen> createState() => _SyncLedgerScreenState();
}

class _SyncLedgerScreenState extends State<SyncLedgerScreen> {
  late final OperationQueue _queue;
  List<LedgerEntry> _entries = const [];
  bool _loading = true;

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
    } else {
      _loading = false;
    }
  }

  Future<void> _loadEntries() async {
    final rows = await _queue.nextBatch(limit: 100);
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
    final colours = context.reserve;

    if (_loading) {
      return FieldScaffold(
        eyebrow: 'Offline queue',
        title: 'What is waiting to upload',
        body: Center(child: CircularProgressIndicator(color: colours.moss)),
      );
    }

    if (_entries.isEmpty) {
      return FieldScaffold(
        eyebrow: 'Offline queue',
        title: 'What is waiting to upload',
        body: _EmptyLedger(online: widget.online, onClose: widget.onClose),
      );
    }

    return FieldScaffold(
      eyebrow: 'Offline queue',
      title: 'What is waiting to upload',
      actions: [
        if (widget.onClose != null)
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close, color: colours.ash2),
            tooltip: 'Close',
          ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              0,
              Insets.lg,
              Insets.md,
            ),
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
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                0,
                Insets.lg,
                Insets.xxxl,
              ),
              itemCount: _entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
              itemBuilder: (context, index) =>
                  _LedgerRow(entry: _entries[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger({required this.online, required this.onClose});

  final bool online;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    // No Scaffold of its own: the caller wraps this in a FieldScaffold so
    // every state of the queue — empty or full — has the same back arrow.
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
            if (onClose != null) ...[
              const SizedBox(height: Insets.xl),
              TextButton(
                onPressed: onClose,
                child: Text(
                  'Back to the map',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                    color: colours.bone,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final stamp = entry.state.stampFor(colours);

    return Semantics(
      label: '${entry.title}. ${entry.detail}. ${entry.state.wired}',
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colours.canopyRaised,
          borderRadius: BorderRadius.circular(Corners.control),
          border: Border.all(color: colours.rule),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(color: stamp, shape: BoxShape.circle),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.label,
                      color: colours.bone,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.detail,
                    style: TextStyle(
                      fontFamily: Faces.book.first,
                      fontSize: Faces.supporting,
                      height: 1.35,
                      color: colours.ash2,
                    ),
                  ),
                  if (entry.attemptNote != null) ...[
                    const SizedBox(height: Insets.xs),
                    Text(
                      entry.attemptNote!,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.stamp,
                        color: colours.ash3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Insets.sm),
            Text(
              entry.state.wired,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                color: colours.ash3,
              ),
            ),
          ],
        ),
      ),
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
