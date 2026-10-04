import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:flutter/material.dart';

/// One record, read.
///
/// A plain value rather than a row from the store, so this screen can be built
/// and tested without a database, and so the reading of a record is separated
/// from the storage of it.
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

  /// The service's word for the state, not the Dart identifier.
  final String status;
  final DateTime capturedAt;
  final DateTime recordedAt;

  /// Non-nullable because a caller has to decide what an absent reading means.
  /// The convention across this app is [double.infinity], because zero would
  /// claim the position is exact.
  final double accuracyMetres;

  final int? distanceMetres;
  final int? bearingDegrees;
  final String notes;
  final int? count;
  final String? speciesCode;
  final String? behaviour;
  final String? ageSexClass;

  /// What the trainee originally wrote, kept because rule 15 requires it.
  final String? recordedSpeciesCode;
  final int? recordedCount;
  final String? correctionReason;
  final String? verifiedBy;
  final String? verificationNotes;
  final bool lateArrival;

  /// Falls back to a description of a record that has no species rather than to
  /// a blank line.
  String get displayName =>
      speciesCode == null ? 'Not yet identified' : commonName;
}

/// The record, opened.
///
/// This screen never offers to edit the position. A correction is made by adding
/// a note, because a record that can be quietly moved is not a record.
///
/// The layout is deliberate about order. It opens on what the record *is* —
/// which animal, how many, what state — because that is the question somebody
/// opens a record to answer. The remaining facts sit behind a single disclosure
/// rather than in a flat column of ten rows, because a screen that shows
/// everything at once on a device held one-handed in a vehicle shows nothing in
/// particular. Adding information is one action, not a form.
class PinDetailScreen extends StatefulWidget {
  const PinDetailScreen({super.key, required this.sighting, this.onAddDetail});

  final SightingSummary sighting;

  /// Called when the reader adds something. The screen shows it immediately and
  /// records it locally; sending it is somebody else's problem, and pretending
  /// otherwise would be a lie on a screen that looks like a record.
  final void Function(String kind, String value)? onAddDetail;

