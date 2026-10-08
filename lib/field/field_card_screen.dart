import 'package:field_log/data/reference_loader.dart';
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/field/card_state.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';

/// The field card: what the trainee writes down, in the vehicle, offline.
///
/// The first decision this screen asks is not what species, but whether the
/// trainee is naming the animal or describing it. That question exists because
/// contract rule 21 permits a sighting with no species at all, and an interface
/// that only offered a species field would force a guess at the moment of
/// capture. A guess made in a vehicle becomes the record, and then it is the
/// thing being corrected all season.
class FieldCardScreen extends StatefulWidget {
  const FieldCardScreen({
    super.key,
    required this.initial,
    required this.species,
    required this.reference,
    required this.onSave,
    required this.onCancel,
    this.cardNumber = 1,
    this.coordinateLabel = '',
    this.accuracyMetres,
    this.isTrailWalk = true,
    this.outings = const [],
    this.selectedOutingId,
    this.onOutingChanged,
    this.recentSpecies = const [],
    this.onReloadSpecies,
    this.onSpeciesUsed,
  });

  final FieldDraft initial;
  final List<SpeciesChoice> species;
  final ReferenceValues reference;

  /// Called with the finished draft. Returning a Future lets the caller commit
  /// the record before the sheet closes, so the card does not vanish and take
  /// the observation with it if the write fails.
  final Future<void> Function(FieldDraft draft) onSave;
  final VoidCallback onCancel;

  /// The clip in the header, counting this card within the walk.
  final int cardNumber;

  /// Where the pin sits, shown in the strip that stays on screen while typing.
  final String coordinateLabel;
  final double? accuracyMetres;

  /// Trail walks carry lessons learned, hours and a rifle role. A game drive
  /// does not, and showing those fields on a drive would invite hours that mean
  /// nothing.
  final bool isTrailWalk;

  /// Available outings to select from.
  final List<Outing> outings;

  /// Currently selected outing ID.
  final String? selectedOutingId;

  /// Called when the user selects a different outing.
  final ValueChanged<String?>? onOutingChanged;

  /// Species this device recorded recently, shown first in the picker so the
  /// common case needs no typing at all.
  final List<SpeciesChoice> recentSpecies;

  /// Re-downloads the reference catalogue (bypassing the freshness window)
  /// and returns it. The picker's empty state offers this as a retry; the
  /// returned snapshot also feeds the open sheet, so a successful retry
  /// repopulates the list in place.
  final Future<ReferenceSnapshot> Function()? onReloadSpecies;

  /// Called after a successful save with the species that was recorded, so
  /// the caller can remember it as recently used.
  final ValueChanged<SpeciesChoice>? onSpeciesUsed;

  @override
  State<FieldCardScreen> createState() => _FieldCardScreenState();
}

