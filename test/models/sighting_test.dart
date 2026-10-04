import 'package:field_log/models/geo_point.dart';
import 'package:field_log/models/sighting.dart';
import 'package:flutter_test/flutter_test.dart';

/// A sighting that has been identified: everything the contract requires is
/// present.
WildlifeSighting identified({
  String id = 'a3f0c2d1-0000-4000-8000-000000000001',
  SightingStatus status = SightingStatus.pending,
  String? speciesCode = 'KOPH',
  int? count = 4,
  String? notes = 'Bull and three females moving east along the contour.',
}) {
  return WildlifeSighting(
    id: id,
    contextCode: 'KALAHARI',
    driveId: 'drive-1',
    status: status,
    location: const GeoPoint(longitude: 22.6875, latitude: -19.9833),
    locationAccuracyM: 8.5,
    capturedAt: DateTime.utc(2026, 10, 4, 5, 42),
    recordedAt: DateTime.utc(2026, 10, 4, 9, 15),
    revision: 1,
    createdBy: 'user-1',
    speciesCode: speciesCode,
    count: count,
    notes: notes,
  );
}

/// A sighting recorded as words, because the trainee could not name what they
/// saw. This is the case that did not fit the contract before rule 21.
/// Words a trainee wrote when they could not name what they saw.
const String noteWords =
    'Bull and three females moving east along the contour.';

WildlifeSighting note({String? notes}) =>
    identified(speciesCode: null, count: null, notes: notes ?? noteWords);

