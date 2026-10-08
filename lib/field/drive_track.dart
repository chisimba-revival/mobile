/// The arithmetic of a drive: how far the vehicle went, how long it was
/// actually being driven, and which of its hours were night hours.
///
/// Everything here is pure — no database, no GPS, no Flutter — because these
/// are the numbers a mentor reads off the record and they must be testable
/// without a device. The screen owns the fixes and the clock; this file owns
/// what those observations add up to.
library;

import 'dart:math';

/// Straight-line distance between two fixes, in metres.
///
/// The haversine formula, the same one the route layer draws with. A logbook
/// of straight lines between fixes underestimates a winding reserve track,
/// which is why the drive screen states what the distance is made of rather
/// than presenting it as an odometer.
double haversineMetres(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final phi1 = lat1 * pi / 180;
  final phi2 = lat2 * pi / 180;
  final dPhi = (lat2 - lat1) * pi / 180;
  final dLambda = (lng2 - lng1) * pi / 180;
  final a =
      sin(dPhi / 2) * sin(dPhi / 2) +
      cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
  return 2 * earthRadius * atan2(sqrt(a), sqrt(1 - a));
}

/// The day and night split of a wall-clock span, in hours.
///
/// Night is 18:00 to 06:00 on the clock — the hours a night qualification is
/// about — and it is derived from the clock rather than from sunlight because
/// the contract states the window, not the dusk. Both arguments must be in
/// the same zone; the screen passes local time because the window is a local
/// one.
///
/// Returns `(daylightHours, nightHours)`. A span that does not run forward
/// contributes nothing to either.
(double, double) splitDayNight(DateTime start, DateTime end) {
  if (!end.isAfter(start)) return (0, 0);

  var nightSeconds = 0;
  // Each night window runs from 18:00 on one day to 06:00 on the next, so the
  // walk starts a day early: a drive that began at 02:00 is inside the window
  // that opened the previous evening.
  var day = DateTime(
    start.year,
    start.month,
    start.day,
  ).subtract(const Duration(days: 1));
  while (!day.isAfter(end)) {
    final windowStart = DateTime(day.year, day.month, day.day, 18);
    final windowEnd = DateTime(day.year, day.month, day.day + 1, 6);
    final from = windowStart.isAfter(start) ? windowStart : start;
    final to = windowEnd.isBefore(end) ? windowEnd : end;
    if (to.isAfter(from)) {
      nightSeconds += to.difference(from).inSeconds;
    }
    day = day.add(const Duration(days: 1));
  }

  final totalSeconds = end.difference(start).inSeconds;
  return ((totalSeconds - nightSeconds) / 3600, nightSeconds / 3600);
}

/// One drive's live arithmetic, held in memory while the screen is open.
///
/// Pauses and distance are session state on purpose: a stop the vehicle made
/// last week is not something this device can recover, and inventing one from
/// the wall clock would be a measurement that never happened. What is held
/// here is what was actually observed — fixes while moving, pauses while the
/// screen was watching — and the end form offers every derived number as an
/// editable value so a guide can correct what the session could not know.
class DriveTracker {
  DriveTracker({required this.startedAt});

  /// When the drive began, in UTC.
  final DateTime startedAt;

  DateTime? _pausedAt;
  int _pausedSeconds = 0;
  double _distanceMetres = 0;

  /// Time at a stop, held until the next fix so it can explain the gap the
  /// stop left. Without it the first driven leg after a long pause would be
  /// discarded as a GPS hole.
  int _exemptGapSeconds = 0;

  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastAt;

  bool get isPaused => _pausedAt != null;

  /// Total metres accumulated from fixes taken while driving.
  double get distanceMetres => _distanceMetres;

  /// Begin a pause. A second pause while already paused changes nothing.
  void pause(DateTime at) {
    _pausedAt ??= at;
  }

  /// End the current pause. A resume with no pause is a no-op.
  void resume(DateTime at) {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    final seconds = at.difference(pausedAt).inSeconds;
    _pausedSeconds += seconds;
    _exemptGapSeconds += seconds;
    _pausedAt = null;
  }

  /// Seconds of driving time: wall clock since the start, minus every pause
  /// including one still running.
  ///
  /// Never negative — a clock adjustment mid-drive is not negative time.
  int drivingSeconds(DateTime now) {
    var seconds = now.difference(startedAt).inSeconds - _pausedSeconds;
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      seconds -= now.difference(pausedAt).inSeconds;
    }
    return seconds < 0 ? 0 : seconds;
  }

  /// Take a position fix and fold it into the distance.
  ///
  /// While paused the fix still moves the last-known position — so resuming
  /// does not draw a line across the stop — but contributes no distance.
  /// A gap longer than two minutes between fixes is the phone coming back
  /// rather than the vehicle moving: no fix happened in between, so the line
  /// between the two edges would be distance that was never driven.
  void addFix(double latitude, double longitude, DateTime at) {
    final lastAt = _lastAt;
    if (lastAt != null && !isPaused) {
      // The stop's own duration comes off the gap first: a pause is a known
      // reason for silence, a hole in the trace while driving is not.
      final gap = at.difference(lastAt).inSeconds - _exemptGapSeconds;
      _exemptGapSeconds = 0;
      if (gap > 0 && gap <= 120) {
        _distanceMetres += haversineMetres(
          _lastLatitude!,
          _lastLongitude!,
          latitude,
          longitude,
        );
      }
    }
    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _lastAt = at;
  }
}