class _FieldCardScreenState extends State<FieldCardScreen> {
  late FieldDraft _draft;
  late final TextEditingController _notes;
  late final TextEditingController _lessons;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _notes = TextEditingController(text: widget.initial.notes);
    _lessons = TextEditingController(text: widget.initial.lessonsLearned);
  }

  @override
  void dispose() {
    _notes.dispose();
    _lessons.dispose();
    super.dispose();
  }

  void _update(FieldDraft next) => setState(() => _draft = next);

  Future<void> _save() async {
    if (!_draft.canSave || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_draft.copyWith(notes: _notes.text));
      final used = _selectedSpecies;
      if (used != null) {
        widget.onSpeciesUsed?.call(used);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final theme = Theme.of(context);

    return FieldScaffold(
      leading: _Clip(text: widget.cardNumber.toString().padLeft(2, '0')),
      eyebrow: _draft.mode == CaptureMode.unnamed
          ? 'Field card · describing it'
          : 'Field card · identified',
      title: 'What did you see?',
      onBack: widget.onCancel,
      backTooltip: 'Discard this card',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.md,
          Insets.lg,
          Insets.xxxl,
        ),
        children: [
          if (widget.coordinateLabel.isNotEmpty)
            _LocationStrip(
              coordinateLabel: widget.coordinateLabel,
              accuracyMetres: widget.accuracyMetres,
              colours: colours,
            ),
          const SizedBox(height: Insets.lg),
          _ModeSwitch(
            value: _draft.mode,
            onChanged: (mode) => _update(_draft.switchTo(mode)),
          ),
          const SizedBox(height: Insets.lg),
          if (_draft.isUnnamed)
            ..._unnamedGroups(colours, theme)
          else
            ..._identifiedGroups(colours, theme),
          const SizedBox(height: Insets.lg),
          _whereYouWere(colours, theme),
          const SizedBox(height: Insets.lg),
          _recordGroup(colours, theme),
          if (widget.isTrailWalk) ...[
            const SizedBox(height: Insets.lg),
            _trailWalkOnly(colours, theme),
          ],
        ],
      ),
      bottom: _Dock(
        canSave: _draft.canSave,
        saving: _saving,
        reason: _draft.cannotSaveReason,
        colours: colours,
        onCancel: widget.onCancel,
        onSave: _save,
      ),
    );
  }

  List<Widget> _identifiedGroups(FieldColours colours, ThemeData theme) {
    return [
      if (widget.outings.isNotEmpty) ...[
        _Group(
          label: 'Outing',
          hint: 'Which drive, hike, or camp is this sighting on?',
          child: _OutingField(
            outings: widget.outings,
            selectedId: widget.selectedOutingId,
            colours: colours,
            onChanged: widget.onOutingChanged ?? (_) {},
          ),
        ),
        const SizedBox(height: Insets.lg),
      ],
      _Group(
        label: 'The sighting',
        hint: _draft.speciesCode == null
            ? 'Name it now. A mentor corrects you later, and what you wrote is kept.'
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SpeciesField(
              choice: _selectedSpecies,
              colours: colours,
              onPick: (choice) =>
                  _update(_draft.copyWith(speciesCode: choice.code)),
              options: widget.species,
              recent: widget.recentSpecies,
              onReload: widget.onReloadSpecies,
            ),
            const SizedBox(height: Insets.lg),
            _CountStepper(
              count: _draft.count,
              colours: colours,
              onChanged: (value) => value == null
                  ? _update(_draft.copyWith(clearCount: true))
                  : _update(_draft.copyWith(count: value)),
            ),
          ],
        ),
      ),
      const SizedBox(height: Insets.lg),
      _Chips(
        label: 'Behaviour',
        values: widget.reference.behaviours,
        selected: _draft.behaviour,
        colours: colours,
        onChanged: (value) => value == null
            ? _update(_draft.copyWith(clearBehaviour: true))
            : _update(_draft.copyWith(behaviour: value)),
      ),
      const SizedBox(height: Insets.lg),
      _Chips(
        label: 'Age and sex — if you can tell',
        optional: true,
        values: widget.reference.ageSexClasses,
        selected: _draft.ageSexClass,
        colours: colours,
        onChanged: (value) => value == null
            ? _update(_draft.copyWith(clearAgeSex: true))
            : _update(_draft.copyWith(ageSexClass: value)),
      ),
    ];
  }

  List<Widget> _unnamedGroups(FieldColours colours, ThemeData theme) {
    return [
      _Group(
        label: 'What you saw, in your words',
        hint:
            'Being unsure is a real answer and gets recorded as one. Your '
            'mentor can identify it afterwards, and this note stays exactly as '
            'you wrote it.',
        child: _NoteField(
          controller: _notes,
          colours: colours,
          hint:
              'Tracks heading north across the road, fresh. Could not say '
              'whose. Grass flattened about a metre across, no spoor in it.',
          noteBody: true,
        ),
      ),
      const SizedBox(height: Insets.lg),
      _Chips(
        label: 'Behaviour, if you know it',
        optional: true,
        values: widget.reference.behaviours,
        selected: _draft.behaviour,
        colours: colours,
        onChanged: (value) => value == null
            ? _update(_draft.copyWith(clearBehaviour: true))
            : _update(_draft.copyWith(behaviour: value)),
      ),
      const SizedBox(height: Insets.sm),
      _CountStepper(
        count: _draft.count,
        colours: colours,
        hint:
            'Leave it alone if the number means nothing. A bellow heard is '
            'one event, not one animal.',
        onChanged: (value) => value == null
            ? _update(_draft.copyWith(clearCount: true))
            : _update(_draft.copyWith(count: value)),
      ),
    ];
  }

  Widget _whereYouWere(FieldColours colours, ThemeData theme) {
    return _Group(
      label: 'Where you were',
      hint:
          'Together these let a reviewer tell a new animal from the same one '
          'logged twice. Approximate is fine.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _NumberField(
              label: 'Distance from vehicle',
              unit: 'm',
              value: _draft.distanceMetres,
              colours: colours,
              onChanged: (value) => value == null
                  ? _update(_draft.copyWith(clearDistance: true))
                  : _update(_draft.copyWith(distanceMetres: value.round())),
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: _SelectField<CompassPoint>(
              label: 'Direction',
              values: CompassPoint.values,
              selected: _draft.bearingDegrees == null
                  ? null
                  : CompassPoint.fromDegrees(_draft.bearingDegrees!),
              colours: colours,
              labelOf: (point) => point.label,
              onChanged: (point) => point == null
                  ? _update(_draft.copyWith(clearBearing: true))
                  : _update(_draft.copyWith(bearingDegrees: point.degrees)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordGroup(FieldColours colours, ThemeData theme) {
    // In "I am not sure" mode the note hero above is already the observation,
    // and it is bound to the same field as this one. Rendering both would put a
    // single value in two boxes that mean different things and leave saving to
    // pick one at random, so the second is dropped rather than duplicated.
    // Splitting them properly needs the observation to become its own field,
    // which is a change to FieldDraft rather than to this screen.
    return _Group(
      label: _draft.isUnnamed ? 'Anything else' : 'Record',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_draft.isUnnamed) ...[
            _NoteField(
              controller: _notes,
              colours: colours,
              hint: 'What made you certain? What were you unsure of?',
            ),
            const SizedBox(height: Insets.md),
          ],
          _Photos(
            colours: colours,
            hint:
                'Uploaded on their own, so a slow photo never delays the '
                'record.',
          ),
        ],
      ),
    );
  }

  Widget _trailWalkOnly(FieldColours colours, ThemeData theme) {
    return _Group(
      label: 'Trail walk',
      muted: true,
      hint: 'These apply to walks only. A game drive does not carry them.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NoteField(
            controller: _lessons,
            colours: colours,
            label: 'What will you do differently on the next walk?',
            hint: 'Your own words. Nobody signs off on this.',
          ),
          const SizedBox(height: Insets.md),
          _NumberField(
            label: 'Hours on this walk',
            unit: 'h',
            value: _draft.hoursOnThisWalk,
            allowsDecimals: true,
            colours: colours,
            onChanged: (value) => value == null
                ? _update(_draft.copyWith(clearHours: true))
                : _update(_draft.copyWith(hoursOnThisWalk: value.toDouble())),
          ),
          const SizedBox(height: Insets.md),
          _Chips(
            label: 'Your role on this walk',
            values: const ['first', 'second', 'none'],
            selected: _draft.rifleRole,
            colours: colours,
            labelOf: _roleLabel,
            onChanged: (value) => _update(_draft.copyWith(rifleRole: value!)),
          ),
          const SizedBox(height: Insets.sm),
          _Supporting(
            'Kept apart from the other hours. Second-rifle hours are counted '
            'separately from first rifle and from your own.',
            colours,
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'first' => '1st rifle',
    'second' => '2nd rifle',
    'none' => 'Participant',
    _ => role,
  };

  SpeciesChoice? get _selectedSpecies {
    final code = _draft.speciesCode;
    if (code == null) {
      return null;
    }
    for (final choice in widget.species) {
      if (choice.code == code) {
        return choice;
      }
    }
    return null;
  }
}

/// The card's own number, as a clip on the corner of a field card.
class _Clip extends StatelessWidget {
  const _Clip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Container(
      width: 44,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: BorderRadius.circular(Corners.chip),
        border: Border.all(color: colours.ruleStrong),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.stamp,
          letterSpacing: 0.5,
          color: colours.bone,
        ),
      ),
    );
  }
}

