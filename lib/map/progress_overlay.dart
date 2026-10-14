import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:field_log/design/tokens.dart';
import 'package:field_log/progress/progress_summary.dart';

/// An outing currently running on this phone, drawn on the map's progress card
/// so a drive or a walk can be watched — and stopped — without opening its
/// logbook.
///
/// The card is the indicator that something is started: it lives exactly as
/// long as the outing does, and its Stop action is what takes it away. It
/// deliberately carries no record-writing responsibility — ending the drive or
/// the walk belongs to the logbook screen, which owns the facts of the end
/// (hours, head count). Stopping here only clears the indicator.
class ActiveOuting {
  const ActiveOuting({
    required this.label,
    required this.kind,
    required this.startedAt,
    this.onStop,
  });

  /// The word the card leads with: "Drive" or "Trail".
  final String label;

  /// Which logbook opened it, so the stop action can name what it stops.
  final String kind;

  /// When the outing started, for the live elapsed readout.
  final DateTime startedAt;

  /// Takes the card off the map. Called from the card's own Stop action.
  final VoidCallback? onStop;
}

/// The progress card on the map: the time this device has actually walked and
/// driven, for the outing in hand.
///
/// While an outing is running the card is the live indicator — a ticking
/// elapsed readout and a Stop action — and it is hidden entirely once nothing
/// is started, so stopping the drive is what removes it. With an active outing
/// the card still unfolds on tap into the trail and the drive hours behind the
/// readout. Nothing here is a target, a bar or a percentage: a guide reads
/// their own logbook, and the record is what matters.
class ProgressOverlay extends StatefulWidget {
  const ProgressOverlay({
    super.key,
    required this.progress,
    required this.colours,
    this.activeOuting,
    this.onDismiss,
  });

  final OutingProgress progress;
  final FieldColours colours;
  final ActiveOuting? activeOuting;
  final VoidCallback? onDismiss;

  @override
  State<ProgressOverlay> createState() => _ProgressOverlayState();
}