  @override
  State<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends State<PinDetailScreen> {
  /// What has been added on this device but not yet sent. Held here so the
  /// screen never has to own a database.
  final List<_Added> _added = [];
  bool _showAll = false;

  void _add(String kind, String value) {
    setState(() => _added.add(_Added(kind, value)));
    widget.onAddDetail?.call(kind, value);
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final text = Theme.of(context).textTheme;
    final s = widget.sighting;

    return Scaffold(
      backgroundColor: colours.canopy,
      body: SafeArea(
        child: Column(
          children: [
            _Header(sighting: s, colours: colours, text: text),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  0,
                  Insets.lg,
                  Insets.xl,
                ),
                children: [
                  if (_isCorrected(s)) ...[
                    _Correction(sighting: s, colours: colours, text: text),
                    const SizedBox(height: Insets.md),
                  ],
                  _Headline(sighting: s, colours: colours, text: text),
                  const SizedBox(height: Insets.lg),
                  _Disclosure(
                    label: 'All details',
                    open: _showAll,
                    onToggle: () => setState(() => _showAll = !_showAll),
                    child: _AllDetails(
                      sighting: s,
                      added: _added,
                      colours: colours,
                      text: text,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  _AddedList(added: _added, colours: colours, text: text),
                ],
              ),
            ),
            _Dock(
              colours: colours,
              text: text,
              onAdd: () => _openAddSheet(context, colours),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isCorrected(SightingSummary s) =>
      (s.recordedCount != null && s.recordedCount != s.count) ||
      (s.recordedSpeciesCode != null && s.recordedSpeciesCode != s.speciesCode);

  Future<void> _openAddSheet(BuildContext context, FieldColours colours) async {
    // A sheet rather than a screen, because this is a small interruption to a
    // record somebody is already reading, not a change of place.
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      // Without this the sheet is capped to a fraction of the screen and its
      // lower half — the age and sex chips, and the Add button itself — is
      // clipped away on a normal phone. A sheet whose button you cannot reach
      // is not a sheet.
      isScrollControlled: true,
      backgroundColor: colours.canopyRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Corners.sheet),
        ),
      ),
      builder: (sheetContext) => _AddSheet(colours: colours),
    );
    if (choice == null || !mounted) {
      return;
    }
    _add(choice.kind, choice.value);
  }
}

/// Something added on this device and not yet sent.
class _Added {
  const _Added(this.kind, this.value);

  final String kind;
  final String value;
}

/// What the sheet offers.
class _AddChoice {
  const _AddChoice(this.kind, this.value);

  final String kind;
  final String value;
}

/// The three things a mentor or reader actually adds to a record.
///
/// Deliberately short. A sheet offering every field of the contract would be a
/// form wearing a sheet's clothes, and the fields that matter most here are the
/// ones already on the card.
class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.colours});

  final FieldColours colours;

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _note = TextEditingController();
  String? _behaviour;
  String? _ageSex;

  static const _behaviours = [
    'feeding',
    'resting',
    'moving',
    'hunting',
    'drinking',
    'social',
    'breeding',
  ];
  static const _ageSexes = [
    'adult_male',
    'adult_female',
    'subadult_male',
    'subadult_female',
    'juvenile',
    'calf_cub',
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String? get _problem {
    if (_note.text.trim().isEmpty && _behaviour == null && _ageSex == null) {
      return 'Add something, or close this without saving.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colours = widget.colours;

    return SingleChildScrollView(
      // The keyboard covers the chips otherwise, and the button with them.
      padding: EdgeInsets.only(
        left: Insets.lg,
        right: Insets.lg,
        top: Insets.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Insets.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to this record',
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.cardTitle,
              color: colours.bone,
            ),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            'What you add is kept with the record, and goes up when there is '
            'signal.',
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              height: 1.4,
              color: colours.ash2,
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Label(text: 'A note', colours: colours),
          const SizedBox(height: Insets.xs),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 2,
            autofocus: true,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.body,
              color: colours.bone,
            ),
            cursorColor: colours.bone,
            decoration: InputDecoration(
              filled: true,
              fillColor: colours.canopy,
              hintText: 'What did you see that changes this record?',
              hintStyle: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.body,
                color: colours.ash3,
              ),
              contentPadding: const EdgeInsets.all(Insets.md),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Corners.control),
                borderSide: BorderSide(color: colours.rule),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Corners.control),
                borderSide: BorderSide(color: colours.bone, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.lg),
          _Label(text: 'Behaviour, if you saw it', colours: colours),
          const SizedBox(height: Insets.sm),
          _Wrap(
            options: _behaviours,
            selected: _behaviour,
            colours: colours,
            onPick: (value) =>
                setState(() => _behaviour = _behaviour == value ? null : value),
          ),
          const SizedBox(height: Insets.lg),
          _Label(text: 'Age and sex, if you can tell', colours: colours),
          const SizedBox(height: Insets.sm),
          _Wrap(
            options: _ageSexes,
            selected: _ageSex,
            colours: colours,
            onPick: (value) =>
                setState(() => _ageSex = _ageSex == value ? null : value),
          ),
          if (_problem != null) ...[
            const SizedBox(height: Insets.md),
            Text(
              _problem!,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                color: colours.ash3,
              ),
            ),
          ],
          const SizedBox(height: Insets.xl),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _problem == null
                  ? () {
                      // One action, one addition. A record gains a thing rather
                      // than being rewritten, because rule 6 forbids discarding
                      // what the trainee wrote.
                      final note = _note.text.trim();
                      if (note.isNotEmpty) {
                        Navigator.of(context).pop(_AddChoice('note', note));
                      } else if (_behaviour != null) {
                        Navigator.of(context)
                            .pop(_AddChoice('behaviour', _behaviour!));
                      } else if (_ageSex != null) {
                        Navigator.of(context)
                            .pop(_AddChoice('age_sex', _ageSex!));
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: colours.bone,
                foregroundColor: colours.canopy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Corners.control),
                ),
              ),
              child: Text(
                'Add',
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
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.colours});

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Faces.ui.first,
        fontSize: Faces.stamp,
        color: colours.ash2,
      ),
    );
  }
}

