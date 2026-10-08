import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:field_log/data/database.dart';
import 'package:field_log/data/drive_writer.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/drive_track.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// The drive logbook: start a drive, watch it run, and close it with what the
/// service needs to accept the record.
///
/// The drive starts before it can be described — a vehicle moving at 05:40 has
/// no duration and no head count yet — so [DriveWriter.startDrive] writes a
/// local row and queues nothing, and this screen carries the live arithmetic
/// in memory until the guide closes the drive with the facts only they know.
/// Every derived number on the closing form is editable, because the session
/// can only measure what its own GPS fixes saw and a mentor reads what is
/// written, not what was intended.
class DriveLogbookScreen extends StatefulWidget {
  const DriveLogbookScreen({
    super.key,
    required this.database,
    required this.writer,
    required this.contextCode,
    this.guideId,
    this.onDriveStarted,
    this.onDriveEnded,
  });

  final FieldLogDatabase database;
  final DriveWriter writer;

  /// The reserve context the row is written into — the same one sync pushes
  /// within.
  final String contextCode;

  /// Who is driving, when somebody is signed in. Absent is honest: a drive
  /// started on an unclaimed device records no guide rather than a guessed one.
  final String? guideId;

  /// Called with the new row's local id so the caller can file captures
  /// against the drive from the first moment it exists.
  final ValueChanged<String>? onDriveStarted;

  /// Called after the drive is saved and queued, so the caller can refresh
  /// the queue badge and offer a sync.
  final VoidCallback? onDriveEnded;

  @override
  State<DriveLogbookScreen> createState() => _DriveLogbookScreenState();
}

class _DriveLogbookScreenState extends State<DriveLogbookScreen> {
  DriveRow? _drive;
  DriveTracker? _tracker;
  bool _loading = true;
  bool _starting = false;
  bool _ending = false;
  bool _saving = false;
  DateTime? _endedAt;

  Timer? _tick;
  StreamSubscription<Position>? _fixes;

  int? _guestCount;
  bool? _oilOk;
  bool? _waterOk;
  bool? _tyresOk;
  bool? _offTrackUsed;

