import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';

part 'sighting.freezed.dart';
part 'sighting.g.dart';

/// A sighting's review state.
///
/// `needsReview` is kept distinct from `pending` and is not a synonym for it:
/// `pending` means nobody has looked, `needsReview` means somebody competent
/// looked and was not willing to decide. Collapsing them loses the record of a
/// mentor's uncertainty, which is a thing the contract cares about enough to
/// have its own rule.
enum SightingStatus {
  @JsonValue('pending')
  pending,

  @JsonValue('verified')
  verified,

  @JsonValue('rejected')
  rejected,

  @JsonValue('needs_review')
  needsReview;

  /// Whether an identification must be present for a sighting in this state.
  ///
  /// This is the client-side expression of contract rule 21, and it exists
  /// because the rule cannot be expressed in the model itself: `speciesCode`
  /// is nullable so that a sighting recorded without an identification compiles
  /// at all, and the condition therefore has to be checked explicitly.
  bool get requiresIdentification => switch (this) {
    SightingStatus.verified => true,
    SightingStatus.pending ||
    SightingStatus.needsReview ||
    SightingStatus.rejected => false,
  };

  /// Whether a count must be present for a sighting in this state.
  ///
  /// An absent count is not a zero. A zero asserts the animal was looked for
  /// and there were none, which is a different statement from not having
  /// counted. Contract rule 18 draws the same line between `not_observed` and a
  /// zero.
  bool get requiresCount => requiresIdentification;
}

/// What the animal was doing.
///
/// The contract declares this an enum because a behaviour tally across a drive
/// is a training exercise in itself, and free text would not support it. It
/// does **not** enumerate the values, which is a gap in the contract rather
/// than a choice here. The values below are provisional and are what the client
/// offers; the wire values must be reconciled with the service before step 6
/// of the contract's delivery sequence, or a tally will silently under-count.
enum SightingBehaviour {
  @JsonValue('grazing')
  grazing,

  @JsonValue('moving')
  moving,

  @JsonValue('resting')
  resting,

  @JsonValue('feeding')
  feeding,

  @JsonValue('with_young')
  withYoung,

  @JsonValue('alert')
  alert,

  @JsonValue('unknown')
  unknown,
}

/// Who was seen, where separable.
///
/// Provisional for the same reason as [SightingBehaviour]: the contract requires
/// the field, to support a mentor judging whether a trainee separated a bull
/// from a cow, but does not enumerate its values.
enum AgeSexClass {
  @JsonValue('female')
  female,

  @JsonValue('male')
  male,

  @JsonValue('juvenile')
  juvenile,

  @JsonValue('adult_unknown')
  adultUnknown,

  @JsonValue('unknown')
  unknown,
}

/// A wildlife sighting, as the contract's logbook table describes it.
///
/// [speciesCode] and [count] are nullable. That is not a loosening of the
/// contract, it is the amendment recorded as rule 21: both are required only
/// when [status] is [SightingStatus.verified], and a trainee who saw something
/// they could not name records a sighting with neither. Forcing a guess at
/// capture trains a guess, and a logbook of confident wrong species is worth
/// less to a mentor than one of honest blanks.
///
/// [verifiedAt] is a timestamp and not a status. A sighting can be
/// [SightingStatus.rejected] and still carry a `verifiedAt`, because a decision
/// was made at a time. Collapsing the two loses the audit trail, which is the
/// one thing a disputed sighting most needs.
@freezed
abstract class WildlifeSighting with _$WildlifeSighting {
  const factory WildlifeSighting({
    required String id,
    required String contextCode,
    required String driveId,
    required SightingStatus status,

    /// The contract carries this as a GeoJSON `Point`, so it is written as one
    /// rather than as a flat longitude and latitude pair. The converter is
    /// named explicitly because `GeoPoint` is hand-written rather than
    /// generated, and json_serializable will not infer a codec for it.
    @GeoPointConverter() required GeoPoint location,
    required DateTime capturedAt,
    required DateTime recordedAt,
    required int revision,
    required String createdBy,
    String? speciesCode,
    int? count,
    double? locationAccuracyM,
    int? distanceM,
    int? bearingDeg,
    SightingBehaviour? behaviour,
    AgeSexClass? ageSexClass,
    String? notes,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? verificationNotes,
    String? recordedSpeciesCode,
    int? recordedCount,
    @Default(false) bool lateArrival,
  }) = _WildlifeSighting;

  const WildlifeSighting._();

  factory WildlifeSighting.fromJson(Map<String, dynamic> json) =>
      _$WildlifeSightingFromJson(json);

  /// Whether this sighting carries an identification, whatever its state.
  ///
  /// A note is a real record with a real pin; it renders in the same clipped
  /// tab as any other, dashed, with a `?` instead of a species code, because
  /// the identification genuinely is open.
  bool get hasIdentification => speciesCode != null;

  /// Whether anything has been corrected, so the original must be shown
  /// alongside the current value rather than the current value alone.
  bool get hasCorrection =>
      recordedSpeciesCode != null || recordedCount != null;

  /// Whether the record states what was seen rather than only that something
  /// was.
  ///
  /// The design requires that a note lead with what the trainee wrote, set in
  /// the serif, above everything else: their words are the record, not the
  /// animal they turned out to be looking at.
  bool get isNote => !hasIdentification && (notes?.trim().isNotEmpty ?? false);
}

/// Four uppercase letters, per the contract's logbook requirement for
/// `species_code`.
///
/// Returns `null` for a value the contract would not accept, rather than
/// throwing, because the caller is usually a form deciding whether to enable a
/// control and needs a reason rather than an exception.
String? validateSpeciesCode(String? code) {
  if (code == null) {
    return null;
  }
  final trimmed = code.trim();
  if (trimmed.length != 4) {
    return 'A species code is four characters.';
  }
  if (!RegExp(r'^[A-Z]{4}$').hasMatch(trimmed)) {
    return 'A species code is four uppercase letters.';
  }
  return null;
}
