/// Plain summaries of the hours and requirements an outing has accumulated.
///
/// These types are deliberately plain and deliberately not sums: hours are
/// kept apart by role, and requirements are stated as counts known and counts
/// remaining to discuss. Nothing here is a percentage, a score, a grade or a
/// bar, because readiness is never a verdict — it is a description of what is
/// known. See `tally_screen.dart` and the design rules it is held to.
library;

/// Hours walked under one rifle role, kept separate from every other role.
///
/// The value is never added into a single number elsewhere: qualifying hours
/// are counted per role, so a guide who walked both first and second rifle has
/// two counts, not one.
class HoursCount {
  const HoursCount({
    required this.role,
    required this.label,
    required this.note,
    required this.value,
  });

  /// The stable role key: `first`, `second`, or `none`.
  final String role;

  /// The human label, e.g. "First rifle hours".
  final String label;

  /// A short note explaining what the count means.
  final String note;

  /// The hours walked under this role.
  final double value;
}

/// One competency stated as a count: what is known, and what is still needed.
class Requirement {
  const Requirement({
    required this.title,
    required this.have,
    required this.need,
    this.detail = '',
  });

  /// The competency or requirement name.
  final String title;

  /// How much has been observed so far.
  final int have;

  /// How much is required for the competency.
  final int need;

  /// An optional sentence of context.
  final String detail;

  /// Whether the count has reached the requirement. Not a pass — a met
  /// requirement is still only a count that has caught up.
  bool get isMet => have >= need;

  /// The count as a fraction of two whole numbers, e.g. "3 of 5".
  String get countLabel => '$have of $need';

  /// What remains to discuss, e.g. "2 to go". Only meaningful when unmet.
  String get remainingLabel => '${need - have} to go';
}

/// One trail log folded into the progress summary.
class TrailEntry {
  const TrailEntry({
    required this.localId,
    required this.startedAt,
    required this.rifleRole,
    required this.hours,
    required this.fromWaypoints,
    required this.disagrees,
  });

  final String localId;
  final DateTime? startedAt;
  final String rifleRole;

  /// The hours used for this entry: the logged value when present, otherwise
  /// the hours derived from waypoints.
  final double hours;

  /// Whether [hours] came from waypoint timestamps rather than a logged value.
  final bool fromWaypoints;

  /// Whether a logged value and a waypoint-derived value both exist and differ.
  final bool disagrees;
}

/// The hours and requirements an outing has accumulated on foot.
class TrailProgress {
  const TrailProgress({
    required this.hours,
    required this.requirements,
    this.entries = const [],
    this.totalHours = 0,
    this.hoursReconciled = false,
    this.walkLengthKm,
    this.guideRole,
    this.rifleDetails,
    this.status,
    this.description,
    this.lessonsLearned,
    this.weather,
    this.endedAt,
  });

  final List<HoursCount> hours;
  final List<Requirement> requirements;
  final List<TrailEntry> entries;
  final double totalHours;

  /// Whether any walk's logged hours disagree with the hours its waypoints
  /// imply, so the two figures still need reconciling before submitting.
  final bool hoursReconciled;

  /// The latest walk's distance, for the map's progress card. Null when no
  /// walk has a recorded length.
  final double? walkLengthKm;

  /// The latest walk's guide role, if it named one.
  final String? guideRole;

  /// The latest walk's rifle details, if it recorded any.
  final String? rifleDetails;

  /// The latest walk's status, if it has one.
  final String? status;

  /// The latest walk's description, if it has one.
  final String? description;

  /// The latest walk's lessons learned, if any were written down.
  final String? lessonsLearned;

  /// The latest walk's weather, if it was recorded.
  final String? weather;

  /// When the latest walk ended, if it has ended.
  final DateTime? endedAt;

  /// Whether any walk at all is recorded.
  bool get hasTrail => entries.isNotEmpty;

  /// The id of the most recent walk, for opening the record it came from.
  String? get latestLocalId => entries.isEmpty ? null : entries.last.localId;

  static const empty = TrailProgress(hours: [], requirements: []);
}

/// One drive folded into the progress summary.
class DriveEntry {
  const DriveEntry({
    required this.localId,
    required this.startedAt,
    required this.durationHours,
  });

  final String localId;
  final DateTime? startedAt;
  final double? durationHours;
}

/// The drives an outing has accumulated, and the latest drive's detail.
class DriveProgress {
  const DriveProgress({
    this.count = 0,
    this.totalHours = 0,
    this.entries = const [],
    this.daylightHours,
    this.nightHours,
    this.offRoadSeconds,
    this.guestCount,
    this.vehicleId,
    this.inspectionOilOk,
    this.inspectionWaterOk,
    this.inspectionTyresOk,
    this.offTrackUsed,
    this.weather = '',
    this.notes = '',
  });

  final int count;
  final double totalHours;
  final List<DriveEntry> entries;
  final double? daylightHours;
  final double? nightHours;
  final int? offRoadSeconds;
  final int? guestCount;
  final String? vehicleId;
  final bool? inspectionOilOk;
  final bool? inspectionWaterOk;
  final bool? inspectionTyresOk;
  final bool? offTrackUsed;
  final String weather;
  final String notes;

  /// The id of the most recent drive, for opening the record it came from.
  String? get latestLocalId => entries.isEmpty ? null : entries.last.localId;

  /// The hours all drives on this device add up to. A drive left open counts
  /// nothing until it is closed, so this is a sum of closed durations only.
  double get durationHours => totalHours;

  static const empty = DriveProgress();
}

/// Everything an outing has to show for itself, on foot and by vehicle.
class OutingProgress {
  const OutingProgress({this.trail, this.drive});

  final TrailProgress? trail;
  final DriveProgress? drive;

  /// Whether the outing has any walk recorded at all.
  bool get hasTrail => trail != null;

  /// Hours on foot, kept beside the hours behind the wheel, never mixed in.
  double get trailHours => trail?.totalHours ?? 0;

  /// Whether the outing has any drive recorded at all, closed or still open.
  bool get hasDrive => drive != null;

  /// Hours behind the wheel, kept beside the hours on foot rather than mixed in.
  double get driveHours => drive?.totalHours ?? 0;

  static const empty = OutingProgress();
}

/// Formats an hours value without inventing precision it does not have.
///
/// Trailing zeros are trimmed so `14.0` reads "14 h" and `9.25` reads
/// "9.25 h". The unit is always " h", never ":00" or a clock.
String formatHours(double hours) {
  final rounded = (hours * 100).round() / 100;
  final trimmed = rounded
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '');
  return '$trimmed h';
}
