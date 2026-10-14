import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:field_log/progress/progress_summary.dart';

/// Trail and drive progress together, for the map's card.
///
/// The database is the input, never the service: the summary has to describe
/// what this device actually holds, in the state it holds it, whether or not it
/// has reached the service yet. A walk recorded offline is still a walk.
class ProgressLoader {
  ProgressLoader(this.database);

  final FieldLogDatabase database;

  /// Reads walks and drives out of the database and folds them into the
  /// summaries the map's progress card and the tally screen both read.
  ///
  /// Trail hours are reconciled rather than trusted from one source. Where a
  /// walk has at least two timestamped waypoints, the time between them is the
  /// time actually walked — the phone watched it happen — and the hand-entered
  /// hoursWalked is used only when there are fewer than two waypoints. When
  /// both exist and disagree, the summary is flagged instead of one being
  /// silently preferred, because only the trainee can say which is right.
  Future<OutingProgress> load({List<Competency>? competencies}) async {
    final trail = await loadTrail(competencies: competencies);
    final drive = await loadDrive();
    return OutingProgress(trail: trail, drive: drive);
  }

  /// Every walk's hours, split by rifle role, plus the latest walk's details.
  Future<TrailProgress> loadTrail({List<Competency>? competencies}) async {
    final logs =
        await (database.select(database.trailLogs)
              ..where((t) => t.isTombstone.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
            .get();

    final hoursByRole = <String, double>{};
    final entries = <TrailEntry>[];
    var totalHours = 0.0;
    var reconciled = false;

    for (final log in logs) {
      final points =
          await (database.select(database.trailWaypoints)
                ..where((t) => t.trailLogId.equals(log.localId))
                ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
              .get();

      final gap = _gapHours(points);
      final logged = log.hoursWalked;
      final fromWaypoints = logged == null && gap != null;
      final hours = logged ?? gap ?? 0;
      final disagrees =
          logged != null && gap != null && (logged - gap).abs() > 0.01;
      if (disagrees) reconciled = true;

      final role = log.rifleRole ?? 'none';
      hoursByRole[role] = (hoursByRole[role] ?? 0) + hours;
      totalHours += hours;
      entries.add(
        TrailEntry(
          localId: log.localId,
          startedAt: log.startedAt,
          rifleRole: role,
          hours: hours,
          fromWaypoints: fromWaypoints,
          disagrees: disagrees,
        ),
      );
    }

    // The most recent walk, by the same ordering the list is read in.
    final latest = logs.isEmpty ? null : logs.first;

    return TrailProgress(
      hours: _hoursList(hoursByRole),
      requirements: buildRequirements(competencies ?? const <Competency>[]),
      entries: entries,
      totalHours: totalHours,
      hoursReconciled: reconciled,
      walkLengthKm: latest?.walkLengthKm,
      guideRole: latest?.guideRole,
      rifleDetails: latest?.rifleDetails,
      status: latest?.status,
      description: latest?.description,
      lessonsLearned: latest?.lessonsLearned,
      weather: latest?.weather,
      endedAt: latest?.endedAt,
    );
  }

  /// Every drive's hours summed, plus the latest drive's details.
  Future<DriveProgress> loadDrive() async {
    final drives =
        await (database.select(database.drives)
              ..where((t) => t.isTombstone.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
            .get();

    var totalHours = 0.0;
    final entries = <DriveEntry>[];
    for (final drive in drives) {
      totalHours += drive.durationHours ?? 0;
      entries.add(
        DriveEntry(
          localId: drive.localId,
          startedAt: drive.startedAt,
          durationHours: drive.durationHours,
        ),
      );
    }

    // The most recent drive carries the closing facts the card reads out.
    final latest = drives.isEmpty ? null : drives.first;

    return DriveProgress(
      count: drives.length,
      totalHours: totalHours,
      entries: entries,
      daylightHours: latest?.daylightHours,
      nightHours: latest?.nightHours,
      offRoadSeconds: latest?.offRoadSeconds,
      guestCount: latest?.guestCount,
      vehicleId: latest?.vehicleId,
      inspectionOilOk: latest?.inspectionOilOk,
      inspectionWaterOk: latest?.inspectionWaterOk,
      inspectionTyresOk: latest?.inspectionTyresOk,
      offTrackUsed: latest?.offTrackUsed,
      weather: latest?.weather ?? '',
      notes: latest?.notes ?? '',
    );
  }

  /// The requirements a competency catalogue implies. A competency's level is
  /// the size of the requirement. The device holds no record of verified
  /// achievements yet, so [Requirement.have] is honestly zero rather than
  /// invented; the list still tells the trainee what is being asked of them.
  List<Requirement> buildRequirements(List<Competency> competencies) {
    return [
      for (final competency in competencies)
        if (!competency.retired)
          Requirement(
            title: competency.name,
            have: 0,
            need: competency.level,
            detail: competency.description,
          ),
    ];
  }

  /// Hours between the first and last timestamped waypoint of a walk.
  static double? _gapHours(List<TrailWaypoint> points) {
    if (points.length < 2) return null;
    return points.last.recordedAt
            .difference(points.first.recordedAt)
            .inSeconds /
        3600;
  }

  /// The rifle-role split, in the order a mentor reads it, skipping empty roles.
  static List<HoursCount> _hoursList(Map<String, double> hoursByRole) {
    const order = ['first', 'second', 'none'];
    final roles = <String>[
      ...order.where(hoursByRole.containsKey),
      ...hoursByRole.keys.where((role) => !order.contains(role)),
    ];
    return [
      for (final role in roles)
        HoursCount(
          role: role,
          label: _roleHoursLabel(role),
          note: _roleNote(role),
          value: hoursByRole[role]!,
        ),
    ];
  }

  static String _roleHoursLabel(String role) {
    switch (role) {
      case 'first':
        return 'First rifle hours';
      case 'second':
        return 'Second rifle hours';
      default:
        return 'No rifle hours';
    }
  }

  static String _roleNote(String role) {
    switch (role) {
      case 'first':
        return 'Hours walked carrying the first rifle.';
      case 'second':
        return 'Hours walked carrying the second rifle, counted separately.';
      default:
        return 'Hours walked without a rifle.';
    }
  }
}
