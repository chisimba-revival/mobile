import 'dart:ui' show Color;

import 'package:field_log/design/tokens.dart';

/// What kind of record is being written.
///
/// This is the decision the field card asks first, and it is a consequence of
/// contract rule 21 rather than a preference of the interface. A trainee who
/// saw something and cannot name it has still observed something, and the only
/// way to record that honestly is to make the empty answer a first-class one
/// rather than a failure to fill in a required field.
enum CaptureMode {
  /// The trainee names the animal now.
  identified,

  /// The trainee writes what they saw and a mentor identifies it later.
  unnamed,
}

/// One direction, or another, of travel from the vehicle.
///
/// Recorded as whole degrees because a bearing to the nearest ten degrees is
/// more than the ground truth of a sighting made from a moving vehicle, and
/// storing more precision than the observation has is how a false confidence
/// gets into a record.
enum CompassPoint {
  north('N', 'North'),
  northEast('NE', 'North-east'),
  east('E', 'East'),
  southEast('SE', 'South-east'),
  south('S', 'South'),
  southWest('SW', 'South-west'),
  west('W', 'West'),
  northWest('NW', 'North-west');

  const CompassPoint(this.wire, this.label);

  /// The value the contract carries in `bearing_deg`. The contract stores a
  /// whole number of degrees rather than a compass point, so this is the
  /// conversion and not the stored form.
  final String wire;

  /// What the interface says.
  final String label;

  /// The bearing this point stands for.
  int get degrees => switch (this) {
    north => 0,
    northEast => 45,
    east => 90,
    southEast => 135,
    south => 180,
    southWest => 225,
    west => 270,
    northWest => 315,
  };

  /// The nearest point to [degrees].
  ///
  /// Rounding rather than flooring, so a bearing of 340 reads as north-west
  /// rather than west. Which of the two is "right" depends on nothing a user
  /// could tell, so the answer that matches ordinary speech wins.
  static CompassPoint nearestTo(int degrees) {
    final wrapped = ((degrees % 360) + 360) % 360;
    return CompassPoint.values[((wrapped + 22) ~/ 45) % 8];
  }

  /// The point [degrees] falls nearest to, if it is one of ours.
  static CompassPoint? fromDegrees(int degrees) {
    for (final point in CompassPoint.values) {
      if (point.degrees == (((degrees % 360) + 360) % 360)) {
        return point;
      }
    }
    return null;
  }
}

/// The draft being written on the field card.
///
/// Immutable, so that "what did I type before I switched modes" is a question
/// with an answer rather than a thing to be reasoned about while the keyboard
/// is up. Every editor returns a new draft.
class FieldDraft {
  const FieldDraft({
    this.mode = CaptureMode.identified,
    this.speciesCode,
    this.count,
    this.behaviour,
    this.ageSexClass,
    this.notes = '',
    this.distanceMetres,
    this.bearingDegrees,
    this.lessonsLearned = '',
    this.hoursOnThisWalk,
    this.rifleRole = 'second',
    this.capturedAt,
    this.recordedAt,
  });

  final CaptureMode mode;
  final String? speciesCode;
  final int? count;
  final String? behaviour;
  final String? ageSexClass;
  final String notes;
  final int? distanceMetres;
  final int? bearingDegrees;
  final String lessonsLearned;
  final double? hoursOnThisWalk;
  final String rifleRole;
  final DateTime? capturedAt;
  final DateTime? recordedAt;

  bool get isUnnamed => mode == CaptureMode.unnamed;

  /// Whether this draft can be saved.
  ///
  /// The rule is deliberately mode-dependent, and it is the whole content of
  /// contract rule 21 as far as the interface is concerned. In "I identified
  /// it" a species is required, because the trainee has said they know what it
  /// is. In "I am not sure" a species is forbidden and some words are
  /// required, because a record with neither is not an observation.
  ///
  /// Count is required in neither mode. A count of one animal is meaningful;
  /// no count at all is meaningful too, and an absent count is not a zero.
  bool get canSave {
    if (isUnnamed) {
      return notes.trim().isNotEmpty;
    }
    if (speciesCode == null || speciesCode!.isEmpty) {
      return false;
    }
    return true;
  }

  /// Why saving is not offered, phrased for the person reading it.
  ///
  /// Returns null when the draft can be saved. A form that simply greys out a
  /// button leaves the reader to guess what is missing, which in a moving
  /// vehicle means they give up and record nothing.
  String? get cannotSaveReason {
    if (canSave) {
      return null;
    }
    if (isUnnamed) {
      return 'Describe what you saw. An empty card is not an observation.';
    }
    return 'Choose a species, or switch to "I am not sure" and write what you saw.';
  }

