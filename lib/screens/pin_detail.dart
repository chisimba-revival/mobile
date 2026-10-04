import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:flutter/material.dart';

/// What one recorded observation says about itself.
///
/// A plain value rather than a Drift row so the screen can be built and tested
/// without a database, and so the reading of a record is separated from the
/// storage of it.
class SightingSummary {
  const SightingSummary({
    required this.localId,
    required this.visual,
    required this.commonName,
    required this.scientificName,
    required this.status,
    required this.capturedAt,
    required this.recordedAt,
    required this.accuracyMetres,
    required this.distanceMetres,
    required this.bearingDegrees,
    required this.notes,
    this.count,
    this.speciesCode,
    this.behaviour,
    this.ageSexClass,
    this.recordedSpeciesCode,
    this.recordedCount,
    this.correctionReason,
    this.verifiedBy,
    this.verificationNotes,
    this.lateArrival = false,
  });

  final String localId;
  final PinVisual visual;
  final String commonName;
  final String scientificName;
  final String status;
  final DateTime capturedAt;
  final DateTime recordedAt;
  final double accuracyMetres;
  final int? distanceMetres;
  final int? bearingDegrees;
  final String notes;
  final int? count;
  final String? speciesCode;
  final String? behaviour;
  final String? ageSexClass;
  final String? recordedSpeciesCode;
  final int? recordedCount;
  final String? correctionReason;
  final String? verifiedBy;
  final String? verificationNotes;
  final bool lateArrival;

  /// The name to show, falling back to the description of a record that has no
  /// species rather than to a blank line.
  String get displayName =>
      speciesCode == null ? 'Not yet identified' : commonName;
}

/// One observation, read.
///
/// This screen never offers to edit the position. A correction is made by
/// adding a note, because a record that can be quietly moved is not a record.
class PinDetailScreen extends StatelessWidget {
  const PinDetailScreen({super.key, required this.sighting});

  final SightingSummary sighting;

  static Future<void> open(BuildContext context, String localId) {
    // A placeholder route until the app has a router. Returning the id keeps
    // the caller honest: it cannot pretend to have shown the record.
    debugPrint('open pin $localId');
    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          _Header(sighting: sighting, colours: colours, text: text),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Insets.lg),
              children: [
                if (sighting.recordedCount != null ||
                    sighting.recordedSpeciesCode != null)
                  _Correction(sighting: sighting, colours: colours, text: text),
                _Field(
                  label: 'Species',
                  value: sighting.displayName,
                  detail: sighting.speciesCode == null
                      ? 'Recorded in your own words instead.'
                      : '${sighting.scientificName} · ${sighting.speciesCode}',
                  colours: colours,
                  text: text,
                ),
                if (sighting.count != null)
                  _Field(
                    label: 'Count',
                    value: '${sighting.count}',
                    colours: colours,
                    text: text,
                  ),
                _Field(
                  label: 'Behaviour',
                  value: sighting.behaviour ?? 'Not recorded',
                  colours: colours,
                  text: text,
                ),
                _Field(
                  label: 'Age and sex',
                  value: sighting.ageSexClass ?? 'Not recorded',
                  colours: colours,
                  text: text,
                ),
                _Field(
                  label: 'Where you were',
                  value: _whereYouWere(),
                  detail:
                      'Position accuracy ±${sighting.accuracyMetres.round()} m',
                  colours: colours,
                  text: text,
                ),
                _Field(
                  // Capture time and record time are separate facts and neither
                  // stands in for the other, so both are shown and named.
                  label: 'Captured',
                  value: _clock(sighting.capturedAt),
                  detail: 'When you saw it',
                  colours: colours,
                  text: text,
                ),
                _Field(
                  label: 'Recorded',
                  value: _clock(sighting.recordedAt),
                  detail: 'When it was written down',
                  colours: colours,
                  text: text,
                ),
                if (sighting.notes.isNotEmpty)
                  _Field(
                    label: 'Your words',
                    value: sighting.notes,
                    colours: colours,
                    text: text,
                  ),
                if (sighting.verificationNotes != null)
                  _Field(
                    label: "Mentor's note",
                    value: sighting.verificationNotes!,
                    colours: colours,
                    text: text,
                  ),
                const SizedBox(height: Insets.xl),
              ],
            ),
          ),
          _Dock(colours: colours, text: text),
        ],
      ),
    );
  }

  String _whereYouWere() {
    final parts = <String>[];
    if (sighting.distanceMetres != null) {
      parts.add('${sighting.distanceMetres} m from the vehicle');
    }
    if (sighting.bearingDegrees != null) {
      parts.add(_compass(sighting.bearingDegrees!));
    }
    if (parts.isEmpty) {
      return 'Approximate position only';
    }
    return parts.join(', ');
  }

  static String _clock(DateTime at) =>
      '${at.toIso8601String().substring(0, 10)} '
      '${at.toIso8601String().substring(11, 16)}';
}