  late final TextEditingController _vehicle;
  late final TextEditingController _duration;
  late final TextEditingController _daylight;
  late final TextEditingController _night;
  late final TextEditingController _offRoadMinutes;
  late final TextEditingController _weather;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _vehicle = TextEditingController();
    _duration = TextEditingController();
    _daylight = TextEditingController();
    _night = TextEditingController();
    _offRoadMinutes = TextEditingController();
    _weather = TextEditingController();
    _notes = TextEditingController();
    // The elapsed clock only matters while a drive is on the screen; the
    // callback guards so a pending timer after the drive closes is a no-op
    // rather than a frame for a panel that is gone.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _drive != null && !_ending) setState(() {});
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _fixes?.cancel();
    _vehicle.dispose();
    _duration.dispose();
    _daylight.dispose();
    _night.dispose();
    _offRoadMinutes.dispose();
    _weather.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Find the drive that is still open, if this device has one.
  ///
  /// Route-planner placeholders carry no status, so they are not open drives
  /// and the status filter leaves them out. The most recent open drive wins:
  /// two open drives is a state the app never writes, and picking one beats
  /// refusing to open the screen at all.
  Future<void> _load() async {
    final rows =
        await (widget.database.select(widget.database.drives)
              ..where((t) => t.isTombstone.equals(false))
              ..where((t) => t.status.isIn(const ['planned', 'active']))
              ..where((t) => t.endedAt.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
            .get();
    if (!mounted) return;
    if (rows.isNotEmpty) {
      _drive = rows.first;
      // A tracker that starts counting from this moment: pauses and distance
      // are what this session observed. Time before the screen was reopened
      // stays in the wall clock and the closing form lets the guide correct
      // the driving time if the app was closed mid-drive.
      _tracker = DriveTracker(startedAt: _drive!.startedAt);
      unawaited(_watchFixes());
    }
    setState(() => _loading = false);
  }

  /// Follow fixes while a drive is open. Distance is a nicety, not a
  /// requirement: no permission and no fix means the drive still runs on its
  /// clock, with the distance line on the closing form saying nothing.
  Future<void> _watchFixes() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _fixes =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((position) {
            _tracker?.addFix(
              position.latitude,
              position.longitude,
              position.timestamp.toUtc(),
            );
            if (mounted && !_ending) setState(() {});
          });
    } on Object catch (error) {
      // A device with no location stack still drives. The clock and the form
      // do not depend on a fix.
      debugPrint('drive position: $error');
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    final vehicle = _vehicle.text.trim();
    final localId = await widget.writer.startDrive(
      contextCode: widget.contextCode,
      startedAt: DateTime.now().toUtc(),
      guideId: widget.guideId,
      vehicleId: vehicle.isEmpty ? null : vehicle,
    );
    widget.onDriveStarted?.call(localId);
    if (!mounted) return;
    await _load();
    // The writer queued nothing: a drive just started has no duration and no
    // head count, and the service refuses a create without them. The row is
    // local until this screen closes the drive with the facts.
    if (mounted) setState(() => _starting = false);
  }

  /// The clock stops here: the closing form works from this instant, and a
  /// later "keep driving" resumes both.
  void _beginEnding() {
    final drive = _drive;
    final tracker = _tracker;
    if (drive == null || tracker == null) return;
    final now = DateTime.now().toUtc();
    tracker.pause(now);
    final drivingHours = tracker.drivingSeconds(now) / 3600;
    final (daylight, night) = splitDayNight(
      drive.startedAt.toLocal(),
      now.toLocal(),
    );
    _endedAt = now;
    _duration.text = _hoursText(drivingHours);
    _daylight.text = _hoursText(daylight);
    _night.text = _hoursText(night);
    setState(() => _ending = true);
  }

  void _keepDriving() {
    final now = DateTime.now().toUtc();
    _tracker?.resume(now);
    _endedAt = null;
    setState(() => _ending = false);
  }

  /// The service needs a head count and a duration before it will take a
  /// drive, so the save is disabled without them and the form says which one
  /// is missing rather than presenting a button that does nothing.
  String? get _cannotSaveReason {
    if (_hoursOf(_duration) == null) {
      return 'The driving time is needed: check the hours above, or write '
          'the hours you drove.';
    }
    if (_guestCount == null) {
      return 'A head count is needed: how many passengers were aboard?';
    }
    return null;
  }

  Future<void> _save() async {
    final drive = _drive;
    final endedAt = _endedAt;
    if (drive == null || endedAt == null) return;
    final reason = _cannotSaveReason;
    if (reason != null || _saving) return;
    setState(() => _saving = true);
    await widget.writer.save(
      drive.localId,
      status: 'completed',
      endedAt: endedAt,
      durationHours: _hoursOf(_duration),
      guestCount: _guestCount,
      inspectionOilOk: _oilOk,
      inspectionWaterOk: _waterOk,
      inspectionTyresOk: _tyresOk,
      daylightHours: _hoursOf(_daylight),
      nightHours: _hoursOf(_night),
      offRoadSeconds: _minutesOf(_offRoadMinutes) == null
          ? null
          : (_minutesOf(_offRoadMinutes)! * 60).round(),
      offTrackUsed: _offTrackUsed,
      weather: _weather.text.trim().isEmpty ? null : _weather.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    widget.onDriveEnded?.call();
    if (mounted) Navigator.of(context).maybePop();
  }

  double? _hoursOf(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  double? _minutesOf(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    if (_loading) {
      return FieldScaffold(
        eyebrow: 'Drive logbook',
        title: 'Opening the log',
        body: Center(child: CircularProgressIndicator(color: colours.moss)),
      );
    }

    final drive = _drive;
    if (drive == null) return _startForm(colours);
    if (_ending) return _closingForm(drive, colours);
    return _runningPanel(drive, colours);
  }

  // ---------------------------------------------------------------- start

  Widget _startForm(FieldColours colours) {
    return FieldScaffold(
      eyebrow: 'Drive logbook',
      title: 'Start a drive',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.md,
          Insets.lg,
          Insets.xxxl,
        ),
        children: [
          _Group(
            label: 'The vehicle',
            hint:
                'The vehicle is remembered for this drive only — a fleet '
                'number or a registration is enough.',
            child: _TextField(
              controller: _vehicle,
              colours: colours,
              hint: 'Registration or fleet number',
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Group(
            label: 'Who is driving',
            child: Text(
              widget.guideId == null
                  ? 'Not signed in. The drive is recorded on this device and '
                        'you can sign in later.'
                  : 'Guide on record: ${widget.guideId}',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                height: 1.4,
                color: widget.guideId == null ? colours.ash3 : colours.bone,
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Supporting(
            'Starting writes the drive to this phone immediately. Distance '
            'and driving time are counted from the moment you start; the '
            'head count and the inspection are collected when you end it.',
            colours,
          ),
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _starting ? null : _start,
            style: FilledButton.styleFrom(
              backgroundColor: colours.bone,
              foregroundColor: colours.canopy,
              disabledBackgroundColor: colours.ash2,
              padding: const EdgeInsets.symmetric(vertical: Insets.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Corners.control),
              ),
            ),
            child: Text(
              _starting ? 'Starting…' : 'Start the drive',
              style: TextStyle(fontFamily: Faces.ui.first),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- running

  Widget _runningPanel(DriveRow drive, FieldColours colours) {
    final tracker = _tracker!;
    final elapsed = tracker.drivingSeconds(DateTime.now().toUtc());
    final distance = tracker.distanceMetres;

    return FieldScaffold(
      eyebrow: 'Drive logbook',
      title: 'On the drive',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.md,
          Insets.lg,
          Insets.xxxl,
        ),
        children: [
          _Measure(
            label: 'Driving time',
            value: _clock(elapsed),
            note:
                'Clock time since the start, less every pause you have '
                'taken.',
            colours: colours,
          ),
          const SizedBox(height: Insets.md),
          _Measure(
            label: 'Distance',
            value: '${(distance / 1000).toStringAsFixed(2)} km',
            note:
                'Straight lines between GPS fixes — less than the odometer '
                'on a winding track, and only as good as the fixes.',
            colours: colours,
          ),
          if (tracker.isPaused) ...[
            const SizedBox(height: Insets.md),
            Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                color: colours.canopyRaised,
                borderRadius: BorderRadius.circular(Corners.control),
                border: Border.all(color: colours.straw),
              ),
              child: Text(
                'Paused at a stop. The clock is not running.',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  color: colours.bone,
                ),
              ),
            ),
          ],
          const SizedBox(height: Insets.lg),
          _Group(
            label: 'This drive',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Started ${_localTime(drive.startedAt)}',
                  style: TextStyle(
                    fontFamily: Faces.book.first,
                    fontSize: Faces.body,
                    color: colours.bone,
                  ),
                ),
                if (drive.vehicleId != null) ...[
                  const SizedBox(height: Insets.xs),
                  Text(
                    'Vehicle ${drive.vehicleId}',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.ash2,
                    ),
                  ),
                ],
                const SizedBox(height: Insets.xs),
                Text(
                  'Sightings tapped on the map are filed against this drive.',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.supporting,
                    color: colours.ash3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          OutlinedButton(
            onPressed: tracker.isPaused ? _keepDriving : _beginEnding,
            style: OutlinedButton.styleFrom(
              foregroundColor: colours.bone,
              side: BorderSide(color: colours.ruleStrong),
              padding: const EdgeInsets.symmetric(vertical: Insets.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Corners.control),
              ),
            ),
            child: Text(
              tracker.isPaused ? 'Resume driving' : 'Pause at this stop',
              style: TextStyle(fontFamily: Faces.ui.first),
            ),
          ),
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _beginEnding,
            style: FilledButton.styleFrom(
              backgroundColor: colours.bone,
              foregroundColor: colours.canopy,
              padding: const EdgeInsets.symmetric(vertical: Insets.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Corners.control),
              ),
            ),
            child: Text(
              'End the drive',
              style: TextStyle(fontFamily: Faces.ui.first),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- closing

  Widget _closingForm(DriveRow drive, FieldColours colours) {
    final reason = _cannotSaveReason;

    return FieldScaffold(
      eyebrow: 'Drive logbook',
      title: 'Close the drive',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.md,
          Insets.lg,
          Insets.xxxl,
        ),
        children: [
          _Group(
            label: 'Who was aboard',
            hint:
                'A head count, not a score. Zero is a real answer — you may '
                'have driven alone.',
            child: _Stepper(
              value: _guestCount,
              colours: colours,
              onChanged: (value) => setState(() => _guestCount = value),
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Group(
            label: 'The hours',
            hint:
                'Filled from the clock. Correct any of them — the number '
                'you write is the number that stands.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NumberField(
                  label: 'Driving time, hours',
                  controller: _duration,
                  colours: colours,
                ),
                const SizedBox(height: Insets.md),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: 'Daylight hours',
                        controller: _daylight,
                        colours: colours,
                      ),
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: _NumberField(
                        label: 'Night hours',
                        controller: _night,
                        colours: colours,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                _Supporting(
                  'Night is 18:00 to 06:00 on the clock. Night hours count '
                  'towards the night qualification and are kept apart from '
                  'daylight hours.',
                  colours,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Group(
            label: 'Before you drove off',
            hint: 'What you checked. Leave a line unset if you did not look.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OkRow(
                  label: 'Oil',
                  value: _oilOk,
                  colours: colours,
                  onChanged: (value) => setState(() => _oilOk = value),
                ),
                const SizedBox(height: Insets.sm),
                _OkRow(
                  label: 'Water',
                  value: _waterOk,
                  colours: colours,
                  onChanged: (value) => setState(() => _waterOk = value),
                ),
                const SizedBox(height: Insets.sm),
                _OkRow(
                  label: 'Tyres',
                  value: _tyresOk,
                  colours: colours,
                  onChanged: (value) => setState(() => _tyresOk = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Group(
            label: 'Off the track',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _YesNo(
                  label: 'Did you leave the track?',
                  value: _offTrackUsed,
                  colours: colours,
                  onChanged: (value) => setState(() => _offTrackUsed = value),
                ),
                const SizedBox(height: Insets.md),
                _NumberField(
                  label: 'Minutes off road',
                  controller: _offRoadMinutes,
                  colours: colours,
                  optional: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Group(
            label: 'Conditions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TextField(
                  controller: _weather,
                  colours: colours,
                  hint: 'Weather — rain, heat, wind',
                ),
                const SizedBox(height: Insets.md),
                _TextField(
                  controller: _notes,
                  colours: colours,
                  hint: 'Anything about the drive worth keeping',
                  lines: 3,
                ),
              ],
            ),
          ),
          if (reason != null) ...[
            const SizedBox(height: Insets.lg),
            _Supporting(reason, colours),
          ],
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _keepDriving,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colours.bone,
                  side: BorderSide(color: colours.ruleStrong),
                  padding: const EdgeInsets.symmetric(vertical: Insets.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Corners.control),
                  ),
                ),
                child: Text(
                  'Keep driving',
                  style: TextStyle(fontFamily: Faces.ui.first),
                ),
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: reason == null ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colours.bone,
                  foregroundColor: colours.canopy,
                  disabledBackgroundColor: colours.ash2,
                  padding: const EdgeInsets.symmetric(vertical: Insets.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Corners.control),
                  ),
                ),
                child: Text(
                  'Save the drive',
                  style: TextStyle(fontFamily: Faces.ui.first),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `h:mm:ss` — a duration the eye can read off at a glance in a moving
  /// vehicle.
  static String _clock(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:'
        '${rest.toString().padLeft(2, '0')}';
  }

  /// Hours as a form value: no trailing zeros, no invented precision.
  static String _hoursText(double hours) {
    if (hours == hours.roundToDouble()) return '${hours.round()}';
    var text = hours.toStringAsFixed(2);
    if (text.endsWith('0')) text = text.substring(0, text.length - 1);
    return text;
  }

  /// A start time as the local clock says it.
  static String _localTime(DateTime utc) {
    final local = utc.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month at $hour:$minute';
  }
}

// ----------------------------------------------------------------- pieces

/// A group of fields under a stamp label, the same shape the field card uses.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child, this.hint});

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.stamp,
            letterSpacing: 0.8,
            color: colours.ash1,
          ),
        ),
        const SizedBox(height: Insets.sm),
        child,
        if (hint != null) ...[
          const SizedBox(height: Insets.sm),
          _Supporting(hint!, colours),
        ],
      ],
    );
  }
}

class _Supporting extends StatelessWidget {
  const _Supporting(this.text, this.colours);

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Faces.ui.first,
        fontSize: Faces.supporting,
        height: 1.4,
        color: colours.ash3,
      ),
    );
  }
}

/// One live measurement: label, value, and what the value is made of.
class _Measure extends StatelessWidget {
  const _Measure({
    required this.label,
    required this.value,
    required this.note,
    required this.colours,
  });

