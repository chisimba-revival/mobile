// SightingRow is generated into database.g.dart, which is a part of
// database.dart, so the row type is only reachable through that library.
import 'package:field_log/data/database.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/card_state.dart';
import 'package:field_log/field/field_card_screen.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/models/sighting.dart';
import 'package:field_log/screens/sync_ledger.dart';
import 'package:field_log/screens/tally_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rules the screens must obey, asserted where a user can see them.
///
/// These are widget tests rather than unit tests because the rules are mostly
/// about what is and is not offered: that a form says why it cannot be saved,
/// that a screen shows no score, and that a screen which cannot help does not
/// pretend to be a button.
Future<void> pumpField(WidgetTester tester, Widget child) async {
  // A tall surface, because a ListView builds lazily and find.text only sees
  // what has been built. Without this the tests below would be asserting that
  // content is absent when it is merely below the fold, which is a test that
  // passes for the wrong reason until the day it passes for the right one.
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(theme: fieldTheme(FieldColours.dark), home: child),
  );
  await tester.pumpAndSettle();
}

FieldCardScreen aCard({
  FieldDraft? draft,
  Future<void> Function(FieldDraft)? onSave,
}) {
  return FieldCardScreen(
    initial: draft ?? FieldDraft(mode: CaptureMode.identified),
    species: const [
      SpeciesChoice(
        code: 'ANTH',
        commonName: 'Antelope',
        scientificName: 'Sylvicapra grimmia',
      ),
    ],
    reference: const ReferenceValues(
      behaviours: ['feeding', 'resting'],
      ageSexClasses: ['adult_male', 'juvenile'],
    ),
    onSave: onSave ?? (draft) async {},
    onCancel: () {},
  );
}

