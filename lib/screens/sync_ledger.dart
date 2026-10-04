import 'package:field_log/design/tokens.dart';
import 'package:field_log/design/theme.dart';
import 'package:flutter/material.dart';

/// What the queue is waiting to do.
///
/// This screen exists to tell the truth about a machine rather than to be a
/// control panel. Nothing here can be pressed to make a queued change send
/// sooner, so nothing here is presented as a button.
class SyncLedgerScreen extends StatelessWidget {
  const SyncLedgerScreen({
    super.key,
    required this.entries,
    required this.online,
    this.onClose,
  });

  final List<LedgerEntry> entries;
  final bool online;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    if (entries.isEmpty) {
      return _EmptyLedger(online: online, onClose: onClose);
    }

    return Scaffold(
      backgroundColor: colours.canopy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.lg,
                Insets.lg,
                Insets.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline queue',
                          style: TextStyle(
                            fontFamily: Faces.ui.first,
                            fontSize: Faces.stamp,
                            color: colours.ash2,
                          ),
                        ),
                        const SizedBox(height: Insets.xs),
                        Text(
                          'What is waiting to upload',
                          style: TextStyle(
                            fontFamily: Faces.book.first,
                            fontSize: Faces.cardTitle,
                            color: colours.bone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(Icons.close, color: colours.ash2),
                      tooltip: 'Close',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                0,
                Insets.lg,
                Insets.md,
              ),
              child: Text(
                online
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
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
                itemBuilder: (context, index) =>
                    _LedgerRow(entry: entries[index]),
              ),
            ),
          ],
        ),
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
    return Scaffold(
      backgroundColor: colours.canopy,
      body: SafeArea(
        child: Center(
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