/// Chips for a small closed set of values.
class _Wrap extends StatelessWidget {
  const _Wrap({
    required this.options,
    required this.selected,
    required this.colours,
    required this.onPick,
  });

  final List<String> options;
  final String? selected;
  final FieldColours colours;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        for (final option in options)
          _Chip(
            label: _humanise(option),
            selected: option == selected,
            colours: colours,
            onTap: () => onPick(option),
          ),
      ],
    );
  }

  /// The wire values are the contract's, not the interface's. A trainee does
  /// not know the contract has a field called `age_sex_class`.
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
    // Chips are fills, never text. Straw and moss fall below a legible contrast
    // as running text on the light surface in midday, so a selected chip is a
    // filled shape and its label is drawn in whichever ink measures better.
    final fill = selected ? colours.straw : colours.canopyRaised;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.chip),
        child: Container(
          // A touch target that a fingertip in a moving vehicle can hit.
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Corners.chip),
            border: Border.all(color: selected ? colours.straw : colours.rule),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.label,
              color: colours.inkOn(fill),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the record is: which animal, how many, what state.
///
/// This is the part that answers the question somebody opened the record to
/// ask, so it is the part that is always on screen.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.sighting,
    required this.colours,
    required this.text,
  });

  final SightingSummary sighting;
  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final s = sighting;
    final accent = _accentFor(s.visual.state, colours);
    final count = s.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              // A record with no count is not a record of zero animals. Rule 18
              // keeps "not counted" from being read as none.
              count == null ? '—' : '$count',
              style: TextStyle(
                fontFamily: Faces.book.first,
                fontSize: 40,
                height: 1,
                color: colours.bone,
              ),
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                count == null
                    ? 'number not counted'
                    : count == 1
                    ? 'animal'
                    : 'animals',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  color: colours.ash2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.sm),
        // The state is a word first. An accent alone cannot be read by everyone,
        // and in sunlight it is the first thing lost.
        _StateLine(
          state: s.visual.state,
          accent: accent,
          colours: colours,
          text: text,
        ),
        const SizedBox(height: Insets.xs),
        Text(
          // The spoken line is the same sentence the pin would read out, so the
          // card and the map cannot disagree about what a record is.
          s.visual.spoken,
          style: TextStyle(
            fontFamily: Faces.book.first,
            fontSize: Faces.body,
            height: 1.45,
            color: colours.ash1,
          ),
        ),
      ],
    );
  }
}

class _StateLine extends StatelessWidget {
  const _StateLine({
    required this.state,
    required this.accent,
    required this.colours,
    required this.text,
  });

