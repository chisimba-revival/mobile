import 'package:field_log/data/database.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:field_log/progress/progress_loader.dart';
import 'package:field_log/progress/progress_summary.dart';
import 'package:flutter/material.dart';

// `HoursCount`, `Requirement` and `TrailProgress` live in the shared module so
// the map's progress card and this screen read the same values. The export
// keeps them reachable through this library for the tests that import it.
export 'package:field_log/progress/progress_summary.dart';

/// Hours walked, and what the trail still asks for.
///
/// Contract rule 20: nothing here is presented as a score. There are no points,
/// no bars and no percentages, because a trainee reading "73 per cent" learns
/// that they are being graded rather than that there is an animal they have not
/// yet found. What is shown instead is the requirement and how far along it is,
/// which is the same information without the verdict attached.
class TallyScreen extends StatefulWidget {
  const TallyScreen({
    super.key,
    this.database,
    this.progress,
    this.onLoadCompetencies,
    this.onEditTrail,
    this.onEditDrive,
  });

  final FieldLogDatabase? database;
  final TrailProgress? progress;

  /// Where the requirements on screen come from. A screen given only a
  /// database would have to know about the account, and it does not.
  final Future<List<Competency>> Function()? onLoadCompetencies;

  /// Reopens one walk to correct what was recorded against it. The id names
  /// the walk, so the walk's own row is the one that opens it: a lifetime
  /// total is not a thing anybody can correct.
  final Future<void> Function(String localId)? onEditTrail;

  /// Reopens an existing drive's closing form with its own values in place, so
  /// the correction is made on the record that made it.
  final Future<void> Function(String localId)? onEditDrive;

  @override
  State<TallyScreen> createState() => _TallyScreenState();
}

