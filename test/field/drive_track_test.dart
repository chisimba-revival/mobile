import 'package:field_log/field/drive_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('night hours', () {
    test('18:00 to 06:00 is the whole drive at night', () {
      final (daylight, night) = splitDayNight(
        DateTime(2026, 10, 4, 18),
        DateTime(2026, 10, 5, 6),
      );
      expect(night, 12);
      expect(daylight, 0);
    });

    test('an hour that straddles dusk splits at the clock', () {
      final (daylight, night) = splitDayNight(
        DateTime(2026, 10, 4, 17),
        DateTime(2026, 10, 4, 19),
      );
      expect(night, 1, reason: 'only 18:00 to 19:00 is night');
      expect(daylight, 1, reason: '17:00 to 18:00 is daylight');
    });

    test('a drive that began before dawn is still inside last night', () {
      final (daylight, night) = splitDayNight(
        DateTime(2026, 10, 4, 5),
        DateTime(2026, 10, 4, 7),
      );
      expect(night, 1, reason: 'the window opened at 18:00 the evening before');
      expect(daylight, 1);
    });

    test('an overnight run counts the whole of it', () {
      final (daylight, night) = splitDayNight(
        DateTime(2026, 10, 4, 20),
        DateTime(2026, 10, 5, 2),
      );
      expect(night, 6);
      expect(daylight, 0);
    });

    test('two nights with a day between them are counted separately', () {
      final (daylight, night) = splitDayNight(
        DateTime(2026, 10, 4, 17),
        DateTime(2026, 10, 6, 17),
      );
      expect(night, 24);
      expect(daylight, 24);
      // Night is never merged into a single "hours worked" number the design
      // forbids; here it is even kept as its own half of the span.
      expect(daylight + night, 48);
    });

    test('a span that does not run forward has no hours at all', () {
      final (daylight, night) = splitDayNight(
        DateTime(2026, 10, 4, 12),
        DateTime(2026, 10, 4, 12),
      );
      expect(daylight, 0);
      expect(night, 0);
    });
  });

  group('driving time', () {
    final start = DateTime.utc(2026, 10, 4, 10);

    test('pauses come off the wall clock', () {
      final tracker = DriveTracker(startedAt: start);
      tracker.pause(DateTime.utc(2026, 10, 4, 10, 30));
      tracker.resume(DateTime.utc(2026, 10, 4, 10, 45));
      expect(
        tracker.drivingSeconds(DateTime.utc(2026, 10, 4, 11)),
        45 * 60,
        reason: 'fifteen minutes at a stop are not driving',
      );
    });

    test('a pause still running stops the clock where it began', () {
      final tracker = DriveTracker(startedAt: start);
      tracker.pause(DateTime.utc(2026, 10, 4, 10, 30));
      expect(tracker.drivingSeconds(DateTime.utc(2026, 10, 4, 12)), 30 * 60);
      expect(tracker.isPaused, isTrue);
      tracker.resume(DateTime.utc(2026, 10, 4, 12, 10));
      expect(
        tracker.drivingSeconds(DateTime.utc(2026, 10, 4, 12, 10)),
        30 * 60,
        reason: 'the two hours paused stay paused after the resume',
      );
    });

    test('a resume with no pause changes nothing', () {
      final tracker = DriveTracker(startedAt: start);
      tracker.resume(DateTime.utc(2026, 10, 4, 11));
      expect(tracker.drivingSeconds(DateTime.utc(2026, 10, 4, 11)), 60 * 60);
    });

    test('the clock never runs backwards', () {
      final tracker = DriveTracker(startedAt: start);
      expect(
        tracker.drivingSeconds(start.subtract(const Duration(hours: 1))),
        0,
      );
    });
  });

  group('distance', () {
    final at = DateTime.utc(2026, 10, 4, 10);

    test('two fixes a hundred metres apart count once', () {
      final tracker = DriveTracker(startedAt: at);
      tracker.addFix(-1.2921, 36.8219, at);
      tracker.addFix(-1.2930, 36.8219, at.add(const Duration(seconds: 30)));
      // 0.0009° of latitude on a sphere of Earth's radius.
      expect(tracker.distanceMetres, closeTo(100.1, 1));
    });

    test('fixes taken while paused add no distance', () {
      final tracker = DriveTracker(startedAt: at);
      tracker.addFix(-1.2921, 36.8219, at);
      tracker.pause(at.add(const Duration(seconds: 10)));
      tracker.addFix(-1.2930, 36.8219, at.add(const Duration(seconds: 30)));
      expect(tracker.distanceMetres, 0);
      // The last-known position moved with the vehicle, so resuming does not
      // draw the line across the stop.
      tracker.resume(at.add(const Duration(minutes: 5)));
      tracker.addFix(
        -1.2931,
        36.8219,
        at.add(const Duration(minutes: 5, seconds: 30)),
      );
      expect(
        tracker.distanceMetres,
        closeTo(11.1, 1),
        reason: 'only the movement after the resume is driven distance',
      );
    });

    test('a gap of more than two minutes is not driven distance', () {
      final tracker = DriveTracker(startedAt: at);
      tracker.addFix(-1.2921, 36.8219, at);
      tracker.addFix(-1.2930, 36.8219, at.add(const Duration(minutes: 5)));
      expect(
        tracker.distanceMetres,
        0,
        reason: 'no fix happened in between, so the line was never driven',
      );
    });
  });
}
