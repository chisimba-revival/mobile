import 'dart:convert';

import 'package:field_log/data/mappers.dart';
import 'package:field_log/models/geo_point.dart';
import 'package:field_log/models/sighting.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests exist because of a bug they would have caught.
///
/// Every decoder here once compared the wire string against `value.name`. That is
/// the same as the wire value only when a Dart identifier happens to match its
/// snake_case form. Three did not: `needsReview` is `needs_review` on the wire,
/// `withYoung` is `with_young`, and `adultUnknown` is `adult_unknown`. Each of
/// those three values was therefore destroyed on the way in, and nothing noticed,
/// because the encode direction was a hand-written switch that was correct.
///
/// The `needs_review` case was the worst. It did not become null. It became
/// `pending`, which is a real state meaning "nobody has looked at this", while
/// the true meaning is "somebody competent looked and declined to decide". That
/// is contract rule 16's entire distinction, thrown away quietly on the pull
/// path. So the tests below are mostly about symmetry: if the encoder and the
/// decoder disagree for even one value, the difference has to be impossible to
/// miss.
void main() {
  group('every enum value survives the round trip', () {
    test('status', () {
      for (final value in SightingStatus.values) {
        final wire = statusWireName(value);
        final back = statusByWire(wire);
        expect(back, value, reason: 'status "$wire" did not decode back');
      }
      // The specific regression, named rather than left to the loop.
      expect(statusByWire('needs_review'), SightingStatus.needsReview);
      expect(
        SightingStatus.needsReview,
        isNot(SightingStatus.pending),
        reason: 'rule 16: somebody looked and declined to decide',
      );
    });

    test('behaviour', () {
      for (final value in SightingBehaviour.values) {
        final wire = behaviourWireName(value);
        final back = behaviourByWire(wire);
        expect(back, value, reason: 'behaviour "$wire" did not decode back');
      }
      expect(behaviourByWire('with_young'), SightingBehaviour.withYoung);
    });

    test('age and sex class', () {
      for (final value in AgeSexClass.values) {
        final wire = ageSexWireName(value);
        final back = ageSexByWire(wire);
        expect(
          back,
          value,
          reason: 'age_sex_class "$wire" did not decode back',
        );
      }
      expect(ageSexByWire('adult_unknown'), AgeSexClass.adultUnknown);
    });

    test('an unknown value is refused rather than guessed', () {
      // The contract does not enumerate behaviour or age_sex_class, so a value
      // we do not know is expected, not exceptional. It becomes null: one lost
      // field, with the record still whole, rather than an exception that loses
      // the sighting.
      expect(behaviourByWire('stalking'), equals(null));
      expect(ageSexByWire('subadult_female'), equals(null));
    });

    test('an unknown status falls back to pending, never to verified', () {
      expect(statusByWire('confirmed'), SightingStatus.pending);
      expect(statusByWire('VERIFIED'), SightingStatus.pending);
    });
  });

  group('a sighting on the wire', () {
    test('round-trips through JSON without losing a field', () {
      final original = WildlifeSighting(
        id: 'local-1',
        contextCode: 'kiswahili',
        driveId: 'drive-1',
        speciesCode: 'LEOP',
        count: 2,
        location: const GeoPoint(longitude: 36.8219, latitude: -1.2921),
        distanceM: 40,
        bearingDeg: 315,
        behaviour: SightingBehaviour.withYoung,
        ageSexClass: AgeSexClass.adultUnknown,
        notes: 'two, moving north',
        status: SightingStatus.needsReview,
        capturedAt: DateTime.utc(2026, 10, 4, 6, 30),
        recordedAt: DateTime.utc(2026, 10, 4, 18, 5),
        revision: 4,
        createdBy: 'usr_trainee',
      );

      final restored = WildlifeSighting.fromJson(
        jsonDecode(encodePayload(sightingToState(original)))
            as Map<String, dynamic>,
      );

      expect(restored.speciesCode, original.speciesCode);
      expect(restored.count, original.count);
      expect(restored.behaviour, original.behaviour);
      expect(restored.ageSexClass, original.ageSexClass);
      expect(restored.status, original.status);
      expect(restored.notes, original.notes);
      expect(restored.distanceM, original.distanceM);
      expect(restored.bearingDeg, original.bearingDeg);
      expect(restored.location.longitude, closeTo(36.8219, 1e-9));
      expect(restored.location.latitude, closeTo(-1.2921, 1e-9));
    });

    test('uses snake_case keys, because the contract does', () {
      final state = sightingToState(
        WildlifeSighting(
          id: 'local-1',
          contextCode: 'kiswahili',
          driveId: 'drive-1',
          location: const GeoPoint(longitude: 36.0, latitude: -1.0),
          status: SightingStatus.pending,
          capturedAt: DateTime.utc(2026, 10, 4, 6, 30),
          recordedAt: DateTime.utc(2026, 10, 4, 18, 5),
          revision: 0,
          createdBy: 'usr_trainee',
        ),
      );

      // A camelCase key here is not a style problem. The service reads
      // snake_case, so the record would arrive with every field empty.
      for (final key in const [
        'context_code',
        'drive_id',
        'status',
        'captured_at',
        'recorded_at',
        'revision',
        'created_by',
        'location',
      ]) {
        expect(state.containsKey(key), isTrue, reason: 'missing $key');
      }
      for (final key in state.keys) {
        expect(
          key,
          isNot(contains(RegExp('[A-Z]'))),
          reason: '$key is camelCase and would not be read',
        );
      }
    });

    test('omits an absent optional rather than sending it as null', () {
      final state = sightingToState(
        WildlifeSighting(
          id: 'local-1',
          contextCode: 'kiswahili',
          driveId: 'drive-1',
          location: const GeoPoint(longitude: 36.0, latitude: -1.0),
          status: SightingStatus.pending,
          capturedAt: DateTime.utc(2026, 10, 4, 6, 30),
          recordedAt: DateTime.utc(2026, 10, 4, 18, 5),
          revision: 0,
          createdBy: 'usr_trainee',
        ),
      );

      // Rule 21: a sighting recorded without an identification is a complete
      // record. Sending species_code: null invites the service to treat the
      // field as cleared rather than never mentioned.
      expect(state.containsKey('species_code'), isFalse);
      expect(state.containsKey('count'), isFalse);
      expect(state.containsKey('notes'), isFalse);
    });
  });
}