class _TallyScreenState extends State<TallyScreen> {
  OutingProgress? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.progress != null) {
      _progress = OutingProgress(trail: widget.progress);
      _loading = false;
    } else if (widget.database != null) {
      _loadProgress();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadProgress() async {
    if (widget.database == null) return;

    final competencies =
        await widget.onLoadCompetencies?.call() ?? <Competency>[];
    // Both halves, not just the walk. A drive is a record like any other, and
    // a progress screen that silently ignores the half of the day behind the
    // wheel is not the trainee's progress.
    final progress = await ProgressLoader(widget.database!)
        .load(competencies: competencies);

    if (mounted) {
      setState(() {
        _progress = progress;
        _loading = false;
      });
    }
  }

  /// The last drive's own facts, in the order the logbook asked for them.
  ///
  /// The hours are absent on purpose: every drive carries its own hours beside
  /// its own way to be corrected, so repeating them here would put the same
  /// number on screen three times over without adding a way to act on it.
  ///
  /// A total on its own is not the record: four guests, a vehicle and two of
  /// the three inspections are what actually happened. Rows are dropped rather
  /// than faked when a field was never filled in, so an empty row is never
  /// mistaken for a zero.
  static List<(String, String)> _driveDetails(DriveProgress drive) {
    final rows = <(String, String)>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) rows.add((label, value));
    }

    final daylight = drive.daylightHours;
    if (daylight != null) add('In daylight', formatHours(daylight));
    final night = drive.nightHours;
    if (night != null) add('At night', formatHours(night));
    final offRoad = drive.offRoadSeconds;
    if (offRoad != null && offRoad > 0) {
      add('Off-road', '${(offRoad / 60).round()} min');
    }
    final guests = drive.guestCount;
    if (guests != null) add('Guests', '$guests');
    final vehicle = drive.vehicleId;
    if (vehicle != null && vehicle.isNotEmpty) add('Vehicle', vehicle);

    final inspections = <String>[
      if (drive.inspectionOilOk != null)
        'Oil ${drive.inspectionOilOk! ? 'ok' : 'no'}',
      if (drive.inspectionWaterOk != null)
        'Water ${drive.inspectionWaterOk! ? 'ok' : 'no'}',
      if (drive.inspectionTyresOk != null)
        'Tyres ${drive.inspectionTyresOk! ? 'ok' : 'no'}',
    ];
    if (inspections.isNotEmpty) {
      add('Inspections', inspections.join(' · '));
    }
    if (drive.offTrackUsed == true) add('Off-track', 'Used');
    if (drive.weather.isNotEmpty) add('Weather', drive.weather);
    if (drive.notes.isNotEmpty) add('Notes', drive.notes);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    if (_loading) {
      return FieldScaffold(
        eyebrow: 'Your trail',
        title: 'Where you are',
        body: Center(child: CircularProgressIndicator(color: colours.moss)),
      );
    }

    final progress = _progress ?? OutingProgress.empty;
    final trail = progress.trail ?? TrailProgress.empty;
    final drive = progress.drive ?? DriveProgress.empty;
    final nothingYet =
        trail.totalHours == 0 && drive.totalHours == 0 && trail.hours.isEmpty;

    return FieldScaffold(
      eyebrow: 'Your trail',
      title: 'Where you are',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.sm,
          Insets.lg,
          Insets.xxxl,
        ),
        children: [
          const SizedBox(height: Insets.xl),
          if (nothingYet) ...[
            Container(
              padding: const EdgeInsets.all(Insets.lg),
              decoration: BoxDecoration(
                color: colours.canopyRaised,
                borderRadius: BorderRadius.circular(Corners.sheet),
                border: Border.all(color: colours.rule),
              ),
              child: Text(
                'No hours yet. Walk a trail or drive a vehicle and the hours '
                'that count towards your sign-off will appear here.',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.label,
                  height: 1.4,
                  color: colours.ash2,
                ),
              ),
            ),
            const SizedBox(height: Insets.md),
          ],
          if (trail.entries.isNotEmpty || trail.hours.isNotEmpty) ...[
            _SectionTitle('Trail', colours),
            const SizedBox(height: Insets.sm),
            for (final hours in trail.hours) ...[
              _HoursBlock(hours: hours),
              const SizedBox(height: Insets.md),
            ],
            // One row per walk, each carrying its own way back to the record
            // it came from. A lifetime total is not something a person can
            // correct; the walk behind it is.
            for (final entry in trail.entries) ...[
              _EntryRow(
                colours: colours,
                value: formatHours(entry.hours),
                label: _roleLabel(entry.rifleRole),
                detail: _walkDetail(entry),
                editLabel:
                    'Correct the walk from ${_entryDate(entry.startedAt)}',
                onEdit: widget.onEditTrail == null
                    ? null
                    : () => widget.onEditTrail!(entry.localId),
              ),
              const SizedBox(height: Insets.sm),
            ],
            if (trail.hoursReconciled)
              _Note(
                'Waypoint times and the hours entered disagree for one of '
                'these walks — check it before submitting.',
                colours,
              ),
            const SizedBox(height: Insets.lg),
          ],
          if (drive.entries.isNotEmpty || drive.count > 0) ...[
            _SectionTitle('Drive', colours),
            const SizedBox(height: Insets.sm),
            _HoursBlock(
              hours: HoursCount(
                role: 'drive',
                label: 'Hours behind the wheel',
                note:
                    '${drive.count} drive${drive.count == 1 ? '' : 's'} '
                    'on this device',
                value: drive.totalHours,
              ),
            ),
            const SizedBox(height: Insets.md),
            // One row per drive, each with its own way back to the record.
            for (final entry in drive.entries) ...[
              _EntryRow(
                colours: colours,
                value: entry.durationHours == null
                    ? 'not closed yet'
                    : formatHours(entry.durationHours!),
                placeholder: entry.durationHours == null,
                label: 'Drive',
                detail: _entryDate(entry.startedAt),
                editLabel:
                    'Correct the drive from ${_entryDate(entry.startedAt)}',
                onEdit: widget.onEditDrive == null
                    ? null
                    : () => widget.onEditDrive!(entry.localId),
              ),
              const SizedBox(height: Insets.sm),
            ],
            for (final row in _driveDetails(drive)) ...[
              _DetailRow(row: row, colours: colours),
            ],
            const SizedBox(height: Insets.lg),
          ],
          _Requirements(progress: trail),
          const SizedBox(height: Insets.md),
          Text(
            'These are the requirements your mentor will use. Your mentor '
            'decides whether you are ready — the list is not a verdict, and '
            'nothing here stops you submitting a walk.',
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              height: 1.5,
              color: colours.ash3,
            ),
          ),
        ],
      ),
    );
  }

  /// The named role a walk carried, in the words the logbook offers them in.
  static String _roleLabel(String role) {
    switch (role) {
      case 'first':
        return 'First rifle';
      case 'second':
        return 'Second rifle';
      default:
        return 'No rifle';
    }
  }

  /// Where a walk's hours came from, and whether the two figures differ.
  ///
  /// A measured figure and a typed one are not the same claim, so the row says
  /// which one it is showing. Where both exist and disagree, the row says so
  /// against the walk that disagrees rather than against every walk at once.
  static String _walkDetail(TrailEntry entry) {
    final date = _entryDate(entry.startedAt);
    final measured = entry.fromWaypoints
        ? 'measured from the waypoints'
        : 'typed at the close';
    final parts = <String>[
      date,
      measured,
      if (entry.disagrees) 'the typed figure differs',
    ];
    return parts.join(' · ');
  }

  /// A start time as the day it falls on, without the clock: a progress list is
  /// read across days, not across minutes.
  static String _entryDate(DateTime? when) {
    if (when == null) return 'date not recorded';
    final local = when.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}