/// The position strip.
///
/// This never leaves the screen while the trainee types, because a record
/// whose position is not visible while it is being written is a record that
/// gets written about the wrong place.
class _LocationStrip extends StatefulWidget {
  const _LocationStrip({
    required this.coordinateLabel,
    required this.accuracyMetres,
    required this.colours,
  });

  final String coordinateLabel;
  final double? accuracyMetres;
  final FieldColours colours;

  @override
  State<_LocationStrip> createState() => _LocationStripState();
}

class _LocationStripState extends State<_LocationStrip> {
  double? _heading;

  @override
  void initState() {
    super.initState();
    _startCompass();
  }

  void _startCompass() {
    FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final heading = event.heading;
      if (heading != null) {
        setState(() => _heading = heading);
      }
    });
  }

  /// Determines the GPS fix quality based on accuracy and satellite count.
  ///
  /// This is a heuristic since the platform doesn't expose fix type directly.
  /// - 3D fix: accuracy ≤ 10m and ≥ 4 satellites
  /// - 2D fix: accuracy ≤ 50m and ≥ 3 satellites
  /// - No fix: otherwise
  String _fixQuality() {
    final acc = widget.accuracyMetres;
    if (acc == null || acc == 0) return 'No fix';
    // We don't have satellite count in the strip, so use accuracy only
    if (acc <= 10) return '3D';
    if (acc <= 50) return '2D';
    return 'Weak';
  }

  Color _fixColor(FieldColours colours) {
    final quality = _fixQuality();
    switch (quality) {
      case '3D':
        return colours.moss;
      case '2D':
        return colours.straw;
      default:
        return colours.ash3;
    }
  }

  Future<void> _copyCoords() async {
    await Clipboard.setData(ClipboardData(text: widget.coordinateLabel));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordinates copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colours = widget.colours;
    final fixQuality = _fixQuality();
    final fixColour = _fixColor(colours);

    return Semantics(
      button: true,
      label: 'Location: ${widget.coordinateLabel}. Tap to copy.',
      onTap: _copyCoords,
      child: InkWell(
        onTap: _copyCoords,
        borderRadius: BorderRadius.circular(Corners.control),
        child: Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: colours.inset,
            borderRadius: BorderRadius.circular(Corners.control),
            border: Border.all(color: colours.rule),
          ),
          child: Row(
            children: [
              Icon(Icons.my_location, size: 16, color: colours.straw),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.supporting,
                      color: colours.ash2,
                    ),
                    children: [
                      const TextSpan(text: 'Pinned at '),
                      TextSpan(
                        text: widget.coordinateLabel,
                        style: TextStyle(color: colours.bone),
                      ),
                      if (widget.accuracyMetres != null) ...[
                        const TextSpan(text: '  ±'),
                        TextSpan(
                          text: '${widget.accuracyMetres!.round()} m',
                          style: TextStyle(color: colours.bone),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Compass rose (tiny, rotates with device heading)
              if (_heading != null) ...[
                const SizedBox(width: Insets.sm),
                Transform.rotate(
                  angle: -_heading! * 3.141592653589793 / 180,
                  child: Icon(Icons.explore, size: 14, color: colours.ash2),
                ),
              ],
              const SizedBox(width: Insets.sm),
              // Fix quality badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: fixColour.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Corners.chip),
                  border: Border.all(color: fixColour, width: 0.8),
                ),
                child: Text(
                  fixQuality,
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    fontWeight: FontWeight.w600,
                    color: fixColour,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two modes, as a radio group.
///
/// A switch rather than two screens, because the decision is made once up front
/// and the trainee should not have to navigate to change their mind. Switching
/// keeps everything already typed, which is the case that matters: someone who
/// starts to name an animal, becomes unsure, and switches.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.value, required this.onChanged});

  final CaptureMode value;
  final ValueChanged<CaptureMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: 'How this sighting is recorded',
          child: Column(
            children: [
              _ModeOption(
                selected: value == CaptureMode.identified,
                icon: Icons.circle_outlined,
                title: 'I identified it',
                subtitle: 'Name the animal now',
                colours: colours,
                onTap: () => onChanged(CaptureMode.identified),
              ),
              const SizedBox(height: Insets.sm),
              _ModeOption(
                selected: value == CaptureMode.unnamed,
                icon: Icons.edit_note,
                title: 'I am not sure',
                subtitle: 'Write what you saw. A mentor names it later.',
                colours: colours,
                onTap: () => onChanged(CaptureMode.unnamed),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        _Supporting(
          value == CaptureMode.unnamed
              ? 'Nothing you wrote is lost. The note stays as you wrote it even '
                    'after a mentor identifies it.'
              : 'A mentor corrects you later, and nothing you wrote is lost.',
          colours,
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colours,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final FieldColours colours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.control),
        child: Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: selected ? colours.canopyOverlay : colours.canopyRaised,
            borderRadius: BorderRadius.circular(Corners.control),
            border: Border.all(
              color: selected ? colours.bone : colours.rule,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colours.bone : colours.ash3,
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.label,
                        color: colours.bone,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.supporting,
                        color: colours.ash2,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check, size: 16, color: colours.bone),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.child,
    this.hint,
    this.muted = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                letterSpacing: 0.8,
                color: muted ? colours.ash3 : colours.ash1,
              ),
            ),
            if (muted) ...[
              const SizedBox(width: Insets.sm),
              Text(
                'walk only',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.stamp,
                  color: colours.ash3,
                ),
              ),
            ],
          ],
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

/// A hint. Not decoration: every one of these explains why the app is asking
/// for something, which is the difference between a form that trains thought
/// and one that trains compliance.
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

class _SpeciesField extends StatelessWidget {
  const _SpeciesField({
    required this.choice,
    required this.colours,
    required this.onPick,
    required this.options,
    this.recent = const [],
    this.onReload,
  });

  final SpeciesChoice? choice;
  final FieldColours colours;
  final ValueChanged<SpeciesChoice> onPick;
  final List<SpeciesChoice> options;
  final List<SpeciesChoice> recent;
  final Future<ReferenceSnapshot> Function()? onReload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(Corners.control),
          child: Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: colours.inset,
              borderRadius: BorderRadius.circular(Corners.control),
              border: Border.all(color: colours.ruleStrong),
            ),
            child: Row(
              children: [
                _Clip(text: choice?.code ?? '····'),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice?.commonName ?? 'Choose a species',
                        style: TextStyle(
                          fontFamily: Faces.book.first,
                          fontSize: Faces.body,
                          color: choice == null ? colours.ash3 : colours.bone,
                        ),
                      ),
                      if (choice != null)
                        Text(
                          choice!.scientificName,
                          style: TextStyle(
                            fontFamily: Faces.book.first,
                            fontSize: Faces.supporting,
                            fontStyle: FontStyle.italic,
                            color: colours.ash2,
                          ),
                        )
                      else
                        Text(
                          'Search by common or scientific name',
                          style: TextStyle(
                            fontFamily: Faces.ui.first,
                            fontSize: Faces.supporting,
                            color: colours.ash3,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more, size: 18, color: colours.ash2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<SpeciesChoice>(
      context: context,
      backgroundColor: colours.canopyRaised,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Corners.sheet),
        ),
      ),
      builder: (context) => _SpeciesPicker(
        options: options,
        selected: choice,
        colours: colours,
        recent: recent,
        onReload: onReload,
      ),
    );
    if (picked != null) {
      onPick(picked);
    }
  }
}

/// Outing selector dropdown.
class _OutingField extends StatelessWidget {
  const _OutingField({
    required this.outings,
    required this.selectedId,
    required this.colours,
    required this.onChanged,
  });

  final List<Outing> outings;
  final String? selectedId;
  final FieldColours colours;
  final ValueChanged<String?> onChanged;

  String _labelFor(Outing outing) {
    final kind = outing.kind;
    final status = outing.status;
    final date = outing.plannedStart.isNotEmpty
        ? outing.plannedStart.substring(0, 10)
        : '';
    return '$kind — $status — $date';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      decoration: BoxDecoration(
        color: colours.inset,
        borderRadius: BorderRadius.circular(Corners.control),
        border: Border.all(color: colours.rule),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: colours.canopyRaised,
          hint: Text(
            'Select an outing',
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.body,
              color: colours.ash3,
            ),
          ),
          items: [
            for (final outing in outings)
              DropdownMenuItem<String>(
                value: outing.id,
                child: Text(
                  _labelFor(outing),
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.body,
                    color: colours.bone,
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SpeciesPicker extends StatefulWidget {
  const _SpeciesPicker({
    required this.options,
    required this.selected,
    required this.colours,
    this.recent = const [],
    this.onReload,
  });

  final List<SpeciesChoice> options;
  final SpeciesChoice? selected;
  final FieldColours colours;

  /// Recently used species, shown first when the query is empty. Entries
  /// whose code is no longer in the catalogue are dropped rather than offered
  /// — a pick the card cannot resolve back to a name would look unset.
  final List<SpeciesChoice> recent;

  /// Re-downloads the catalogue and returns it; see
  /// [FieldCardScreen.onReloadSpecies].
  final Future<ReferenceSnapshot> Function()? onReload;

  @override
  State<_SpeciesPicker> createState() => _SpeciesPickerState();
}

class _SpeciesPickerState extends State<_SpeciesPicker> {
  String _query = '';

  /// Set by a successful reload, overriding the options the sheet was opened
  /// with so a retry repopulates the list without reopening it.
  ReferenceSnapshot? _reloaded;
  bool _loading = false;

  List<SpeciesChoice> get _all => _reloaded?.species ?? widget.options;

  Future<void> _reload() async {
    final reload = widget.onReload;
    if (reload == null || _loading) return;
    setState(() => _loading = true);
    try {
      final snapshot = await reload();
      if (!mounted) return;
      setState(() {
        _reloaded = snapshot;
        _loading = false;
      });
    } on Object {
      // The loader is expected to swallow its own failures; this only guards
      // a caller that supplies its own callback.
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final matches = _all.where((option) => option.matches(query)).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: Insets.sm),
                decoration: BoxDecoration(
                  color: widget.colours.ruleStrong,
                  borderRadius: BorderRadius.circular(Corners.chip),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.sm,
                  Insets.lg,
                  Insets.md,
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.body,
                    color: widget.colours.bone,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Common or scientific name',
                    hintStyle: TextStyle(color: widget.colours.ash3),
                    prefixIcon: Icon(Icons.search, color: widget.colours.ash2),
                  ),
                ),
              ),
              Expanded(child: _buildBody(query, matches)),
            ],
          ),
        ),
      ),
    );
  }

  /// The area below the search field, in the order a guide meets it:
  /// downloading, nothing to show, no match, then the list itself.
  Widget _buildBody(String query, List<SpeciesChoice> matches) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: widget.colours.moss,
              ),
            ),
            const SizedBox(height: Insets.md),
            Text(
              'Downloading the species list…',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                color: widget.colours.ash3,
              ),
            ),
          ],
        ),
      );
    }

    if (_all.isEmpty) {
      final failed = _reloaded?.refreshError != null;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No species list yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Faces.book.first,
                  fontSize: Faces.body,
                  color: widget.colours.bone,
                ),
              ),
              const SizedBox(height: Insets.sm),
              Text(
                failed
                    ? 'Could not reach the reserve office. Try again when you have a connection.'
                    : 'The list downloads once and is kept on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  height: 1.4,
                  color: widget.colours.ash3,
                ),
              ),
              if (widget.onReload != null) ...[
                const SizedBox(height: Insets.lg),
                OutlinedButton.icon(
                  onPressed: _reload,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.colours.bone,
                    side: BorderSide(color: widget.colours.ruleStrong),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Download the species list'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (query.isNotEmpty && matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nothing matches "$query"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Faces.book.first,
                  fontSize: Faces.body,
                  color: widget.colours.bone,
                ),
              ),
              const SizedBox(height: Insets.sm),
              Text(
                'Try a shorter word, the code, or the scientific name.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  height: 1.4,
                  color: widget.colours.ash3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entries = _entries(query, matches);
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.lg,
              Insets.xs,
            ),
            child: Text(
              entry,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                letterSpacing: 0.6,
                color: widget.colours.ash2,
              ),
            ),
          );
        }
        return _rowFor(entry as SpeciesChoice);
      },
    );
  }

  /// Flattens the list into rows with section headers. Headers only appear
  /// when the recents section has something to say; with no recents the list
  /// is the plain catalogue it always was.
  List<Object> _entries(String query, List<SpeciesChoice> matches) {
    if (query.isNotEmpty) return matches;
    final shownCodes = <String>{};
    final recentRows = <SpeciesChoice>[];
    for (final recent in widget.recent) {
      if (shownCodes.contains(recent.code)) continue;
      final match = _all.where((o) => o.code == recent.code);
      if (match.isNotEmpty) {
        shownCodes.add(recent.code);
        // The catalogue copy, not the stored one: names get corrected.
        recentRows.add(match.first);
      }
    }
    if (recentRows.isEmpty) return matches;
    return <Object>[
      'Recently used',
      ...recentRows,
      'All species',
      for (final option in matches)
        if (!shownCodes.contains(option.code)) option,
    ];
  }

  Widget _rowFor(SpeciesChoice option) {
    final isSelected = option.code == widget.selected?.code;
    return Semantics(
      selected: isSelected,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(option),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          child: Row(
            children: [
              _Clip(text: option.code),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.commonName,
                      style: TextStyle(
                        fontFamily: Faces.book.first,
                        fontSize: Faces.body,
                        color: widget.colours.bone,
                      ),
                    ),
                    Text(
                      option.scientificName,
                      style: TextStyle(
                        fontFamily: Faces.book.first,
                        fontSize: Faces.supporting,
                        fontStyle: FontStyle.italic,
                        color: widget.colours.ash2,
                      ),
                    ),
                  ],
                ),
              ),
              if (option.isSign)
                Text(
                  'sign',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    color: widget.colours.ash3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The count.
///
/// A stepper rather than a keypad: the design's hint says "count them all,
/// including young", which is a request to count carefully, and a keypad that
/// offers ten digits as the primary interface invites the fastest answer rather
/// than the right one.
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.count,
    required this.colours,
    required this.onChanged,
    this.hint,
  });

  final int? count;
  final FieldColours colours;
  final ValueChanged<int?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'How many',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.label,
                color: colours.bone,
              ),
            ),
            const Spacer(),
            _StepButton(
              icon: Icons.remove,
              onTap: count == null || count! <= 1
                  ? null
                  : () => onChanged(count! - 1),
            ),
            SizedBox(
              width: 56,
              child: Text(
                count?.toString() ?? '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Faces.book.first,
                  fontSize: Faces.cardTitle,
                  color: count == null ? colours.ash3 : colours.bone,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: count == null
                  ? () => onChanged(1)
                  : () => onChanged(count! + 1),
            ),
            if (count != null)
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
        ),
        if (hint != null) ...[
          const SizedBox(height: Insets.xs),
          _Supporting(hint!, colours),
        ],
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

