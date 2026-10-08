import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:field_log/data/database.dart';
import 'package:field_log/data/trail_log_writer.dart';
import 'package:field_log/data/encounter_writer.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/card_state.dart';
import 'package:field_log/field/field_card_screen.dart';
import 'package:field_log/screens/logbook_form.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// The trail logbook: start a walk, drop waypoints, record encounters,
/// close it.
///
/// Mirrors [DriveLogbookScreen] for the second capture mode. The walk
/// starts before it can be described — a route planned at 05:40 has no
/// waypoints and no hours walked yet — so [TrailLogWriter.startLog]
/// writes a local row and queues nothing, and this screen carries the
/// live arithmetic in memory until the guide closes the walk.
///
/// Waypoints and encounters are never edited or deleted by design: the
/// sequence of observations is itself the record.
class TrailLogbookScreen extends StatefulWidget {
  const TrailLogbookScreen({
    super.key,
    required this.database,
    required this.writer,
    required this.encounters,
    required this.contextCode,
    this.driveId = '',
    this.guideId,
    this.species = const [],
    this.recentSpecies = const [],
    this.onSpeciesUsed,
    this.onTrailStarted,
    this.onTrailEnded,
  });

  final FieldLogDatabase database;
  final TrailLogWriter writer;
  final EncounterWriter encounters;
  final String contextCode;
  final String driveId;
  final String? guideId;
  final List<SpeciesChoice> species;
  final List<SpeciesChoice> recentSpecies;
  final void Function(SpeciesChoice choice)? onSpeciesUsed;
  final void Function(String localId)? onTrailStarted;
  final VoidCallback? onTrailEnded;

  @override
  State<TrailLogbookScreen> createState() => _TrailLogbookScreenState();
}

enum _TrailView { start, walking, encounter, closing }

class _TrailLogbookScreenState extends State<TrailLogbookScreen> {
  _TrailView _view = _TrailView.start;

  // ---- start form ----
  final _trailName = TextEditingController();
  String? _rifleRole;
  final _walkLengthKm = TextEditingController();
  String? _guideRole;
  final _rifleDetails = TextEditingController();

  // ---- walking panel ----
  final _weather = TextEditingController();

  // ---- encounter ----
  final _distanceKm = TextEditingController();
  final _animalBehaviour = TextEditingController();
  final _actionTaken = TextEditingController();
  final _encounterNote = TextEditingController();
  SpeciesChoice? _encounterSpecies;

  // ---- closing ----
  final _hoursWalked = TextEditingController();
  final _description = TextEditingController();
  final _lessonsLearned = TextEditingController();

  TrailLogRow? _log;
  List<DangerousGameEncounterRow> _encounterLog = const [];
  Position? _position;
  StreamSubscription<Position>? _fixes;

  @override
  void initState() {
    super.initState();
    _watchFixes();
  }

  @override
  void dispose() {
    _fixes?.cancel();
    _trailName.dispose();
    _walkLengthKm.dispose();
    _rifleDetails.dispose();
    _weather.dispose();
    _distanceKm.dispose();
    _animalBehaviour.dispose();
    _actionTaken.dispose();
    _encounterNote.dispose();
    _hoursWalked.dispose();
    _description.dispose();
    _lessonsLearned.dispose();
    super.dispose();
  }

  void _watchFixes() {
    _fixes =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((p) {
          if (!mounted) return;
          setState(() => _position = p);
        }, onError: (_) {});
  }

  /// A position fix is currently available.
  bool get _hasFix => _position != null;