const _cardinals = <String, String>{
  'N': 'north',
  'NE': 'north-east',
  'E': 'east',
  'SE': 'south-east',
  'S': 'south',
  'SW': 'south-west',
  'W': 'west',
  'NW': 'north-west',
};

String _compass(int degrees) {
  final index = (((degrees % 360) + 22) ~/ 45) % 8;
  final name = _cardinals.values.elementAt(index);
  return 'bearing $degrees° ($name)';
}

class _Header extends StatelessWidget {
  const _Header({
    required this.sighting,
    required this.colours,
    required this.text,
  });

  final SightingSummary sighting;
  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colours.canopy,
      padding: const EdgeInsets.all(Insets.lg),
      child: Row(
        children: [
          _Clip(
            label: sighting.speciesCode ?? '···',
            accent: _accentFor(sighting.visual.state, colours),
            colours: colours,
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sight · ${PinDetailScreen._clock(sighting.capturedAt)}',
                  style: text.labelSmall?.copyWith(color: colours.ash2),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  sighting.displayName,
                  style: text.headlineSmall?.copyWith(color: colours.bone),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close, color: colours.ash1),
          ),
        ],
      ),
    );
  }

  // The accent follows the pin's state, so a card header and the map pin for
  // the same record always read as the same kind of thing.
  static Color _accentFor(PinState state, FieldColours c) => switch (state) {
    PinState.verified => c.moss,
    PinState.corrected => c.dust,
    PinState.deleted => c.ash3,
    PinState.queued || PinState.needsReview || PinState.unverified => c.straw,
  };
}

class _Clip extends StatelessWidget {
  const _Clip({
    required this.label,
    required this.accent,
    required this.colours,
  });

  final String label;
  final Color accent;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: accent),
        borderRadius: BorderRadius.circular(Corners.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.stamp,
          letterSpacing: 0.5,
          color: accent,
        ),
      ),
    );
  }
}

class _Correction extends StatelessWidget {
  const _Correction({
    required this.sighting,
    required this.colours,
    required this.text,
  });

  final SightingSummary sighting;
  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    // The original is shown next to the corrected value, permanently. Rule 15
    // requires it, and a trainee can only learn from a correction if they can
    // see what was changed and why.
    final changes = <String>[];
    if (sighting.recordedSpeciesCode != null &&
        sighting.recordedSpeciesCode != sighting.speciesCode) {
      changes.add('${sighting.recordedSpeciesCode} → ${sighting.speciesCode}');
    }
    if (sighting.recordedCount != null &&
        sighting.recordedCount != sighting.count) {
      changes.add('${sighting.recordedCount} → ${sighting.count}');
    }
    if (changes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.lg),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        border: Border.all(color: colours.dust),
        borderRadius: BorderRadius.circular(Corners.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Corrected',
            style: text.labelLarge?.copyWith(color: colours.dust),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            changes.join(' · '),
            style: text.bodyMedium?.copyWith(color: colours.bone),
          ),
          if (sighting.correctionReason != null) ...[
            const SizedBox(height: Insets.xs),
            Text(
              sighting.correctionReason!,
              style: text.bodySmall?.copyWith(color: colours.ash2),
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.colours,
    required this.text,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: colours.ash2)),
          const SizedBox(height: Insets.xs),
          Text(value, style: text.bodyLarge?.copyWith(color: colours.bone)),
          if (detail != null) ...[
            const SizedBox(height: Insets.xs),
            Text(detail!, style: text.bodySmall?.copyWith(color: colours.ash2)),
          ],
        ],
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.colours, required this.text});

  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colours.canopy,
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: colours.bone,
                side: BorderSide(color: colours.ruleStrong),
              ),
              child: const Text('Add a note'),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: colours.bone,
                foregroundColor: colours.canopy,
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
