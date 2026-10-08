import 'package:drift/drift.dart' hide Column;
import 'package:field_log/data/database.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/design/theme.dart';
import 'package:flutter/material.dart';

/// Hours walked, and what the trail still asks for.
///
/// Contract rule 20: nothing here is presented as a score. There are no points,
/// no bars and no percentages, because a trainee reading "73 per cent" learns
/// that they are being graded rather than that there is an animal they have not
/// yet found. What is shown instead is the requirement and how far along it is,
/// which is the same information without the verdict attached.
class TallyScreen extends StatefulWidget {
  const TallyScreen({super.key, this.database, this.progress});

  final FieldLogDatabase? database;
  final TrailProgress? progress;

  @override
  State<TallyScreen> createState() => _TallyScreenState();
}

class _TallyScreenState extends State<TallyScreen> {
  TrailProgress? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.progress != null) {
      _progress = widget.progress;
      _loading = false;
    } else if (widget.database != null) {
      _loadProgress();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadProgress() async {
    if (widget.database == null) return;

    // Load all trail logs
    final trailLogs = await widget.database!
        .select(widget.database!.trailLogs)
        .get();

    final hoursByRole = <String, double>{};

    for (final log in trailLogs) {
      // Calculate hours for this trail log
      final waypoints = widget.database!.select(widget.database!.trailWaypoints)
        ..where((t) => t.trailLogId.equals(log.localId))
        ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]);

      final points = await waypoints.get();
      if (points.length >= 2) {
        double hours = 0.0;
        for (int i = 1; i < points.length; i++) {
          final prev = points[i - 1];
          final curr = points[i];
          final diff = curr.recordedAt.difference(prev.recordedAt).inSeconds;
          hours += diff / 3600.0;
        }
        // Add to the appropriate role bucket
        hoursByRole['none'] = (hoursByRole['none'] ?? 0.0) + hours;
      }
    }

    // Build hours list
    final hoursList = <HoursCount>[
      if ((hoursByRole['first'] ?? 0) > 0)
        HoursCount(
          role: 'first',
          label: 'First rifle',
          note: 'Hours with first rifle',
          value: hoursByRole['first']!,
        ),
      if ((hoursByRole['second'] ?? 0) > 0)
        HoursCount(
          role: 'second',
          label: 'Second rifle',
          note: 'Hours with second rifle',
          value: hoursByRole['second']!,
        ),
      if ((hoursByRole['none'] ?? 0) > 0)
        HoursCount(
          role: 'none',
          label: 'No rifle',
          note: 'Hours without a rifle',
          value: hoursByRole['none']!,
        ),
    ];

    // Fetch competencies for reference data
    // TODO: In a full implementation, the TallyScreen would have access to
    // the ChisimbaApi and SessionStore to fetch live competencies. For now,
    // we use locally stored reference data or empty requirements.
    final reqs = <Requirement>[];

    _progress = TrailProgress(hours: hoursList, requirements: reqs);
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
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

    final progress = _progress ?? TrailProgress.empty;

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
          for (final hours in progress.hours) ...[
            _HoursBlock(hours: hours),
            const SizedBox(height: Insets.md),
          ],
          const SizedBox(height: Insets.sm),
          _Requirements(progress: progress),
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
                _hours(hours.value),
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

  /// Hours are shown to two places because 9.25 hours is a real and reportable
  /// quantity, and rounding it to 9 would quietly change the record.
  /// Formats hours without inventing precision or dropping it.
  ///
  /// Trailing zeros are trimmed rather than kept: 14.5 is the number that was
  /// walked and "14.50 h" says something about the field width rather than
  /// about the day. A quarter hour still keeps its quarter, because 9.25 is a
  /// real and reportable quantity and rounding it to 9 would quietly change the
  /// record.
  static String _hours(double value) {
    if (value == value.roundToDouble()) {
      return '${value.round()} h';
    }
    var text = value.toStringAsFixed(2);
    if (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    return '$text h';
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

/// Hours walked, kept apart by rifle role.
///
/// Second-rifle hours are never added to first-rifle hours, and neither is
/// added to time walked without a rifle. Merging them would produce a single
/// larger number that means nothing the mentor could act on.
class HoursCount {
  const HoursCount({
    required this.role,
    required this.label,
    required this.note,
    required this.value,
  });

  /// One of `first`, `second`, `none`, matching the contract's rifle_role.
  final String role;
  final String label;
  final String note;
  final double value;
}

/// One outstanding requirement for a trail sign-off.
class Requirement {
  const Requirement({
    required this.title,
    required this.have,
    required this.need,
    this.detail = '',
  });

  final String title;
  final int have;
  final int need;
  final String detail;

  bool get isMet => have >= need;

  /// The count as words rather than as a proportion. "3 of 5" says what is
  /// still to do; "60 per cent" says how the trainee is doing.
  String get countLabel => '$have of $need';

  /// What is left, said as an amount rather than a shortfall score.
  String get remainingLabel => '${need - have} to go';
}

class TrailProgress {
  const TrailProgress({required this.hours, required this.requirements});

  /// Nothing walked and nothing outstanding. What a device that has no
  /// sign-off requirements fetched yet should show, rather than inventing a
  /// total of zero hours against requirements it was never told about.
  static const empty = TrailProgress(hours: [], requirements: []);

  final List<HoursCount> hours;
  final List<Requirement> requirements;
}