  final String label;
  final String value;
  final String note;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: BorderRadius.circular(Corners.sheet),
        border: Border.all(color: colours.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                    color: colours.ash2,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: Faces.book.first,
                  fontSize: 26,
                  color: colours.bone,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            note,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              height: 1.4,
              color: colours.ash3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.colours,
    this.hint,
    this.lines = 1,
  });

  final TextEditingController controller;
  final FieldColours colours;
  final String? hint;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: lines,
      minLines: lines,
      style: TextStyle(
        fontFamily: Faces.book.first,
        fontSize: Faces.body,
        height: 1.45,
        color: colours.bone,
      ),
      cursorColor: colours.straw,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: Faces.book.first,
          fontSize: Faces.body,
          color: colours.ash3,
        ),
        filled: true,
        fillColor: colours.inset,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.control),
          borderSide: BorderSide(color: colours.rule),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.control),
          borderSide: BorderSide(color: colours.rule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.control),
          borderSide: BorderSide(color: colours.straw),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.colours,
    this.optional = false,
  });

  final String label;
  final TextEditingController controller;
  final FieldColours colours;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.label,
                color: colours.bone,
              ),
            ),
            if (optional)
              Text(
                '  optional',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  color: colours.ash3,
                ),
              ),
          ],
        ),
        const SizedBox(height: Insets.xs),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontFamily: Faces.book.first,
            fontSize: Faces.body,
            color: colours.bone,
          ),
          cursorColor: colours.straw,
          decoration: InputDecoration(
            hintText: '—',
            hintStyle: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.body,
              color: colours.ash3,
            ),
            filled: true,
            fillColor: colours.inset,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.rule),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.rule),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.straw),
            ),
          ),
        ),
      ],
    );
  }
}