  double? _parseWalkKm(String text) {
    final cleaned = text.replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  /// Reasons the start button must stay disabled. Last shown so the
  /// guide knows what to fix.
  String? _startGate() {
    final name = _trailName.text.trim();
    if (name.isEmpty) return 'A trail name is needed…';
    if (_rifleRole == null) return 'Which rifle is carried?';
    final km = _parseWalkKm(_walkLengthKm.text);
    if (km == null || km <= 0) {
      return 'The walk length is needed — write them like 4.2 km.';
    }
    return null;
  }

  Future<void> _start() async {
    final id = await widget.writer.startLog(
      driveId: widget.driveId,
      contextCode: widget.contextCode,
      trailCode: _trailName.text.trim(),
      startedAt: DateTime.now().toUtc(),
      rifleRole: _rifleRole!,
      walkLengthKm: _parseWalkKm(_walkLengthKm.text)!,
    );
    _log = await (widget.database.select(
      widget.database.trailLogs,
    )..where((t) => t.localId.equals(id))).getSingle();
    setState(() => _view = _TrailView.walking);
    widget.onTrailStarted?.call(id);
  }

  String? _encounterGate() {
    if (_encounterSpecies == null) return 'Which species was seen?';
    if (!_hasFix) {
      return 'A position fix is needed — step away from the tree first.';
    }
    return null;
  }

  Future<void> _saveEncounter() async {
    final pos = _position!;
    await widget.encounters.record(
      contextCode: widget.contextCode,
      outingId: _log!.localId,
      speciesCode: _encounterSpecies!.code,
      latitude: pos.latitude,
      longitude: pos.longitude,
      capturedAt: DateTime.now().toUtc(),
      distanceM: _distanceKm.text.trim().isEmpty
          ? null
          : (double.tryParse(_distanceKm.text.replaceAll(',', '.')) ?? 0) *
                1000,
      animalBehaviour: _animalBehaviour.text.trim().isEmpty
          ? null
          : _animalBehaviour.text.trim(),
      actionTaken: _actionTaken.text.trim().isEmpty
          ? null
          : _actionTaken.text.trim(),
      accuracyM: pos.accuracy == 0 ? null : pos.accuracy,
      note: _encounterNote.text.trim().isEmpty
          ? null
          : _encounterNote.text.trim(),
      createdBy: widget.guideId,
    );
    final used = _encounterSpecies!;
    _encounterSpecies = null;
    _distanceKm.clear();
    _animalBehaviour.clear();
    _actionTaken.clear();
    _encounterNote.clear();
    setState(() {});
    // Reload the encounter log so the list reflects the new record.
    _reloadEncounters();
    widget.onSpeciesUsed?.call(used);
  }

  Future<void> _reloadEncounters() async {
    final rows =
        await (widget.database.select(widget.database.dangerousGameEncounters)
              ..where((t) => t.outingId.equals(_log!.localId))
              ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
            .get();
    if (!mounted) return;
    setState(() => _encounterLog = rows);
  }

  String? _closingGate() {
    final text = _hoursWalked.text.trim();
    if (text.isEmpty) return null;
    if (double.tryParse(text.replaceAll(',', '.')) == null) {
      return 'Hours walked must be a number — write them like 4.5.';
    }
    return null;
  }

  Future<void> _close() async {
    final hours = _hoursWalked.text.trim().isEmpty
        ? null
        : double.parse(_hoursWalked.text.replaceAll(',', '.'));
    await widget.writer.save(
      _log!.localId,
      status: 'completed',
      endedAt: DateTime.now().toUtc(),
      hoursWalked: hours,
      weather: _weather.text.trim().isEmpty ? null : _weather.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      lessonsLearned: _lessonsLearned.text.trim().isEmpty
          ? null
          : _lessonsLearned.text.trim(),
      guideRole: _guideRole,
      rifleDetails: _rifleDetails.text.trim().isEmpty
          ? null
          : _rifleDetails.text.trim(),
    );
    widget.onTrailEnded?.call();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colours = FieldColours.dark;
    final text = Theme.of(context).textTheme;
    return FieldScaffold(
      eyebrow: 'Trail',
      title: _view == _TrailView.start
          ? 'Start a trail'
          : _view == _TrailView.walking
          ? 'On the trail'
          : _view == _TrailView.closing
          ? 'Close the trail'
          : 'Record an encounter',
      body: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          if (_view == _TrailView.start)
            _startForm(colours: colours, text: text),
          if (_view == _TrailView.walking)
            _walkingPanel(colours: colours, text: text),
          if (_view == _TrailView.encounter)
            _encounterForm(colours: colours, text: text),
          if (_view == _TrailView.closing)
            _closingForm(colours: colours, text: text),
        ],
      ),
    );
  }