void main() {
  group('the field card', () {
    testWidgets('will not save an identified card with no species', (
      tester,
    ) async {
      await pumpField(tester, aCard());
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save to this walk'),
      );
      expect(save.onPressed, isNull);
      // And it says why, rather than presenting a dead end.
      expect(
        find.textContaining('Choose a species, or switch to'),
        findsOneWidget,
        reason: 'a disabled control with no explanation is a dead end',
      );
    });

    testWidgets('will not save an unnamed card with no note', (tester) async {
      await pumpField(
        tester,
        aCard(draft: FieldDraft(mode: CaptureMode.unnamed)),
      );
      expect(find.textContaining('Describe what you saw'), findsOneWidget);
    });

    testWidgets('will save an unnamed card once a note is written', (
      tester,
    ) async {
      await pumpField(
        tester,
        aCard(
          draft: FieldDraft(
            mode: CaptureMode.unnamed,
            notes: 'Tracks heading north, fresh, could not say whose.',
          ),
        ),
      );
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save to this walk'),
      );
      expect(save.onPressed, isNotNull);
    });

    testWidgets('keeps what was typed when the mode changes', (tester) async {
      var draft = FieldDraft(
        mode: CaptureMode.identified,
        notes: 'a herd moving east',
        distanceMetres: 120,
      );
      await pumpField(
        tester,
        aCard(draft: draft, onSave: (FieldDraft saved) async => draft = saved),
      );

      expect(find.text('a herd moving east'), findsOneWidget);

      // The case the design's promise is actually about: a trainee starts to
      // name an animal, gets unsure, and switches.
      await tester.tap(find.text('I am not sure'));
      await tester.pumpAndSettle();

      expect(find.text('a herd moving east'), findsOneWidget);
      expect(find.text('120'), findsWidgets);
    });

    testWidgets('offers both modes as a radio group', (tester) async {
      await pumpField(tester, aCard());
      expect(find.text('I identified it'), findsOneWidget);
      expect(find.text('I am not sure'), findsOneWidget);
    });

    testWidgets('keeps the position visible while the card is typed', (
      tester,
    ) async {
      await pumpField(
        tester,
        FieldCardScreen(
          initial: FieldDraft(mode: CaptureMode.identified),
          species: const [],
          reference: const ReferenceValues(behaviours: [], ageSexClasses: []),
          coordinateLabel: '-1.2921, 36.8219',
          accuracyMetres: 6,
          onSave: (draft) async {},
          onCancel: () {},
        ),
      );
      // The strip composes its caption in a RichText, and find.textContaining
      // does not look inside one unless it is told to.
      expect(
        find.textContaining('-1.2921', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('6 m', findRichText: true), findsOneWidget);
    });

    testWidgets('hides the walk-only fields on a drive', (tester) async {
      await pumpField(
        tester,
        FieldCardScreen(
          initial: FieldDraft(mode: CaptureMode.identified),
          species: const [],
          reference: const ReferenceValues(behaviours: [], ageSexClasses: []),
          isTrailWalk: false,
          onSave: (draft) async {},
          onCancel: () {},
        ),
      );
      expect(find.text('Lessons learned'), findsNothing);
      expect(find.text('Hours on this walk'), findsNothing);
    });
  });

  group('the tally', () {
    TrailProgress aProgress() => const TrailProgress(
      hours: [
        HoursCount(
          role: 'first',
          label: '1st rifle hours',
          note: 'Your hours walking first rifle.',
          value: 14.5,
        ),
        HoursCount(
          role: 'second',
          label: '2nd rifle hours',
          note: 'Counted separately.',
          value: 9.25,
        ),
      ],
      requirements: [
        Requirement(title: 'Elephant encounters', have: 10, need: 10),
        Requirement(
          title: 'Rhino encounters',
          have: 3,
          need: 5,
          detail: 'Two more to discuss at your next walk',
        ),
      ],
    );

    testWidgets('shows hours kept apart by role', (tester) async {
      await pumpField(tester, TallyScreen(progress: aProgress()));
      expect(find.text('1st rifle hours'), findsOneWidget);
      expect(find.text('2nd rifle hours'), findsOneWidget);
      // Not merged into one larger number that means nothing actionable.
      expect(find.text('23.75 h'), findsNothing);
      // 9.25 is reportable and must not be rounded away.
      expect(find.text('9.25 h'), findsOneWidget);
      expect(find.text('14.5 h'), findsOneWidget);
    });

    testWidgets('states requirements as counts, not as a score', (
      tester,
    ) async {
      await pumpField(tester, TallyScreen(progress: aProgress()));
      expect(find.text('10 of 10'), findsOneWidget);
      expect(find.text('3 of 5'), findsOneWidget);
      expect(
        find.text('Two more to discuss at your next walk'),
        findsOneWidget,
      );
    });

    testWidgets('shows no points, bars or percentages anywhere', (
      tester,
    ) async {
      await pumpField(tester, TallyScreen(progress: aProgress()));

      // Contract rule 20. Asserted over the rendered text rather than by
      // reading the code, because the point is what a trainee can see.
      final rendered = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((w) => w.text.toPlainText())
          .join(' ');

      expect(RegExp(r'\d+\s*%').hasMatch(rendered), isFalse);
      expect(
        RegExp(r'\bpoints?\b', caseSensitive: false).hasMatch(rendered),
        isFalse,
      );
      expect(
        RegExp(r'\bscore\b', caseSensitive: false).hasMatch(rendered),
        isFalse,
      );
      // A progress bar would be the same judgement in a different shape.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('does not present readiness as decided', (tester) async {
      await pumpField(tester, TallyScreen(progress: aProgress()));
      expect(
        find.textContaining('is not a verdict'),
        findsOneWidget,
        reason: 'the mentor decides, not the list',
      );
      expect(
        find.textContaining('nothing here stops you submitting'),
        findsOneWidget,
      );
    });
  });

  group('the ledger', () {
    testWidgets('presents no control that could make a change send sooner', (
      tester,
    ) async {
      await pumpField(
        tester,
        SyncLedgerScreen(
          online: false,
          entries: const [
            LedgerEntry(
              title: 'Sighting · Elephant',
              detail: 'Four on the second count',
              state: LedgerState.deferred,
            ),
          ],
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      // It says what state the work is in, and that pressing would not help.
      expect(find.text('needs a person'), findsNothing);
      expect(find.text('waiting'), findsOneWidget);
      expect(find.textContaining('goes on its own'), findsOneWidget);
    });

    testWidgets('says the queue is automatic when there is signal', (
      tester,
    ) async {
      await pumpField(
        tester,
        SyncLedgerScreen(online: true, entries: const []),
      );
      expect(find.textContaining('retries itself'), findsOneWidget);
      expect(find.text('Nothing is waiting'), findsOneWidget);
    });
  });

  testWidgets('a requirement that is not met says how much is left', (
    tester,
  ) async {
    await pumpField(
      tester,
      const TallyScreen(
        progress: TrailProgress(
          hours: [],
          requirements: [
            Requirement(title: 'Elephant encounters', have: 10, need: 10),
            Requirement(title: 'Rhino encounters', have: 3, need: 5),
          ],
        ),
      ),
    );
    // The amount still to do, not a shortfall score. "2 to go" can be acted on;
    // "40 per cent short" only judges.
    expect(find.text('2 to go', findRichText: true), findsOneWidget);
    expect(
      find.text('0 to go'),
      findsNothing,
      reason: 'met shows no remainder',
    );
  });

  group('the pin vocabulary', () {
    // These drive the real pinVisualFor over real rows. An earlier version of
    // this file restated the rule in a local helper and asserted against that,
    // which would have kept passing if the implementation changed to disagree.
    test('a sighting recorded in words and never identified is a question', () {
      final visual = pinVisualFor(
        _aRow(notes: 'Tracks heading north, could not say whose.'),
        commonNameFor: _nameOf,
      );
      expect(visual.glyph, '?');
      expect(visual.isNote, isTrue);
      expect(visual.state, PinState.unverified);
    });

    test('a spoor or a call is a dot, not a count', () {
      for (final code in ['SPOO', 'SCAT', 'VOX']) {
        final visual = pinVisualFor(
          _aRow(speciesCode: code, count: 4),
          commonNameFor: _nameOf,
        );
        expect(visual.glyph, '\u00b7', reason: code);
        expect(visual.isSign, isTrue, reason: code);
      }
    });

    test('more than one animal shows the count', () {
      expect(
        pinVisualFor(
          _aRow(speciesCode: 'ANTH', count: 4),
          commonNameFor: _nameOf,
        ).glyph,
        '4',
      );
    });

    test('one animal shows the first letter of its code', () {
      expect(
        pinVisualFor(
          _aRow(speciesCode: 'ANTH', count: 1),
          commonNameFor: _nameOf,
        ).glyph,
        'A',
      );
    });

    test('a deleted record keeps its place rather than disappearing', () {
      final visual = pinVisualFor(
        _aRow(speciesCode: 'ANTH', count: 3, tombstone: true),
        commonNameFor: _nameOf,
      );
      expect(visual.state, PinState.deleted);
      // The initial, not the count: a deleted pin is a place that used to
      // hold something, and the code is what says what.
      expect(visual.glyph, 'A');
      expect(visual.spoken, contains('Deleted'));
    });

    test('a corrected count is announced as a correction', () {
      final visual = pinVisualFor(
        _aRow(
          speciesCode: 'ELEP',
          count: 4,
          recordedCount: 7,
          correctionReason: 'Recounted from the vehicle.',
        ),
        commonNameFor: _nameOf,
      );
      expect(visual.state, PinState.corrected);
      expect(
        visual.spoken,
        allOf(contains('7'), contains('4'), contains('Recounted')),
        reason:
            'a number that quietly changed is the one thing a trainee '
            'could not learn from',
      );
    });

    test('needs review is not the same as pending', () {
      // Contract rule 16: nobody looked, versus somebody competent looked and
      // declined to decide. Flattening these destroys the distinction.
      final pending = pinVisualFor(
        _aRow(speciesCode: 'RHIN', status: SightingStatus.pending),
        commonNameFor: _nameOf,
      );
      final needsReview = pinVisualFor(
        _aRow(speciesCode: 'RHIN', status: SightingStatus.needsReview),
        commonNameFor: _nameOf,
      );
      expect(pending.spoken, isNot(needsReview.spoken));
      expect(needsReview.spoken, contains('has not decided'));
    });

    test('a record with no species is a question whatever its status', () {
      // Contract rule 21: a sighting may name nothing, so the pin says so
      // rather than borrowing a letter from a species nobody claimed.
      for (final status in [
        SightingStatus.pending,
        SightingStatus.needsReview,
        SightingStatus.verified,
      ]) {
        final visual = pinVisualFor(
          _aRow(notes: 'Tracks heading north.', status: status),
          commonNameFor: _nameOf,
        );
        expect(visual.glyph, '?', reason: status.name);
        expect(visual.isNote, isTrue, reason: status.name);
      }
    });

    test('a note whose species arrived later stops being a question', () {
      // Once the species is present the pin reads solid. That is what the
      // design means by "your words stay, the pin goes solid".
      final identified = pinVisualFor(
        _aRow(
          notes: 'Tracks heading north, could not say whose.',
          speciesCode: 'LEOP',
          status: SightingStatus.verified,
        ),
        commonNameFor: _nameOf,
      );
      expect(identified.glyph, 'L');
      expect(identified.isNote, isFalse);
    });
  });
}

/// A sighting row with the fields a pin depends on, and everything else at its
/// natural default. Built without a database because the pin rules are about a
/// row's values, not about where it was read from.
SightingRow _aRow({
  String? speciesCode,
  int? count,
  int? recordedCount,
  String? correctionReason,
  String? notes,
  SightingStatus status = SightingStatus.pending,
  bool tombstone = false,
}) {
  return SightingRow(
    localId: 'local-1',
    serverId: null,
    contextCode: 'kiswahili',
    driveId: 'drive-1',
    speciesCode: speciesCode,
    count: count,
    recordedSpeciesCode: null,
    recordedCount: recordedCount,
    correctionReason: correctionReason,
    notes: notes,
    status: status,
    locationLat: -1.2921,
    locationLng: 36.8219,
    locationAccuracyM: 6.0,
    distanceM: null,
    bearingDeg: null,
    behaviour: null,
    ageSexClass: null,
    capturedAt: DateTime.utc(2026, 10, 4, 6, 30),
    recordedAt: DateTime.utc(2026, 10, 4, 18, 5),
    revision: 3,
    verifiedBy: null,
    verifiedAt: null,
    verificationNotes: null,
    createdBy: 'usr_trainee',
    lateArrival: false,
    isTombstone: tombstone,
    deletedAt: tombstone ? DateTime.utc(2026, 10, 4, 19, 0) : null,
    hasPendingChanges: false,
  );
}

String _nameOf(String code) => code;