/// The head count.
///
/// A stepper rather than a keypad: counting who is aboard is a careful act,
/// and the field starts unset rather than at one, because the app was not
/// there when people got in.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.colours,
    required this.onChanged,
  });

  final int? value;
  final FieldColours colours;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Passengers',
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.label,
            color: colours.bone,
          ),
        ),
        const Spacer(),
        _StepButton(
          icon: Icons.remove,
          onTap: value == null || value! <= 0
              ? null
              : () => onChanged(value! - 1),
        ),
        SizedBox(
          width: 56,
          child: Text(
            value?.toString() ?? '—',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.cardTitle,
              color: value == null ? colours.ash3 : colours.bone,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          // Zero is the first honest answer, not one: the driver may be
          // alone, and starting the count at a passenger who was never in
          // the vehicle would put a person in the record who was not there.
          onTap: () => onChanged(value ?? 0),
        ),
        if (value != null)
          TextButton(
            onPressed: () => onChanged(null),
            child: Text(
              'clear',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                color: colours.ash3,
              ),
            ),
          ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.chip),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Corners.chip),
          border: Border.all(color: colours.ruleStrong),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colours.bone : colours.ash3,
        ),
      ),
    );
  }
}

/// One inspection line: OK, not OK, or unset.
///
/// Two answers and no default. An inspection the guide did not make is
/// recorded as unset rather than as a pass, because a tick the app put there
/// is a check nobody performed.
class _OkRow extends StatelessWidget {
  const _OkRow({
    required this.label,
    required this.value,
    required this.colours,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final FieldColours colours;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.label,
              color: colours.bone,
            ),
          ),
        ),
        _Answer(
          label: 'OK',
          selected: value == true,
          colours: colours,
          onTap: () => onChanged(value == true ? null : true),
        ),
        const SizedBox(width: Insets.sm),
        _Answer(
          label: 'Not OK',
          selected: value == false,
          colours: colours,
          onTap: () => onChanged(value == false ? null : false),
        ),
      ],
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo({
    required this.label,
    required this.value,
    required this.colours,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final FieldColours colours;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.label,
              color: colours.bone,
            ),
          ),
        ),
        _Answer(
          label: 'Yes',
          selected: value == true,
          colours: colours,
          onTap: () => onChanged(value == true ? null : true),
        ),
        const SizedBox(width: Insets.sm),
        _Answer(
          label: 'No',
          selected: value == false,
          colours: colours,
          onTap: () => onChanged(value == false ? null : false),
        ),
      ],
    );
  }
}

/// A fill, never text — the same measured rule the field card's chips follow.
class _Answer extends StatelessWidget {
  const _Answer({
    required this.label,
    required this.selected,
    required this.colours,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final FieldColours colours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? colours.straw : colours.canopyRaised;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Corners.chip),
            border: Border.all(color: selected ? colours.straw : colours.rule),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              color: colours.inkOn(fill),
            ),
          ),
        ),
      ),
    );
  }
}
