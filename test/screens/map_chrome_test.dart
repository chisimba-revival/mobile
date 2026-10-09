import 'package:field_log/design/tokens.dart';
import 'package:field_log/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The map's two account controls both open the menu, and neither ever signs
/// anybody out — the instant sign-out that used to hide behind the name chip
/// is the bug these tests exist to prevent.
Future<void> pumpMap(
  WidgetTester tester, {
  String? signedInAs,
  VoidCallback? onTapSignedInAs,
  VoidCallback? onOpenSettings,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: MapScreen(
        pins: const [],
        queuedCount: 0,
        colours: FieldColours.dark,
        online: true,
        gps: GpsReading(
          accuracyMetres: 10,
          satellites: 4,
          fixedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
        signedInAs: signedInAs,
        onTapSignedInAs: onTapSignedInAs,
        onOpenSettings: onOpenSettings,
        onOpenLedger: () {},
        onOpenSighting: (_) {},
        onRecordSighting: () {},
        onOpenTally: () {},
        onOpenDrive: () {},
        onOpenTrail: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the menu button opens settings', (tester) async {
    var opened = false;
    await pumpMap(tester, onOpenSettings: () => opened = true);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('the name chip opens settings rather than signing out', (
    tester,
  ) async {
    var opened = false;
    await pumpMap(
      tester,
      signedInAs: 'Ranger N',
      onTapSignedInAs: () => opened = true,
    );

    expect(find.bySemanticsLabel('Signed in as Ranger N'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Signed in as Ranger N'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('a signed-out phone still has the menu', (tester) async {
    var opened = false;
    await pumpMap(tester, onOpenSettings: () => opened = true);

    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Signed in as Ranger N'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('the legend opens, explains the map, and closes', (tester) async {
    await pumpMap(tester);

    // A legend nobody asked for is noise, so it starts hidden.
    expect(find.text('Legend'), findsNothing);

    await tester.tap(find.byTooltip('Legend'));
    await tester.pumpAndSettle();

    expect(find.text('Legend'), findsOneWidget);
    for (final entry in ['Sighting', 'Water', 'Drainage', 'Scrub', 'Contour']) {
      expect(find.text(entry), findsOneWidget, reason: '$entry in legend');
    }

    await tester.tap(find.byTooltip('Legend'));
    await tester.pumpAndSettle();

    expect(find.text('Legend'), findsNothing);
  });

  testWidgets('the scale bar is on the map and reads a distance', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMap(tester);

    // "Scale bar, N m" — the bar must carry its meaning, not just its line.
    expect(
      find.bySemanticsLabel(RegExp(r'^Scale bar, \d+ m$')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('no compass is drawn when the device reports no heading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMap(tester);

    // Widget tests have no magnetometer, so the compass must stay hidden: a
    // rose that pretends to point north is worse than none.
    expect(find.bySemanticsLabel(RegExp(r'^Compass')), findsNothing);
    semantics.dispose();
  });
}