  final PinState state;
  final Color accent;
  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      PinState.verified => 'Verified',
      PinState.corrected => 'Corrected',
      PinState.deleted => 'Deleted',
      PinState.needsReview => 'Awaiting a decision',
      PinState.queued => 'Waiting to send',
      PinState.unverified => 'Awaiting review',
    };
    return Row(
      children: [
        // A shape as well as a colour, so the state is legible without hue.
        Icon(_iconFor(state), size: 16, color: accent),
        const SizedBox(width: Insets.xs),
        Text(
          label,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.label,
            fontWeight: FontWeight.w600,
            color: colours.bone,
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(PinState state) => switch (state) {
    PinState.verified => Icons.check_circle_outline,
    PinState.corrected => Icons.edit_outlined,
    PinState.deleted => Icons.delete_outline,
    PinState.needsReview => Icons.hourglass_empty,
    PinState.queued => Icons.schedule,
    PinState.unverified => Icons.radio_button_unchecked,
  };
}

/// The facts, revealed on request.
class _AllDetails extends StatelessWidget {
  const _AllDetails({
    required this.sighting,
    required this.added,
    required this.colours,
    required this.text,
  });

  final SightingSummary sighting;
  final List<_Added> added;
  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final s = sighting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          label: 'Species',
          value: s.speciesCode == null
              ? 'Recorded in your own words instead'
              : s.commonName,
          detail: s.speciesCode == null
              ? null
              : '${s.scientificName} · ${s.speciesCode}',
          colours: colours,
          text: text,
        ),
        _Field(
          label: 'Behaviour',
          value: s.behaviour == null ? 'Not recorded' : _humanise(s.behaviour!),
          colours: colours,
          text: text,
        ),
        _Field(
          label: 'Age and sex',
          value: s.ageSexClass == null
              ? 'Not recorded'
              : _humanise(s.ageSexClass!),
          colours: colours,
          text: text,
        ),
        _Field(
          label: 'Where you were',
          value: _whereYouWere(),
          detail: _accuracy(),
          colours: colours,
          text: text,
        ),
        _Field(
          label: 'Captured',
          value: _clock(s.capturedAt),
          colours: colours,
          text: text,
        ),
        _Field(
          label: 'Recorded',
          value: _clock(s.recordedAt),
          detail: s.lateArrival ? 'Recorded after it happened' : null,
          colours: colours,
          text: text,
        ),
        if (s.notes.isNotEmpty)
          _Field(
            label: 'Your words',
            value: s.notes,
            colours: colours,
            text: text,
          ),
        if (s.verificationNotes != null)
          _Field(
            label: 'Mentor note',
            value: s.verificationNotes!,
            detail: s.verifiedBy == null ? null : 'By ${s.verifiedBy}',
            colours: colours,
            text: text,
          ),
      ],
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
    return parts.isEmpty ? 'Approximate position only' : parts.join(' · ');
  }

  String _accuracy() {
    final metres = sighting.accuracyMetres;
    if (!metres.isFinite) {
      return 'Accuracy not recorded';
    }
    return 'Position accuracy ±${metres.round()} m';
  }
}

/// The disclosure itself.
///
/// A control with a word on it rather than a chevron alone, because a chevron
/// in the corner of a phone screen is not an invitation anybody reads.
class _Disclosure extends StatelessWidget {
  const _Disclosure({
    required this.label,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final String label;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(Corners.control),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.md,
                vertical: Insets.md,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: colours.rule),
                borderRadius: BorderRadius.circular(Corners.control),
              ),
              child: Row(
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
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: colours.ash2,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open) ...[const SizedBox(height: Insets.lg), child],
      ],
    );
  }
}

/// What has been added here and not yet sent.
///
/// Shown as a list with its own heading rather than folded into the record,
/// because something added and something recorded are different facts and the
/// difference matters while the first is still on the phone.
class _AddedList extends StatelessWidget {
  const _AddedList({
    required this.added,
    required this.colours,
    required this.text,
  });

  final List<_Added> added;
  final FieldColours colours;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    if (added.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        border: Border.all(color: colours.rule),
        borderRadius: BorderRadius.circular(Corners.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Added on this phone',
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.stamp,
              color: colours.ash2,
            ),
          ),
          const SizedBox(height: Insets.xs),
          for (final item in added)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.xs),
              child: Text(
                '${_label(item.kind)}: ${item.value}',
                style: TextStyle(
                  fontFamily: Faces.book.first,
                  fontSize: Faces.supporting,
                  height: 1.35,
                  color: colours.bone,
                ),
              ),
            ),
          const SizedBox(height: Insets.xs),
          Text(
            'Goes up when there is signal.',
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.stamp,
              color: colours.ash3,
            ),
          ),
        ],
      ),
    );
  }

  static String _label(String kind) => switch (kind) {
    'note' => 'Note',
    'behaviour' => 'Behaviour',
    'age_sex' => 'Age and sex',
    _ => kind,
  };
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.md,
        Insets.sm,
        Insets.md,
      ),
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
                  'Sight · ${_clock(sighting.capturedAt)}',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    color: colours.ash2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sighting.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Faces.book.first,
                    fontSize: Faces.cardTitle,
                    height: 1.2,
                    color: colours.bone,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close, color: colours.ash1),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