class _Chips extends StatelessWidget {
  const _Chips({
    required this.label,
    required this.values,
    required this.selected,
    required this.colours,
    required this.onChanged,
    this.optional = false,
    this.labelOf,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final FieldColours colours;
  final ValueChanged<String?> onChanged;
  final bool optional;
  final String Function(String)? labelOf;

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
        const SizedBox(height: Insets.sm),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            for (final value in values)
              _Chip(
                label: labelOf?.call(value) ?? _humanise(value),
                selected: selected == value,
                colours: colours,
                onTap: () => onChanged(selected == value ? null : value),
              ),
          ],
        ),
      ],
    );
  }

  /// `adult_male` reads as `Adult male`.
  ///
  /// The wire values are the contract's, not the interface's. A trainee does
  /// not know the contract has a field called age_sex_class.
  static String _humanise(String value) {
    final words = value.split('_');
    return words
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
    // A chip is a fill, never text. Measured, not assumed: an accent hue held
    // across both brightnesses does not hold as running text.
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

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.colours,
    this.hint,
    this.label,
    this.noteBody = false,
  });

  final TextEditingController controller;
  final FieldColours colours;
  final String? hint;
  final String? label;
  final bool noteBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.label,
              color: colours.bone,
            ),
          ),
          const SizedBox(height: Insets.sm),
        ],
        TextField(
          controller: controller,
          maxLines: noteBody ? 6 : 4,
          minLines: noteBody ? 4 : 3,
          style: TextStyle(
            fontFamily: Faces.book.first,
            // The design requires that a note be set at the size a sentence
            // deserves, so this is the largest type in the app by design.
            fontSize: noteBody ? Faces.noteBody : Faces.body,
            height: 1.45,
            color: colours.bone,
          ),
          cursorColor: colours.straw,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: noteBody ? Faces.noteBody : Faces.body,
              height: 1.45,
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
              borderSide: BorderSide(color: colours.bone),
            ),
          ),
        ),
      ],
    );
  }
}

