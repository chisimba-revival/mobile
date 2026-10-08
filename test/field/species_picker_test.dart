import 'package:field_log/data/reference_loader.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/card_state.dart';
import 'package:field_log/field/field_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SpeciesChoice choice(String code, {String common = 'Common'}) => SpeciesChoice(
  code: code,
  commonName: common,
  scientificName: 'Scientificus $code',
);

/// Pumps the card on a tall surface (a ListView builds lazily, so find.text
/// only sees what is on screen) and opens the species picker.
Future<void> openPicker(WidgetTester tester, FieldCardScreen card) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(theme: fieldTheme(FieldColours.dark), home: card),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Choose a species'));
  await tester.pumpAndSettle();
}

FieldCardScreen cardWith({
  List<SpeciesChoice> species = const [],
  List<SpeciesChoice> recent = const [],
  Future<ReferenceSnapshot> Function()? onReload,
}) {
  return FieldCardScreen(
    initial: FieldDraft(mode: CaptureMode.identified),
    species: species,
    reference: const ReferenceValues(),
    onSave: (draft) async {},
    onCancel: () {},
    recentSpecies: recent,
    onReloadSpecies: onReload,
  );
}

void main() {
  group('the species picker', () {
    /// The card beneath the sheet also has text fields, so every finder that
    /// touches the search box must be scoped to the sheet itself.
    Finder searchBox() => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );

    testWidgets('says the list is missing rather than showing an empty sheet', (
      tester,
    ) async {
      await openPicker(tester, cardWith());
      expect(find.text('No species list yet'), findsOneWidget);
      expect(find.text('Download the species list'), findsNothing);
    });

    testWidgets('offers a download when a reload is available, then fills in', (
      tester,
    ) async {
      var reloads = 0;
      final card = cardWith(
        onReload: () async {
          reloads++;
          return ReferenceSnapshot(
            species: [choice('ELEPH', common: 'Elephant')],
          );
        },
      );

      await openPicker(tester, card);
      expect(find.text('No species list yet'), findsOneWidget);
      expect(find.text('Download the species list'), findsOneWidget);

      await tester.tap(find.text('Download the species list'));
      await tester.pumpAndSettle();

      expect(reloads, 1);
      expect(find.text('Elephant'), findsOneWidget);
      expect(find.text('No species list yet'), findsNothing);
    });

    testWidgets('explains a failed download instead of showing nothing', (
      tester,
    ) async {
      final card = cardWith(
        onReload: () async =>
            const ReferenceSnapshot(refreshError: 'network is down'),
      );

      await openPicker(tester, card);
      await tester.tap(find.text('Download the species list'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not reach the reserve office'),
        findsOneWidget,
      );
      // The offer to try again stays.
      expect(find.text('Download the species list'), findsOneWidget);
    });

    testWidgets('says when a query matches nothing, distinct from no data', (
      tester,
    ) async {
      await openPicker(
        tester,
        cardWith(species: [choice('ELEPH', common: 'Elephant')]),
      );
      expect(find.text('No species list yet'), findsNothing);

      await tester.enterText(searchBox(), 'zebra');
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing matches'), findsOneWidget);
      expect(find.textContaining('Try a shorter word'), findsOneWidget);
    });

    testWidgets('lists a recent species under its own heading', (tester) async {
      await openPicker(
        tester,
        cardWith(
          species: [
            choice('ELEPH', common: 'Elephant'),
            choice('LION', common: 'Lion'),
          ],
          recent: [choice('LION', common: 'Lion')],
        ),
      );

      expect(find.text('Recently used'), findsOneWidget);
      expect(find.text('All species'), findsOneWidget);
      // Lion appears once under recents, once in the catalogue is fine, but a
      // query that hides recents must not leave duplicates of the heading.
      await tester.enterText(searchBox(), 'lion');
      await tester.pumpAndSettle();
      expect(find.text('Recently used'), findsNothing);
      expect(find.text('Lion'), findsOneWidget);
    });
  });
}