/// The four-letter clip, the design's shorthand for a species code.
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
    return Semantics(
      label: label == '···' ? 'No species recorded' : 'Species $label',
      excludeSemantics: true,
      child: Container(
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
      ),
    );
  }
}

/// The correction, permanently at the top.
///
/// The original is shown next to the corrected value, permanently. Rule 15
/// requires it, and a trainee can only learn from a correction if they can see
/// what was changed and why.
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
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        border: Border.all(color: colours.dust),
        borderRadius: BorderRadius.circular(Corners.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // A word and an icon, because a dust-coloured border alone is not
              // an announcement.
              Icon(Icons.edit_outlined, size: 16, color: colours.dust),
              const SizedBox(width: Insets.xs),
              Text(
                'Corrected',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.label,
                  fontWeight: FontWeight.w600,
                  color: colours.dust,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            changes.join(' · '),
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.body,
              color: colours.bone,
            ),
          ),
          if (sighting.correctionReason != null) ...[
            const SizedBox(height: Insets.xs),
            Text(
              sighting.correctionReason!,
              style: TextStyle(
                fontFamily: Faces.book.first,
                fontSize: Faces.supporting,
                height: 1.4,
                color: colours.ash2,
              ),
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
          Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.stamp,
              color: colours.ash2,
            ),
          ),
          const SizedBox(height: 2),
          // A long note wraps rather than being cut. A mentor's note that runs
          // past the screen edge is a note nobody reads.
          Text(
            value,
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.body,
              height: 1.45,
              color: colours.bone,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                color: colours.ash2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.colours, required this.text, required this.onAdd});

  final FieldColours colours;
  final TextTheme text;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: colours.bone,
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: colours.ruleStrong),
              ),
              child: const Text('Add to this record'),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: colours.bone,
                foregroundColor: colours.canopy,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The accent follows the pin's state, so a card header and the map pin for the
/// same record always read as the same kind of thing.
Color _accentFor(PinState state, FieldColours c) => switch (state) {
  PinState.verified => c.moss,
  PinState.corrected => c.dust,
  PinState.deleted => c.ash3,
  PinState.queued || PinState.needsReview || PinState.unverified => c.straw,
};

/// The wire values are the contract's, not the interface's. A trainee does not
/// know the contract has a field called `age_sex_class`, so `adult_female` is
/// shown as "Adult female" everywhere a person reads it.
/// Only the first word is capitalised, so `adult_female` reads "Adult female"
/// and not "Adult Female". These are categories a person picks from a list, and
/// a list of Title Case words reads as a table of headings rather than options.
String _humanise(String wire) {
  final parts = wire.split('_');
  return [
    if (parts.isNotEmpty && parts.first.isNotEmpty)
      parts.first[0].toUpperCase() + parts.first.substring(1),
    // Every later word stays as the contract wrote it, so adult_female reads
    // "Adult female" rather than "Adult Female".
    ...parts.skip(1),
  ].join(' ');
}

/// A timestamp as the day and the clock, and nothing else.
///
/// Capture time and record time are separate facts, so this serves both and
/// neither stands in for the other.
String _clock(DateTime at) =>
    '${at.toIso8601String().substring(0, 10)} '
    '${at.toIso8601String().substring(11, 16)}';

const _cardinals = <int, String>{
  0: 'north',
  45: 'north-east',
  90: 'east',
  135: 'south-east',
  180: 'south',
  225: 'south-west',
  270: 'west',
  315: 'north-west',
};

String _compass(int degrees) {
  final index = (((degrees % 360) + 22) ~/ 45) % 8;
  final name = _cardinals.values.elementAt(index);
  return 'bearing $degrees° ($name)';
}
