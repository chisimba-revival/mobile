import 'package:field_log/design/tokens.dart';
import 'package:field_log/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The map's account controls never sign anybody out on a stray tap — the
/// instant sign-out that used to hide behind the name chip is the bug these
/// tests exist to prevent — and the fold menu is where the map's navigation
/// lives now.
///
/// [gps] decides where the map opens. The default is a real fix in South
/// Africa, so the map opens on it at field zoom; a reading with the epoch
/// timestamp and zero coordinates is the "still searching" stand-in
/// [GpsReading.hasFix] rejects, which leaves the map on the country view.
Future<void> pumpMap(
  WidgetTester tester, {
  GpsReading? gps,
  String? signedInAs,
  VoidCallback? onTapSignedInAs,
  VoidCallback? onOpenSettings,
  VoidCallback? onOpenObservations,
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
        gps:
            gps ??
            GpsReading(
              accuracyMetres: 10,
              satellites: 4,
              fixedAt: DateTime.fromMillisecondsSinceEpoch(1750000000000),
              latitude: -25.7461,
              longitude: 28.1881,
            ),
        onRecordSighting: () {},
        signedInAs: signedInAs,
        onTapSignedInAs: onTapSignedInAs,
        onOpenSettings: onOpenSettings,
        onOpenObservations: onOpenObservations,
        onOpenLedger: () {},
        onOpenSighting: (_) {},
        onOpenTally: () {},
        onOpenDrive: () {},
        onOpenTrail: () {},
        tileCache: null,
        selectedLocalId: null,
        onMapTap: null,
        onDropPin: null,
        route: null,
        routeWaypoints: null,
        currentPosition: null,
        mapStylePreset: MapStylePreset.field,
        onMapStylePresetChanged: null,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The stand-in the main screen publishes while the receiver is still looking:
/// the epoch as its timestamp, and 0,0 as its coordinates.
final GpsReading _noFix = GpsReading(
  accuracyMetres: 0,
  satellites: 0,
  fixedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
);

void main() {
  testWidgets('the menu button folds out the menu, which opens settings', (
    tester,
  ) async {
    var opened = false;
    await pumpMap(
      tester,
      onOpenSettings: () => opened = true,
      onOpenObservations: () {},
    );

    // The button folds a menu out of the bar; settings is a row inside it,
    // sharing one place with Drive, Trail, Progress and Observations. The
    // folded card keeps its rows mounted at zero height, so a row being
    // reachable is the signal that the menu is out, not its merely existing.
    expect(find.text('Settings').hitTestable(), findsNothing);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    for (final entry in [
      'Drive',
      'Trail',
      'Observations',
      'Progress',
      'Settings',
    ]) {
      expect(
        find.text(entry).hitTestable(),
        findsOneWidget,
        reason: '$entry in the menu',
      );
    }

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.text('Settings').hitTestable(), findsNothing);
  });

  testWidgets('the logbook opens from the menu', (tester) async {
    var opened = false;
    await pumpMap(tester, onOpenObservations: () => opened = true);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Observations').hitTestable());
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

    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Signed in as Ranger N'), findsNothing);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    // Signing out is not a precondition for anything the menu offers.
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('the map opens where the receiver says it is', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMap(tester);

    // A fix in hand opens the map on it at field zoom: the bar reads five
    // hundred metres, which at this latitude only happens at zoom 14. The
    // country view would read a hundred kilometres instead.
    expect(find.bySemanticsLabel('Scale bar, 500 m'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('with no fix yet the map opens on the country', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMap(tester, gps: _noFix);

    // The stand-in is not a position, so the map falls back to South Africa as
    // a whole: a hundred kilometres across the bar is zoom 6, well below any
    // field zoom, which is the one thing this fallback has to be able to show.
    expect(find.bySemanticsLabel('Scale bar, 100 km'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a fix that lands later moves the map once, not again', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    // One StatefulBuilder that owns the reading: replacing it in place is what
    // makes Flutter update the existing MapScreen (and so call didUpdateWidget)
    // rather than building a fresh one.
    var reading = _noFix;
    late StateSetter rebuild;

    Widget buildMap() => MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return MapScreen(
            pins: const [],
            queuedCount: 0,
            colours: FieldColours.dark,
            online: true,
            gps: reading,
            onOpenLedger: () {},
            onOpenSighting: (_) {},
            onRecordSighting: () {},
            onOpenTally: () {},
            onOpenDrive: () {},
            onOpenTrail: () {},
          );
        },
      ),
    );

    await tester.pumpWidget(buildMap());
    await tester.pumpAndSettle();

    // Nothing yet, so the country view holds.
    expect(find.bySemanticsLabel('Scale bar, 100 km'), findsOneWidget);

    // The receiver finds the device: the map comes to it.
    reading = GpsReading(
      accuracyMetres: 10,
      satellites: 4,
      fixedAt: DateTime.fromMillisecondsSinceEpoch(1750000000000),
      latitude: -25.7461,
      longitude: 28.1881,
    );
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Scale bar, 500 m'), findsOneWidget);

    // The user steps back out a zoom. A refreshed fix arrives after that, and
    // the map must stay where it was left rather than snapping back under them.
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Scale bar, 1 km'), findsOneWidget);

    reading = GpsReading(
      accuracyMetres: 10,
      satellites: 4,
      fixedAt: DateTime.fromMillisecondsSinceEpoch(1750000001000),
      latitude: -25.7461,
      longitude: 28.1881,
    );
    rebuild(() {});
    await tester.pumpAndSettle();

    // Still at the user's zoom, not dragged back to the fix's zoom.
    expect(find.bySemanticsLabel('Scale bar, 1 km'), findsOneWidget);
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

  testWidgets('the zoom buttons step the map and the scale bar follows', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMap(tester);

    // Field zoom over South Africa reads half a kilometre across the bar.
    expect(find.bySemanticsLabel('Scale bar, 500 m'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();

    // One step in halves the ground each bar width covers.
    expect(find.bySemanticsLabel('Scale bar, 200 m'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Scale bar, 500 m'), findsOneWidget);
    semantics.dispose();
  });
}
