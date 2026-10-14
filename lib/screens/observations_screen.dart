import 'package:flutter/material.dart';

import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart' show statusWireName;
import 'package:field_log/design/components.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/screens/pin_detail.dart';

/// The observations logbook answers one question: what did we record, and what
/// happened to it since?
///
/// A record's row is the only truth the list is allowed to tell — a rejection
/// the pins do not draw must still read as Rejected here, and a record that
/// never left the phone must not be allowed to look like one that is waiting to
/// be sent.
class ObservationsScreen extends StatefulWidget {
  const ObservationsScreen({
    super.key,
    this.database,
    this.entries,
    this.onOpen,
    this.onRefresh,
  });

  /// The local replica to read records from. Optional so the screen can also be
  /// driven entirely by [entries], which is how it is tested.
  final FieldLogDatabase? database;

  /// Records to list directly, bypassing the database. When null the records
  /// are read from [database].
  final List<SightingSummary>? entries;

  /// Opens one record. When null the screen pushes its own [PinDetailScreen].
  final void Function(SightingSummary)? onOpen;

  /// Re-reads the records. Called on pull-to-refresh.
  final Future<List<SightingSummary>> Function()? onRefresh;

  @override
  State<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends State<ObservationsScreen> {
  List<SightingSummary>? _entries;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.entries != null) {
      _entries = widget.entries;
      _loading = false;
    } else {
      _read();
    }
  }

  Future<void> _read() async {
    final refresh = widget.onRefresh;
    if (refresh != null) {
      final entries = await refresh();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
      return;
    }

    final database = widget.database;
    if (database == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final rows = await (database.select(
      database.sightings,
    )..where((t) => t.isTombstone.equals(false))).get();
    final entries = [for (final row in rows) _summaryOf(row)]
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  SightingSummary _summaryOf(SightingRow row) {
    return SightingSummary(
      localId: row.localId,
      visual: pinVisualFor(row, commonNameFor: _nameOf),
      commonName: _nameOf(row.speciesCode ?? ''),
      scientificName: '',
      driveId: row.driveId,
      // The service's word for the state, not the Dart identifier.
      status: statusWireName(row.status),
      capturedAt: row.capturedAt,
      recordedAt: row.recordedAt,
      // Zero would claim the position is exact, which an absent reading is not.
      accuracyMetres: row.locationAccuracyM ?? double.infinity,
      distanceMetres: row.distanceM,
      bearingDegrees: row.bearingDeg,
      notes: row.notes ?? '',
      count: row.count,
      speciesCode: row.speciesCode,
      behaviour: row.behaviour,
      ageSexClass: row.ageSexClass,
      recordedSpeciesCode: row.recordedSpeciesCode,
      recordedCount: row.recordedCount,
      correctionReason: row.correctionReason,
      lateArrival: row.lateArrival,
    );
  }

  /// Species names are the reference data's job; without a loader the code is
  /// the honest name rather than an invented one.
  static String _nameOf(String code) => code;

  Future<void> _open(SightingSummary summary) async {
    final open = widget.onOpen;
    if (open != null) {
      open(summary);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PinDetailScreen(sighting: summary),
      ),
    );
    // The record may have been amended or verified; re-read so the row never
    // shows the record the way it was before the reader changed it.
    await _read();
  }

  List<SightingSummary> get _visible {
    final entries = _entries ?? const <SightingSummary>[];
    if (_query.trim().isEmpty) return entries;
    final needle = _query.trim().toLowerCase();
    return [
      for (final entry in entries)
        if (entry.displayName.toLowerCase().contains(needle) ||
            entry.notes.toLowerCase().contains(needle) ||
            (entry.speciesCode ?? '').toLowerCase().contains(needle))
          entry,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visible;
    return FieldScaffold(
      title: 'Observations',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: FieldFormField(
              hint: 'Search records',
              prefix: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: FieldCircularProgress())
                : entries.isEmpty
                ? _nothingYet()
                : RefreshIndicator(
                    onRefresh: _read,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md,
                      ),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Insets.sm),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return FieldListTile(
                          key: ValueKey(entry.localId),
                          leading: _Glyph(visual: entry.visual),
                          title: entry.displayName,
                          subtitle: '${_stateWord(entry)} · ${_when(entry)}',
                          onTap: () => _open(entry),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _nothingYet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              color: context.reserve.ash3,
              size: 32,
            ),
            const SizedBox(height: Insets.sm),
            Text(
              'Nothing recorded yet',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                color: context.reserve.ash2,
              ),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              'Everything you record on the map is listed here, and what '
              'became of it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.reserve.ash3),
            ),
          ],
        ),
      ),
    );
  }

  /// The state as a word, never as a bare enum name.
  String _stateWord(SightingSummary entry) {
    switch (entry.visual.state) {
      case PinState.queued:
        return 'Waiting to send';
      case PinState.verified:
        return 'Verified';
      case PinState.corrected:
        return 'Corrected';
      case PinState.needsReview:
        return 'Needs review';
      case PinState.deleted:
        return 'Deleted';
      case PinState.ghost:
        return 'Draft';
      case PinState.unverified:
        return 'Not yet sent';
    }
  }

  String _when(SightingSummary entry) {
    final at = entry.capturedAt.toLocal();
    final day = at.day.toString().padLeft(2, '0');
    final month = at.month.toString().padLeft(2, '0');
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
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