  Widget _startForm({required FieldColours colours, required TextTheme text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogGroup(
          label: 'Trail name',
          child: LogTextField(
            controller: _trailName,
            colours: colours,
            hint: 'e.g. Ridge traverse',
          ),
        ),
        LogGroup(
          label: 'Rifle role',
          child: LogChoices(
            label: 'Rifle role',
            options: const [
              ('first', 'First rifle'),
              ('second', 'Second rifle'),
              ('neither', 'No rifle'),
            ],
            selected: _rifleRole,
            colours: colours,
            onChanged: (v) => setState(() => _rifleRole = v),
          ),
        ),
        LogGroup(
          label: 'Walk length (km)',
          child: LogNumberField(
            label: 'km',
            controller: _walkLengthKm,
            colours: colours,
          ),
        ),
        LogGroup(
          label: 'Guide role',
          child: LogChoices(
            label: 'Guide role',
            options: const [('lead', 'Lead'), ('backup', 'Backup')],
            selected: _guideRole,
            colours: colours,
            onChanged: (v) => setState(() => _guideRole = v),
            hint: 'Optional',
          ),
        ),
        LogGroup(
          label: 'Rifle details',
          child: LogTextField(
            controller: _rifleDetails,
            colours: colours,
            hint: 'Optional — calibre, model',
          ),
        ),
        const SizedBox(height: Insets.md),
        FilledButton(
          onPressed: _startGate() != null ? null : _start,
          style: FilledButton.styleFrom(
            backgroundColor: colours.bone,
            foregroundColor: colours.canopy,
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.control),
            ),
          ),
          child: const Text('Start the trail'),
        ),
      ],
    );
  }

  Widget _walkingPanel({
    required FieldColours colours,
    required TextTheme text,
  }) {
    final log = _log;
    final waypointCount = log == null ? 0 : null; // async — will reload
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogGroup(
          label: 'Waypoints',
          child: LogMeasure(
            label: 'recorded',
            value: log == null ? '—' : '${waypointCount ?? 0}',
            note: 'pending upload',
            colours: colours,
          ),
        ),
        LogGroup(
          label: 'Elevation',
          child: LogMeasure(
            label: _hasFix ? '±${_position!.accuracy.round()} m' : 'no fix',
            value: _position == null
                ? '—'
                : (_position!.altitude == 0.0
                      ? 'no altitude'
                      : '${_position!.altitude.round()} m'),
            note: 'GPS',
            colours: colours,
          ),
        ),
        LogGroup(
          label: 'Weather',
          child: LogTextField(
            controller: _weather,
            colours: colours,
            hint: 'e.g. clearing',
          ),
        ),
        const SizedBox(height: Insets.sm),
        OutlinedButton(
          onPressed: !_hasFix
              ? () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Waiting for a position fix')),
                  );
                }
              : () async {
                  await widget.writer.appendWaypoint(
                    trailLogId: log!.localId,
                    latitude: _position!.latitude,
                    longitude: _position!.longitude,
                    recordedAt: DateTime.now().toUtc(),
                    accuracyMetres: _position!.accuracy == 0
                        ? null
                        : _position!.accuracy,
                    elevationM: _position!.altitude == 0.0
                        ? null
                        : _position!.altitude,
                  );
                  setState(() {});
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: colours.bone,
            side: BorderSide(color: colours.ruleStrong),
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
          ),
          child: const Text('Drop a waypoint'),
        ),
        const SizedBox(height: Insets.sm),
        FilledButton(
          onPressed: () => setState(() => _view = _TrailView.encounter),
          style: FilledButton.styleFrom(
            backgroundColor: colours.bone,
            foregroundColor: colours.canopy,
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.control),
            ),
          ),
          child: const Text('Record an encounter'),
        ),
        if (log != null) ...[
          const SizedBox(height: Insets.md),
          Text(
            'Encounters recorded: ${_encounterLog.length}',
            style: text.bodyMedium?.copyWith(color: colours.bone),
          ),
          const SizedBox(height: Insets.sm),
          ..._encounterLog.map(
            (e) => LogMeasure(
              label: e.speciesCode,
              value: '${(e.distanceM ?? 0).round()} m',
              note: '',
              colours: colours,
            ),
          ),
        ],
        const SizedBox(height: Insets.md),
        FilledButton(
          onPressed: () => setState(() => _view = _TrailView.closing),
          style: FilledButton.styleFrom(
            backgroundColor: colours.bone,
            foregroundColor: colours.canopy,
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.control),
            ),
          ),
          child: const Text('End the walk'),
        ),
      ],
    );
  }

  Widget _encounterForm({
    required FieldColours colours,
    required TextTheme text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpeciesField(
          choice: _encounterSpecies,
          colours: colours,
          options: widget.species,
          recent: widget.recentSpecies,
          onPick: (choice) => setState(() => _encounterSpecies = choice),
        ),
        LogGroup(
          label: 'Position',
          child: LogMeasure(
            label: _hasFix
                ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)} ±${_position!.accuracy.round()} m'
                : 'no fix',
            value: _position == null ? '—' : 'GPS',
            note: '',
            colours: colours,
          ),
        ),
        LogGroup(
          label: 'Distance (km)',
          child: LogNumberField(
            label: 'km',
            controller: _distanceKm,
            colours: colours,
            optional: true,
          ),
        ),
        LogGroup(
          label: 'Animal behaviour',
          child: LogTextField(
            controller: _animalBehaviour,
            colours: colours,
            hint: 'Optional',
            lines: 2,
          ),
        ),
        LogGroup(
          label: 'Action taken',
          child: LogTextField(
            controller: _actionTaken,
            colours: colours,
            hint: 'Optional',
            lines: 2,
          ),
        ),
        LogGroup(
          label: 'Note',
          child: LogTextField(
            controller: _encounterNote,
            colours: colours,
            hint: 'Optional',
            lines: 2,
          ),
        ),
        const SizedBox(height: Insets.md),
        FilledButton(
          onPressed: _encounterGate() != null ? null : _saveEncounter,
          style: FilledButton.styleFrom(
            backgroundColor: colours.bone,
            foregroundColor: colours.canopy,
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.control),
            ),
          ),
          child: const Text('Save the sighting'),
        ),
        const SizedBox(height: Insets.sm),
        OutlinedButton(
          onPressed: () => setState(() => _view = _TrailView.walking),
          style: OutlinedButton.styleFrom(
            foregroundColor: colours.bone,
            side: BorderSide(color: colours.ruleStrong),
          ),
          child: const Text('Back to walking'),
        ),
      ],
    );
  }

  Widget _closingForm({
    required FieldColours colours,
    required TextTheme text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogGroup(
          label: 'Hours walked',
          child: LogTextField(
            controller: _hoursWalked,
            colours: colours,
            hint: 'Prefilled from start time',
          ),
        ),
        LogGroup(
          label: 'Weather',
          child: LogTextField(
            controller: _weather,
            colours: colours,
            hint: 'e.g. clearing',
          ),
        ),
        LogGroup(
          label: 'Description',
          child: LogTextField(
            controller: _description,
            colours: colours,
            hint: 'Optional',
            lines: 2,
          ),
        ),
        LogGroup(
          label: 'Lessons learned',
          child: LogTextField(
            controller: _lessonsLearned,
            colours: colours,
            hint: 'Optional',
            lines: 2,
          ),
        ),
        LogGroup(
          label: 'Guide role',
          child: LogChoices(
            label: 'Guide role',
            options: const [('lead', 'Lead'), ('backup', 'Backup')],
            selected: _guideRole,
            colours: colours,
            onChanged: (v) => setState(() => _guideRole = v),
            hint: 'Optional',
          ),
        ),
        LogGroup(
          label: 'Rifle details',
          child: LogTextField(
            controller: _rifleDetails,
            colours: colours,
            hint: 'Optional — calibre, model',
          ),
        ),
        const SizedBox(height: Insets.sm),
        LogSupporting(_closingGate() ?? '', colours),
        const SizedBox(height: Insets.sm),
        FilledButton(
          onPressed: _closingGate() != null ? null : _close,
          style: FilledButton.styleFrom(
            backgroundColor: colours.bone,
            foregroundColor: colours.canopy,
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.control),
            ),
          ),
          child: const Text('Save the trail'),
        ),
        const SizedBox(height: Insets.sm),
        OutlinedButton(
          onPressed: () => setState(() => _view = _TrailView.walking),
          style: OutlinedButton.styleFrom(
            foregroundColor: colours.bone,
            side: BorderSide(color: colours.ruleStrong),
          ),
          child: const Text('Keep walking'),
        ),
      ],
    );
  }
}