/// A number the trainee types rather than counts.
///
/// Deliberately free text with a suffix rather than a stepper: distance and
/// hours are not small integers, and a stepper over hours would make the common
/// case of "about three" awkward to enter.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.unit,
    required this.value,
    required this.colours,
    required this.onChanged,
    this.allowsDecimals = false,
  });

  final String label;
  final String unit;
  final num? value;
  final FieldColours colours;
  final ValueChanged<num?> onChanged;
  final bool allowsDecimals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.label,
            color: colours.bone,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: value?.toString() ?? '',
                keyboardType: TextInputType.numberWithOptions(
                  decimal: allowsDecimals,
                ),
                onChanged: (text) => onChanged(
                  allowsDecimals
                      ? double.tryParse(text.trim())
                      : int.tryParse(text.trim()),
                ),
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.body,
                  color: colours.bone,
                ),
                cursorColor: colours.straw,
                decoration: InputDecoration(
                  suffixText: unit,
                  suffixStyle: TextStyle(color: colours.ash3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.values,
    required this.selected,
    required this.colours,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T? selected;
  final FieldColours colours;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.label,
            color: colours.bone,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Insets.md),
          decoration: BoxDecoration(
            color: colours.inset,
            borderRadius: BorderRadius.circular(Corners.control),
            border: Border.all(color: colours.rule),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selected,
              isExpanded: true,
              dropdownColor: colours.canopyRaised,
              hint: Text(
                '—',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.body,
                  color: colours.ash3,
                ),
              ),
              items: [
                for (final value in values)
                  DropdownMenuItem<T>(
                    value: value,
                    child: Text(
                      labelOf(value),
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.body,
                        color: colours.bone,
                      ),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.colours, required this.hint});

  final FieldColours colours;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colours.inset,
            borderRadius: BorderRadius.circular(Corners.control),
            border: Border.all(color: colours.rule),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_camera_outlined, color: colours.ash3),
              const SizedBox(height: Insets.xs),
              Text(
                'Photos',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  color: colours.ash3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.xs),
        _Supporting(hint, colours),
      ],
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.canSave,
    required this.saving,
    required this.reason,
    required this.colours,
    required this.onCancel,
    required this.onSave,
  });

  final bool canSave;
  final bool saving;
  final String? reason;
  final FieldColours colours;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.md,
        Insets.lg,
        Insets.lg,
      ),
      decoration: BoxDecoration(
        color: colours.canopy,
        border: Border(top: BorderSide(color: colours.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The reason saving is unavailable is stated, not implied by a grey
          // button. In a moving vehicle a disabled control is just a dead end.
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Text(
                reason!,
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  color: colours.ash2,
                ),
              ),
            ),
          Row(
            children: [
              TextButton(
                onPressed: saving ? null : onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                    color: colours.ash2,
                  ),
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: FilledButton(
                  onPressed: canSave && !saving ? onSave : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colours.bone,
                    foregroundColor: colours.canopy,
                    disabledBackgroundColor: colours.canopyRaised,
                    disabledForegroundColor: colours.ash3,
                    padding: const EdgeInsets.symmetric(vertical: Insets.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                    ),
                  ),
                  child: Text(
                    saving ? 'Saving' : 'Save to this walk',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'Saves on this phone straight away. Uploads on its own.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              color: colours.ash3,
            ),
          ),
        ],
      ),
    );
  }
}