/// A stamp over a group of figures. Not a score, and not a chart.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.colours);

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: Faces.ui.first,
        fontSize: Faces.stamp,
        letterSpacing: 0.8,
        color: colours.ash3,
      ),
    );
  }
}

/// One labelled fact about the record behind the total.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row, required this.colours});

  final (String, String) row;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              row.$1,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                color: colours.ash2,
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            row.$2,
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.body,
              color: colours.bone,
            ),
          ),
        ],
      ),
    );
  }
}

/// One recorded walk or drive, with its own way to be corrected.
///
/// The lifetime figures above are the summary of what is listed below, and the
/// summary is not correctable — only the record is. So every entry carries its
/// own hours, its own date, and its own control that opens it, and a correction
/// made here is made on the walk it belongs to.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.colours,
    required this.value,
    required this.label,
    required this.detail,
    required this.editLabel,
    required this.onEdit,
    this.placeholder = false,
  });

  final FieldColours colours;

  /// The hours this record counts for, or a stated placeholder for a drive
  /// that was opened and never closed. Never `0 h`: a drive with no duration
  /// yet is not a drive of nothing.
  final String value;
  final String label;
  final String detail;

  /// [placeholder] marks [value] as a stated absence rather than a figure, so
  /// it is set as supporting text instead of as a measured number.
  final bool placeholder;

  final String editLabel;

  /// Null when the screen was given no way to open the record.
  final Future<void> Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: BorderRadius.circular(Corners.control),
        border: Border.all(color: colours.rule),
      ),
      child: Row(
        children: [
          Expanded(
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
                          color: colours.bone,
                        ),
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: Faces.book.first,
                        fontSize: placeholder
                            ? Faces.supporting
                            : Faces.cardTitle,
                        color: placeholder ? colours.ash3 : colours.bone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.supporting,
                    height: 1.4,
                    color: colours.ash3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Insets.sm),
          // 44px of tap target, the same minimum every other control in the
          // app is held to.
          Semantics(
            button: true,
            label: editLabel,
            child: SizedBox(
              width: 44,
              height: 44,
              child: InkWell(
                onTap: onEdit == null ? null : () => onEdit!(),
                borderRadius: BorderRadius.circular(Corners.control),
                child: Center(
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: onEdit == null ? colours.ash4 : colours.ash2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain sentence of caveat. Never a warning colour: the point is what it
/// says, not that it is alarming.
class _Note extends StatelessWidget {
  const _Note(this.text, this.colours);

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Insets.sm),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.supporting,
          height: 1.4,
          color: colours.ash3,
        ),
      ),
    );
  }
}

class _HoursBlock extends StatelessWidget {
  const _HoursBlock({required this.hours});

  final HoursCount hours;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

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
                  hours.label,
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                    color: colours.bone,
                  ),
                ),
              ),
              Text(
                formatHours(hours.value),
                style: TextStyle(
                  fontFamily: Faces.book.first,
                  fontSize: Faces.measure,
                  color: colours.bone,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            hours.note,
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

class _Requirements extends StatelessWidget {
  const _Requirements({required this.progress});

  final TrailProgress progress;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outstanding for your trail sign-off',
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.label,
            color: colours.ash2,
          ),
        ),
        const SizedBox(height: Insets.md),
        for (final requirement in progress.requirements)
          _RequirementRow(requirement: requirement),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.requirement});

  final Requirement requirement;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final met = requirement.isMet;

    return Semantics(
      label: '${requirement.title}. ${requirement.detail}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Insets.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colours.ruleFaint)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A tick or an open circle, drawn rather than coloured: the state
            // has to be readable without relying on hue.
            SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(
                painter: _MarkPainter(met: met, c: colours),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requirement.title,
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.label,
                      color: met ? colours.ash2 : colours.bone,
                    ),
                  ),
                  if (!met) ...[
                    const SizedBox(height: 2),
                    Text(
                      // The amount still to do, not a shortfall score. "2 to
                      // go" can be acted on; "40 per cent short" only judges.
                      requirement.remainingLabel,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.stamp,
                        color: colours.ash3,
                      ),
                    ),
                  ],
                  if (requirement.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      requirement.detail,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.supporting,
                        height: 1.35,
                        color: colours.ash3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Insets.sm),
            Text(
              requirement.countLabel,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                color: met ? colours.ash3 : colours.bone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.met, required this.c});

  final bool met;
  final FieldColours c;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    if (met) {
      canvas.drawCircle(
        centre,
        size.width / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = c.moss,
      );
      final tick = Path()
        ..moveTo(centre.dx - 4, centre.dy)
        ..lineTo(centre.dx - 1, centre.dy + 3.5)
        ..lineTo(centre.dx + 4.5, centre.dy - 3.5);
      canvas.drawPath(
        tick,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = c.moss,
      );
    } else {
      canvas.drawCircle(
        centre,
        size.width / 2 - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = c.ash3,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.met != met || old.c != c;
}