class _ProgressOverlayState extends State<ProgressOverlay> {
  Timer? _ticker;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant ProgressOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.activeOuting != null;
    final isActive = widget.activeOuting != null;
    if (wasActive != isActive ||
        oldWidget.activeOuting?.startedAt != widget.activeOuting?.startedAt) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (widget.activeOuting == null) {
      _ticker = null;
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final outing = widget.activeOuting;
    final progress = widget.progress;
    final hasAnything =
        outing != null || progress.hasTrail || progress.hasDrive;
    if (!hasAnything) return const SizedBox.shrink();

    final colours = widget.colours;
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final active = outing != null;

    return Container(
      margin: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: const BorderRadius.all(Radius.circular(Corners.sheet)),
        border: Border.all(color: colours.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (active) _activeHeader(context, outing),
          Semantics(
            button: true,
            label: _summaryLabel(outing),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _open = !_open);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md,
                  vertical: Insets.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.timelapse, size: 18, color: colours.ash3),
                    const SizedBox(width: Insets.sm),
                    Expanded(child: _summary(context)),
                    Icon(
                      _open ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colours.ash3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: animationsDisabled
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Insets.md,
                      0,
                      Insets.md,
                      Insets.md,
                    ),
                    child: _details(context),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _activeHeader(BuildContext context, ActiveOuting outing) {
    final colours = widget.colours;
    return Container(
      color: colours.canopyOverlay,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outing.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    letterSpacing: 1.2,
                    color: colours.ash2,
                  ),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  _clock(outing.startedAt),
                  style: TextStyle(
                    fontFamily: Faces.book.first,
                    fontSize: Faces.measure,
                    color: colours.bone,
                  ),
                ),
              ],
            ),
          ),
          _stopButton(outing),
          TextButton(
            onPressed: () {
              widget.onDismiss?.call();
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _stopButton(ActiveOuting outing) {
    final colours = widget.colours;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: outing.onStop,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Insets.md),
            decoration: BoxDecoration(
              color: colours.canopyOverlay,
              borderRadius: const BorderRadius.all(
                Radius.circular(Corners.control),
              ),
              border: Border.all(color: colours.ruleStrong),
            ),
            child: Text(
              'Stop',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.label,
                color: colours.bone,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _clock(DateTime startedAt) {
    final elapsed = DateTime.now().difference(startedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Widget _summary(BuildContext context) {
    final progress = widget.progress;
    final colours = widget.colours;
    final parts = <String>[];
    if (progress.hasTrail) parts.add(formatHours(progress.trailHours));
    if (progress.hasDrive) parts.add(formatHours(progress.driveHours));
    final text = parts.isEmpty ? 'Nothing recorded yet' : parts.join(' · ');
    return Text(
      text,
      style: TextStyle(
        fontFamily: Faces.ui.first,
        fontSize: Faces.label,
        color: colours.bone,
      ),
    );
  }

  Widget _details(BuildContext context) {
    final progress = widget.progress;
    final trail = progress.trail;
    final drive = progress.drive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trail != null && trail.hours.isNotEmpty) ...[
          _sectionTitle('On foot'),
          for (final hour in trail.hours)
            _row(hour.label, formatHours(hour.value)),
          if (trail.walkLengthKm != null)
            _row('Distance', _trimKm(trail.walkLengthKm!)),
          if (trail.rifleDetails != null && trail.rifleDetails!.isNotEmpty)
            _note(trail.rifleDetails!),
          if (trail.hoursReconciled)
            _note('A walk has hours that disagree with its waypoints.'),
        ],
        if (drive != null && drive.count > 0) ...[
          _sectionTitle('By vehicle'),
          _row('Drives', '${drive.count}'),
          if (drive.totalHours > 0)
            _row('Hours', formatHours(drive.totalHours)),
          if (drive.daylightHours != null && drive.daylightHours! > 0)
            _row('Daylight', formatHours(drive.daylightHours!)),
          if (drive.nightHours != null && drive.nightHours! > 0)
            _row('Night', formatHours(drive.nightHours!)),
          if (drive.offRoadSeconds != null && drive.offRoadSeconds! > 0)
            _row('Off-road', '${(drive.offRoadSeconds! / 60).round()} min'),
          if (drive.vehicleId != null && drive.vehicleId!.isNotEmpty)
            _row('Vehicle', drive.vehicleId!),
          if (drive.guestCount != null) _row('Guests', '${drive.guestCount}'),
          _inspections(drive),
          if (drive.offTrackUsed == true) _note('Off-track driving was used.'),
          if (drive.weather.isNotEmpty) _note(drive.weather),
          if (drive.notes.isNotEmpty) _note(drive.notes),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    final colours = widget.colours;
    return Padding(
      padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.xs),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.stamp,
          letterSpacing: 1.1,
          color: colours.ash3,
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    final colours = widget.colours;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                color: colours.ash2,
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            value,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              color: colours.bone,
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(String text) {
    final colours = widget.colours;
    return Padding(
      padding: const EdgeInsets.only(top: Insets.xs),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: Faces.book.first,
          fontSize: Faces.supporting,
          fontStyle: FontStyle.italic,
          color: colours.ash3,
        ),
      ),
    );
  }

  Widget _inspections(DriveProgress drive) {
    final parts = <String>[
      if (drive.inspectionOilOk != null)
        'Oil ${drive.inspectionOilOk! ? 'ok' : 'no'}',
      if (drive.inspectionWaterOk != null)
        'Water ${drive.inspectionWaterOk! ? 'ok' : 'no'}',
      if (drive.inspectionTyresOk != null)
        'Tyres ${drive.inspectionTyresOk! ? 'ok' : 'no'}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return _row('Inspections', parts.join(' · '));
  }

  String _summaryLabel(ActiveOuting? outing) {
    final progress = widget.progress;
    if (outing != null) return '${outing.label}, elapsed time and progress';
    return 'Progress: ${formatHours(progress.trailHours)} on foot, '
        '${formatHours(progress.driveHours)} driven';
  }

  String _trimKm(double km) {
    final rounded = (km * 100).round() / 100;
    final trimmed = rounded
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '$trimmed km';
  }
}