  FieldDraft copyWith({
    CaptureMode? mode,
    String? speciesCode,
    int? count,
    String? behaviour,
    String? ageSexClass,
    String? notes,
    int? distanceMetres,
    int? bearingDegrees,
    String? lessonsLearned,
    double? hoursOnThisWalk,
    String? rifleRole,
    DateTime? capturedAt,
    DateTime? recordedAt,
    bool clearSpecies = false,
    bool clearCount = false,
    bool clearBehaviour = false,
    bool clearAgeSex = false,
    bool clearDistance = false,
    bool clearBearing = false,
    bool clearHours = false,
  }) {
    return FieldDraft(
      mode: mode ?? this.mode,
      speciesCode: clearSpecies ? null : (speciesCode ?? this.speciesCode),
      count: clearCount ? null : (count ?? this.count),
      behaviour: clearBehaviour ? null : (behaviour ?? this.behaviour),
      ageSexClass: clearAgeSex ? null : (ageSexClass ?? this.ageSexClass),
      notes: notes ?? this.notes,
      distanceMetres: clearDistance
          ? null
          : (distanceMetres ?? this.distanceMetres),
      bearingDegrees: clearBearing
          ? null
          : (bearingDegrees ?? this.bearingDegrees),
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
      hoursOnThisWalk: clearHours
          ? null
          : (hoursOnThisWalk ?? this.hoursOnThisWalk),
      rifleRole: rifleRole ?? this.rifleRole,
      capturedAt: capturedAt ?? this.capturedAt,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  /// Switching into "I am not sure" keeps what was already typed.
  ///
  /// The design says plainly that nothing written is lost, and the case that
  /// matters is a trainee who starts to name an animal, gets unsure, and
  /// switches. Throwing away a half-typed species would be a small betrayal of
  /// the promise on the button.
  FieldDraft switchTo(CaptureMode next) {
    if (next == mode) {
      return this;
    }
    return copyWith(mode: next);
  }

  @override
  bool operator ==(Object other) =>
      other is FieldDraft &&
      other.mode == mode &&
      other.speciesCode == speciesCode &&
      other.count == count &&
      other.behaviour == behaviour &&
      other.ageSexClass == ageSexClass &&
      other.notes == notes &&
      other.distanceMetres == distanceMetres &&
      other.bearingDegrees == bearingDegrees &&
      other.lessonsLearned == lessonsLearned &&
      other.hoursOnThisWalk == hoursOnThisWalk &&
      other.rifleRole == rifleRole;

  @override
  int get hashCode => Object.hash(
    mode,
    speciesCode,
    count,
    behaviour,
    ageSexClass,
    notes,
    distanceMetres,
    bearingDegrees,
    lessonsLearned,
    hoursOnThisWalk,
    rifleRole,
  );
}

/// A species the trainee can pick.
///
/// A plain value rather than a database row, because the picker has to work
/// from cached reference data and the point of caching it aggressively is that
/// it is available with no signal.
class SpeciesChoice {
  const SpeciesChoice({
    required this.code,
    required this.commonName,
    required this.scientificName,
    this.isSign = false,
  });

  /// Four uppercase letters per the contract. The design's own reference data
  /// contains HIPPO at five letters and VOX at three, so this is recorded but
  /// not enforced: rejecting a code the service may legitimately send would
  /// cost a record, and accepting an odd one costs nothing.
  final String code;

  final String commonName;
  final String scientificName;

  /// True for a record that exists because something was found or heard rather
  /// than seen: spoor, scat, a call.
  ///
  /// These are marked apart because a count is a different claim for them. A
  /// scat is one scat; "one animal" would be an inference.
  final bool isSign;

  /// Whether [query] matches this entry.
  ///
  /// Matches the common name, the scientific name or the code, so the trainee
  /// can type either spelling. The design's hint says as much.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    return commonName.toLowerCase().contains(q) ||
        scientificName.toLowerCase().contains(q) ||
        code.toLowerCase().contains(q);
  }

  @override
  bool operator ==(Object other) =>
      other is SpeciesChoice && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// The reference values the field card offers as chips.
class ReferenceValues {
  const ReferenceValues({
    this.behaviours = const <String>[],
    this.ageSexClasses = const <String>[],
  });

  final List<String> behaviours;
  final List<String> ageSexClasses;
}

/// The accent a chip takes when it is the one selected.
///
/// Chips are fills, never text. This was measured rather than assumed: holding
/// an accent hue across both brightnesses holds for surfaces and ink, but straw
/// and moss fall to 1.89:1 and 2.49:1 as running text on the light surface in
/// midday, so a selected chip is a filled shape and its label is drawn in
/// whichever ink [FieldColours.inkOn] measures as more legible.
Color accentForSelection(bool selected, FieldColours c) =>
    selected ? c.straw : c.canopyRaised;