void main() {
  group('a sighting may be recorded without an identification', () {
    test('a note compiles with neither a species nor a count', () {
      final sighting = note();
      expect(sighting.speciesCode, isNull);
      expect(sighting.count, isNull);
      expect(sighting.hasIdentification, isFalse);
      expect(sighting.isNote, isTrue);
    });

    test('a note is still a real record, not an absence', () {
      final sighting = note();
      expect(sighting.id, isNotEmpty);
      expect(sighting.location.longitude, 22.6875);
      expect(sighting.capturedAt, isNot(sighting.recordedAt));
      expect(sighting.status, SightingStatus.pending);
    });

    test('what the trainee wrote is retained verbatim', () {
      const words = '  Heard a bellow twice, never saw it.  ';
      expect(note(notes: words).notes, words);
    });

    test('a sighting with a species is not a note', () {
      expect(identified().isNote, isFalse);
      expect(identified().hasIdentification, isTrue);
    });

    test('a sighting with neither a species nor notes is neither', () {
      // An empty sighting is not a note in words; it is an incomplete record,
      // and the two must not be conflated or a blank card reads as a claim.
      final sighting = identified(speciesCode: null, count: null, notes: '   ');
      expect(sighting.isNote, isFalse);
      expect(sighting.hasIdentification, isFalse);
    });
  });

  group('rule 21 conditional requiredness', () {
    test('only verified requires an identification', () {
      expect(SightingStatus.verified.requiresIdentification, isTrue);
      expect(SightingStatus.pending.requiresIdentification, isFalse);
      expect(SightingStatus.needsReview.requiresIdentification, isFalse);
      expect(SightingStatus.rejected.requiresIdentification, isFalse);
    });

    test('a note can be verified as observed', () {
      final verified = note().copyWith(
        status: SightingStatus.verified,
        verifiedBy: 'mentor-1',
        verifiedAt: DateTime.utc(2026, 10, 4, 12),
        verificationNotes: 'Confirmed on the recording. Hearing only.',
      );
      expect(verified.status.requiresIdentification, isTrue);
      // The rule and the record disagree here by design: the mentor confirmed
      // something was there, not what it was. The contract makes this a
      // complete claim, so the client must not treat it as a broken record.
      expect(verified.hasIdentification, isFalse);
      expect(verified.verifiedAt, isNotNull);
    });

    test('an absent count is not a zero', () {
      final sighting = note();
      expect(sighting.count, isNull);
      expect(sighting.count == 0, isFalse);
    });

    test('supplying a species after the fact is a correction', () {
      final corrected = note().copyWith(
        status: SightingStatus.verified,
        speciesCode: 'KOPH',
        count: 1,
        verificationNotes: 'Bellow was a buffalo bull.',
      );
      expect(corrected.hasIdentification, isTrue);
      expect(corrected.hasCorrection, isFalse);
    });
  });

  group('corrections retain what was originally recorded', () {
    test('hasCorrection is false until an original exists', () {
      expect(identified().hasCorrection, isFalse);
      expect(note().hasCorrection, isFalse);
    });

    test('an original recorded value marks a correction', () {
      final corrected = identified().copyWith(
        speciesCode: 'KOPF',
        count: 5,
        recordedSpeciesCode: 'KOPH',
        recordedCount: 4,
        verificationNotes: 'Female, not a male.',
      );
      expect(corrected.hasCorrection, isTrue);
      expect(corrected.recordedSpeciesCode, 'KOPH');
      expect(corrected.recordedCount, 4);
    });

    test('a note corrected into an identification retains having had none', () {
      // There is no original species to retain, and inventing one to fill the
      // shadow field would assert something the trainee never claimed.
      final corrected = note().copyWith(speciesCode: 'KOPH', count: 1);
      expect(corrected.recordedSpeciesCode, isNull);
      expect(corrected.recordedCount, isNull);
    });
  });

  group('status is distinct from when a decision was made', () {
    test('a rejected sighting still carries a verified_at', () {
      final rejected = identified().copyWith(
        status: SightingStatus.rejected,
        verifiedBy: 'mentor-1',
        verifiedAt: DateTime.utc(2026, 10, 4, 12),
        verificationNotes: 'Distance and bearing put these in the next valley.',
      );
      expect(rejected.status, SightingStatus.rejected);
      expect(rejected.verifiedAt, isNotNull);
    });

    test('needs_review is not pending', () {
      // Someone competent looked and declined to decide. Collapsing the two
      // reports a mentor's uncertainty as nobody having looked.
      expect(SightingStatus.needsReview, isNot(SightingStatus.pending));
    });
  });

  group('wire values are the contract values', () {
    test('status serialises as the contract spells it', () {
      for (final entry in <SightingStatus, String>{
        SightingStatus.pending: 'pending',
        SightingStatus.verified: 'verified',
        SightingStatus.rejected: 'rejected',
        SightingStatus.needsReview: 'needs_review',
      }.entries) {
        expect(identified(status: entry.key).toJson()['status'], entry.value);
      }
    });

    test('a note round-trips with its absent fields still absent', () {
      final original = note();
      final restored = WildlifeSighting.fromJson(original.toJson());
      expect(restored, original);
      expect(restored.speciesCode, isNull);
      expect(restored.count, isNull);
      expect(restored.notes, original.notes);
    });

    test('an identified sighting round-trips exactly', () {
      final original = identified();
      expect(WildlifeSighting.fromJson(original.toJson()), original);
    });

    test('late arrival defaults to false rather than being absent', () {
      expect(identified().lateArrival, isFalse);
      expect(
        identified().toJson().containsKey('late_arrival'),
        isTrue,
        reason: 'the wire is snake_case; camelCase here would be the bug',
      );
    });
  });

  group('captured and recorded times survive independently', () {
    test('the gap between capture and record is preserved', () {
      // 05:42 in the vehicle, 09:15 at the truck: the offline lag that makes
      // rule 13's two timestamps necessary rather than redundant.
      final sighting = identified();
      expect(
        sighting.recordedAt.difference(sighting.capturedAt),
        const Duration(hours: 3, minutes: 33),
      );
      final restored = WildlifeSighting.fromJson(sighting.toJson());
      expect(restored.capturedAt, sighting.capturedAt);
      expect(restored.recordedAt, sighting.recordedAt);
    });
  });

  group('species code is four uppercase letters', () {
    test('accepts a conforming code', () {
      expect(validateSpeciesCode('KOPH'), isNull);
      expect(validateSpeciesCode('  KOPH  '), isNull);
    });

    test('explains what is wrong rather than throwing', () {
      // The caller is usually a form deciding whether to enable a control, and
      // it needs a reason to display rather than an exception to catch.
      expect(validateSpeciesCode(null), isNull);
      expect(validateSpeciesCode('KOP'), isNotNull);
      expect(validateSpeciesCode('koph'), isNotNull);
      expect(validateSpeciesCode('KOP1'), isNotNull);
      expect(validateSpeciesCode('KO P'), isNotNull);
      expect(validateSpeciesCode(''), isNotNull);
    });
  });
}
