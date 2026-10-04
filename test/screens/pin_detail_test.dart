import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/screens/pin_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests exist because the record screen is where somebody goes to answer
/// one question. Most of them check what is on the screen *before* anybody taps
/// anything, because a screen that shows everything at once on a phone held
/// one-handed shows nothing in particular.
/// The add sheet's note field, found by key rather than by type.
///
/// A type-only finder would match a second TextField the moment one was added
/// to the sheet, and the test would then quietly assert against the wrong one.
const _noteField = Key('pin-detail-note-field');

void main() {
  final captured = DateTime.utc(2026, 10, 4, 6, 14);
  final recorded = DateTime.utc(2026, 10, 4, 18, 5);

  PinVisual visualFor({
    String? code = 'LEOP',
    bool hasCode = true,
    int count = 2,
    String? note,
    bool tombstone = false,
    PinState state = PinState.unverified,
  }) {
    return PinVisual(
      state: state,
      glyph: '?',
      isSign: false,
      isNote: !hasCode,
      spoken: note == null
          ? 'Leopard, ${count > 1 ? count : 'one'}.'
          : 'Note, not yet identified. $note Awaiting review.',
    );
  }

  SightingSummary aRecord({
    String? code = 'LEOP',
    bool hasCode = true,
    int? count = 2,
    String common = 'Leopard',
    String scientific = 'Panthera pardus',
    String? behaviour = 'feeding',
    String? ageSex = 'adult_female',
    String? notes = 'Three across the road, then gone.',
    String? recordedCode,
    int? recordedCount,
    String? reason,
    double accuracy = 6,
    int? distance = 40,
    int? bearing = 315,
    String? mentorNote,
    bool lateArrival = false,
  }) {
    return SightingSummary(
      localId: 'local-1',
      visual: visualFor(
        code: code,
        hasCode: hasCode,
        count: count ?? 1,
        note: hasCode ? null : 'Tracks heading north.',
        tombstone: recordedCode != null && recordedCode != code,
      ),
      commonName: common,
      scientificName: scientific,
      status: 'pending',
      capturedAt: captured,
      recordedAt: recorded,
      accuracyMetres: accuracy,
      distanceMetres: distance,
      bearingDegrees: bearing,
      notes: notes ?? '',
      count: count,
      speciesCode: hasCode ? code : null,
      behaviour: behaviour,
      ageSexClass: ageSex,
      recordedSpeciesCode: recordedCode,
      recordedCount: recordedCount,
      correctionReason: reason,
      verificationNotes: mentorNote,
      lateArrival: lateArrival,
    );
  }

  Future<void> open(
    WidgetTester tester,
    SightingSummary sighting, {
    Future<void> Function(String kind, String value)? onAddDetail,
  }) async {
    // Defaults to recording successfully. A test that says nothing about the
    // write should not fail because nothing recorded it — and a test that does
    // care passes its own.
    onAddDetail ??= (kind, value) async {};
    // A tall surface, because a ListView builds lazily and a test that asserts
    // content is absent when it is merely below the fold passes for the wrong
    // reason until the day it passes for the right one.
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: fieldTheme(FieldColours.dark),
        home: PinDetailScreen(sighting: sighting, onAddDetail: onAddDetail),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the record opens on what it is', () {
    testWidgets('the count is the first thing on the card', (tester) async {
      await open(tester, aRecord(count: 7));

      expect(find.text('7'), findsOneWidget);
      expect(find.text('animals'), findsOneWidget);
    });

    testWidgets('one animal reads in the singular', (tester) async {
      await open(tester, aRecord(count: 1));

      expect(find.text('animal'), findsOneWidget);
      expect(find.text('animals'), findsNothing);
    });

    testWidgets('an uncounted record does not claim zero', (tester) async {
      await open(tester, aRecord(count: null));

      // "heard a bellow is one event, not one animal" means no count is a real
      // answer. Printing 0 would be a different claim entirely.
      expect(find.text('0'), findsNothing);
      expect(find.text('number not counted'), findsOneWidget);
    });

    testWidgets('the state is a word, not only a colour', (tester) async {
      await open(
        tester,
        aRecord(
          recordedCode: 'ELEP',
          recordedCount: 4,
          count: 4,
          reason: 'The first count included two calves.',
        ),
      );

      expect(find.text('Corrected'), findsWidgets);
    });

    testWidgets('a record with no species says so rather than going blank', (
      tester,
    ) async {
      await open(
        tester,
        aRecord(hasCode: false, common: '', code: null, count: null),
      );

      expect(find.text('Not yet identified'), findsOneWidget);
      expect(find.text('···'), findsOneWidget);
    });
  });

  group('details are disclosed rather than shown', () {
    testWidgets('nothing below the headline is on screen at first', (
      tester,
    ) async {
      await open(tester, aRecord());

      expect(find.text('All details'), findsOneWidget);
      // Every one of these exists in the record and is deliberately not shown
      // until asked for.
      expect(find.text('Panthera pardus'), findsNothing);
      expect(find.text('Behaviour'), findsNothing);
      expect(find.text('Age and sex'), findsNothing);
    });

    testWidgets('tapping the disclosure reveals them', (tester) async {
      await open(tester, aRecord());

      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();

      expect(find.text('Panthera pardus · LEOP'), findsOneWidget);
      expect(find.text('Behaviour'), findsOneWidget);
      expect(find.text('Feeding'), findsOneWidget);
      expect(find.text('Adult female'), findsOneWidget);
    });

    testWidgets('and hides them again', (tester) async {
      await open(tester, aRecord());

      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();

      expect(find.text('Panthera pardus · LEOP'), findsNothing);
    });
  });

  group('facts that must not be merged', () {
    testWidgets('captured and recorded are both shown and separately named', (
      tester,
    ) async {
      await open(tester, aRecord());

      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();

      expect(find.text('Captured'), findsOneWidget);
      expect(find.text('Recorded'), findsOneWidget);
      // 06:14 appears twice on purpose: in the header eyebrow, which shows when
      // it was seen, and in the Captured field, which names the same fact. Both
      // are legitimate; what must never happen is one standing in for the other.
      expect(find.textContaining('06:14'), findsWidgets);
      expect(find.textContaining('18:05'), findsOneWidget);
    });

    testWidgets('an unrecorded accuracy is not reported as zero', (
      tester,
    ) async {
      await open(tester, aRecord(accuracy: double.infinity));

      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();

      expect(find.text('Accuracy not recorded'), findsOneWidget);
    });

    testWidgets('a bearing is named rather than left as degrees', (
      tester,
    ) async {
      await open(tester, aRecord(bearing: 315));

      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('north-west'), findsOneWidget);
    });

    testWidgets('a late arrival says so', (tester) async {
      await open(tester, aRecord(lateArrival: true));

      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();

      expect(find.text('Recorded after it happened'), findsOneWidget);
    });
  });

  group('a correction', () {
    testWidgets('shows the original beside the corrected value', (
      tester,
    ) async {
      await open(
        tester,
        aRecord(
          code: 'ELEP',
          recordedCode: 'ELEP',
          recordedCount: 7,
          count: 4,
          reason: 'Two calves were counted twice.',
        ),
      );

      expect(find.textContaining('7 → 4'), findsOneWidget);
      expect(
        find.textContaining('Two calves were counted twice.'),
        findsOneWidget,
      );
    });

    testWidgets('is above the details, not buried among them', (tester) async {
      await open(
        tester,
        aRecord(
          recordedCode: 'ELEP',
          recordedCount: 4,
          count: 4,
          reason: 'Overcounted.',
        ),
      );

      final correction = tester.getTopLeft(find.text('Corrected').first);
      final disclosure = tester.getTopLeft(find.text('All details'));
      expect(correction.dy, lessThan(disclosure.dy));
    });

    testWidgets('is absent when nothing was corrected', (tester) async {
      await open(tester, aRecord());

      expect(find.text('Corrected'), findsNothing);
    });
  });

  group('adding to a record', () {
    testWidgets('the dock offers one action', (tester) async {
      await open(tester, aRecord());

      expect(find.text('Add to this record'), findsOneWidget);
    });

    testWidgets('a note is added and reported to the caller', (tester) async {
      final added = <String, String>{};
      await open(
        tester,
        aRecord(),
        onAddDetail: (kind, value) async => added[kind] = value,
      );

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();
      await tester.enterText(
        // widgetWithText needs an exact match; the hint is longer than this.
        find.byKey(_noteField),
        'Tracks over the same road, an hour later.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(added['note'], 'Tracks over the same road, an hour later.');
      expect(find.textContaining('Tracks over the same road'), findsWidgets);
    });

    testWidgets('what was added is marked as not yet sent', (tester) async {
      await open(tester, aRecord());

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();
      await tester.enterText(
        // widgetWithText needs an exact match; the hint is longer than this.
        find.byKey(_noteField),
        'Same animal, moving east.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Added on this phone'), findsOneWidget);
      expect(find.text('Goes up when there is signal.'), findsOneWidget);
    });

    testWidgets('the add button refuses an empty addition', (tester) async {
      await open(tester, aRecord());

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();

      final add = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Add'),
      );
      expect(add.onPressed, equals(null));
      expect(find.textContaining('Add something, or close'), findsOneWidget);
    });

    testWidgets('a behaviour can be picked instead of typing', (tester) async {
      final added = <String, String>{};
      await open(
        tester,
        aRecord(),
        onAddDetail: (kind, value) async => added[kind] = value,
      );

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drinking'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(added['behaviour'], 'drinking');
    });

    testWidgets('wire values are shown as words', (tester) async {
      await open(tester, aRecord());

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();

      // A trainee does not know the contract has a field called age_sex_class.
      expect(find.text('Adult female'), findsWidgets);
      expect(find.text('adult_female'), findsNothing);
    });

    testWidgets('adding twice adds twice rather than replacing', (
      tester,
    ) async {
      final added = <String>[];
      await open(
        tester,
        aRecord(),
        onAddDetail: (kind, value) async => added.add(value),
      );

      for (final note in ['First note.', 'Second note.']) {
        await tester.tap(find.text('Add to this record'));
        await tester.pumpAndSettle();
        await tester.enterText(
          // widgetWithText needs an exact match; the hint is longer than this.
          find.byKey(_noteField),
          note,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Add'));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('First note.'), findsOneWidget);
      expect(find.textContaining('Second note.'), findsOneWidget);
    });
  });

  group('an addition is shown only once it is recorded', () {
    // These three exist because the callback used to be a plain void and the
    // screen added to its list before anybody had written anything. A record
    // screen that shows a note which was never saved is worse than one that
    // shows nothing, because the trainee walks away believing they wrote it
    // down.

    testWidgets('with nobody recording it, nothing is shown', (tester) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: fieldTheme(FieldColours.dark),
          home: PinDetailScreen(sighting: aRecord()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(_noteField),
        'A note nobody is recording.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('A note nobody is recording.'), findsNothing);
      expect(find.text('Added on this phone'), findsNothing);
    });

    testWidgets('a write that fails shows nothing and says why', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: fieldTheme(FieldColours.dark),
          home: PinDetailScreen(
            sighting: aRecord(),
            onAddDetail: (kind, value) async =>
                throw StateError('the disk is full'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(_noteField),
        'A note that could not be written.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // Nothing is claimed as added...
      expect(find.text('Added on this phone'), findsNothing);
      // ...and the raw error is not shown to a person holding a phone.
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.textContaining('the disk is full'), findsNothing);
      expect(find.textContaining('That was not saved'), findsOneWidget);
    });

    testWidgets('a later success clears an earlier failure', (tester) async {
      // Without this the added list stays hidden for good after one failure,
      // so a successful addition is met with the banner about a different one.
      var shouldFail = true;
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: fieldTheme(FieldColours.dark),
          home: PinDetailScreen(
            sighting: aRecord(),
            onAddDetail: (kind, value) async {
              if (shouldFail) throw StateError('no');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final note in ['The one that failed.', 'The one that worked.']) {
        await tester.tap(find.text('Add to this record'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(_noteField), note);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Add'));
        await tester.pumpAndSettle();
        shouldFail = false;
      }

      expect(find.textContaining('That was not saved'), findsNothing);
      expect(find.text('Added on this phone'), findsOneWidget);
      // The failed addition is not listed alongside the one that worked.
      expect(find.textContaining('The one that worked.'), findsOneWidget);
    });
  });

  group('the add sheet on a real phone', () {
    // Every other test here uses a deliberately tall surface so a lazy ListView
    // has built everything. This one deliberately does not, because the sheet is
    // the one part of this screen that is not a ListView and is capped by the
    // screen instead. Without isScrollControlled its lower half — the age and
    // sex chips and the Add button — is clipped away on a phone and the sheet
    // cannot be completed at all.
    Future<void> openOnAPhone(WidgetTester tester, SightingSummary s) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final added = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: fieldTheme(FieldColours.dark),
          home: PinDetailScreen(
            sighting: s,
            onAddDetail: (kind, value) async => added.add(value),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the Add button can actually be reached and pressed', (
      tester,
    ) async {
      await openOnAPhone(tester, aRecord());

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(_noteField),
        'A note from the vehicle.',
      );
      await tester.pumpAndSettle();

      // Scroll the sheet the way a thumb would, then press it. If the sheet is
      // clipped rather than scrollable this tap cannot land.
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.textContaining('A note from the vehicle.'), findsWidgets);
    });

    testWidgets('the age and sex chips are reachable by scrolling', (
      tester,
    ) async {
      await openOnAPhone(tester, aRecord());

      await tester.tap(find.text('Add to this record'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adult female'), findsOneWidget);
    });
  });

  group('long content does not break the layout', () {
    testWidgets('a very long note wraps instead of overflowing', (
      tester,
    ) async {
      await open(
        tester,
        aRecord(
          notes: List.filled(
            60,
            'the road runs east then north past the pan',
          ).join(' '),
          mentorNote: List.filled(
            40,
            'check the identification carefully next time',
          ).join(' '),
        ),
      );

      await tester.tap(find.text('All details'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), equals(null));
      expect(find.text('Your words'), findsOneWidget);
      expect(find.text('Mentor note'), findsOneWidget);
    });
  });
}
