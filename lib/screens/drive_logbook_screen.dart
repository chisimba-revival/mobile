import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:field_log/data/database.dart';
import 'package:field_log/data/drive_writer.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/drive_track.dart';
import 'package:field_log/screens/logbook_form.dart';
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
          LogGroup(
            label: 'The vehicle',
            hint:
                'The vehicle is remembered for this drive only — a fleet '
                'number or a registration is enough.',
            child: LogTextField(
              controller: _vehicle,
              colours: colours,
              hint: 'Registration or fleet number',
            ),
          ),
          const SizedBox(height: Insets.lg),
          LogGroup(
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
          LogSupporting(
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
          LogMeasure(
            label: 'Driving time',
            value: _clock(elapsed),
            note:
                'Clock time since the start, less every pause you have '
                'taken.',
            colours: colours,
          ),
          const SizedBox(height: Insets.md),
          LogMeasure(
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
          LogGroup(
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
          LogGroup(
            label: 'Who was aboard',
            hint:
                'A head count, not a score. Zero is a real answer — you may '
                'have driven alone.',
            child: LogStepper(
              value: _guestCount,
              colours: colours,
              onChanged: (value) => setState(() => _guestCount = value),
            ),
          ),
          const SizedBox(height: Insets.lg),
          LogGroup(
            label: 'The hours',
            hint:
                'Filled from the clock. Correct any of them — the number '
                'you write is the number that stands.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LogNumberField(
                  label: 'Driving time, hours',
                  controller: _duration,
                  colours: colours,
                ),
                const SizedBox(height: Insets.md),
                Row(
                  children: [
                    Expanded(
                      child: LogNumberField(
                        label: 'Daylight hours',
                        controller: _daylight,
                        colours: colours,
                      ),
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: LogNumberField(
                        label: 'Night hours',
                        controller: _night,
                        colours: colours,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                LogSupporting(
                  'Night is 18:00 to 06:00 on the clock. Night hours count '
                  'towards the night qualification and are kept apart from '
                  'daylight hours.',
                  colours,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          LogGroup(
            label: 'Before you drove off',
            hint: 'What you checked. Leave a line unset if you did not look.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LogOkRow(
                  label: 'Oil',
                  value: _oilOk,
                  colours: colours,
                  onChanged: (value) => setState(() => _oilOk = value),
                ),
                const SizedBox(height: Insets.sm),
                LogOkRow(
                  label: 'Water',
                  value: _waterOk,
                  colours: colours,
                  onChanged: (value) => setState(() => _waterOk = value),
                ),
                const SizedBox(height: Insets.sm),
                LogOkRow(
                  label: 'Tyres',
                  value: _tyresOk,
                  colours: colours,
                  onChanged: (value) => setState(() => _tyresOk = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          LogGroup(
            label: 'Off the track',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LogYesNo(
                  label: 'Did you leave the track?',
                  value: _offTrackUsed,
                  colours: colours,
                  onChanged: (value) => setState(() => _offTrackUsed = value),
                ),
                const SizedBox(height: Insets.md),
                LogNumberField(
                  label: 'Minutes off road',
                  controller: _offRoadMinutes,
                  colours: colours,
                  optional: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          LogGroup(
            label: 'Conditions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LogTextField(
                  controller: _weather,
                  colours: colours,
                  hint: 'Weather — rain, heat, wind',
                ),
                const SizedBox(height: Insets.md),
                LogTextField(
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
            LogSupporting(reason, colours),
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
