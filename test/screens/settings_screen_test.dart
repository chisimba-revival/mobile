import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The settings screen is the app's only account menu, so these tests pin
/// the two things that are invisible once it works: sign-out is asked for
/// rather than taken, and the address field accepts what sign-in accepts.
Future<void> pumpSettings(
  WidgetTester tester, {
  String initialServer = 'http://old.example:8080',
  String? signedInAs,
  Future<String?> Function()? onSignIn,
  Future<void> Function()? onSignOut,
  Future<void> Function(String server)? onSaveServer,
  Future<ReferenceLoadResult> Function({required bool forceRefresh})?
  onLoadReference,
  ThemeMode currentThemeMode = ThemeMode.dark,
  void Function(ThemeMode)? onThemeModeChanged,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: fieldTheme(FieldColours.sunlight),
      darkTheme: fieldTheme(FieldColours.dark),
      themeMode: currentThemeMode,
      home: SettingsScreen(
        initialServer: initialServer,
        signedInAs: signedInAs,
        onSignIn: onSignIn,
        onSignOut: onSignOut,
        onSaveServer: onSaveServer,
        onLoadReference: onLoadReference,
        currentThemeMode: currentThemeMode,
        onThemeModeChanged: onThemeModeChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a signed-in phone shows the name and offers sign-out', (
    tester,
  ) async {
    await pumpSettings(tester, signedInAs: 'Ranger N');

    expect(find.text('Signed in as Ranger N.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('a signed-out phone offers sign-in and the name-less state', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(
      find.text('Not sending yet. Records are safe on this phone.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('sign-out asks first and only signs out when confirmed', (
    tester,
  ) async {
    var signedOut = false;
    await pumpSettings(
      tester,
      signedInAs: 'Ranger N',
      onSignOut: () async => signedOut = true,
    );

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    expect(
      signedOut,
      isFalse,
      reason: 'a dialog that signs out before the answer is not a question',
    );

    await tester.tap(find.text('Stay signed in'));
    await tester.pumpAndSettle();

    expect(signedOut, isFalse);
    expect(find.text('Signed in as Ranger N.'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
    expect(
      find.text('Not sending yet. Records are safe on this phone.'),
      findsOneWidget,
      reason: 'the account section must reflect the state it just changed',
    );
  });

  testWidgets('the address field starts at the current server', (tester) async {
    await pumpSettings(tester, initialServer: 'http://current.example:8080');

    // The first text field on the screen is the address; the account section
    // has no fields of its own.
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'http://current.example:8080');
  });

  testWidgets('a changed address is saved and normalised', (tester) async {
    final calls = <String>[];
    await pumpSettings(
      tester,
      onSaveServer: (server) async => calls.add(server),
    );

    await tester.enterText(
      find.byType(TextField).first,
      '  reserve.local:9090/  ',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Save address'));
    await tester.pumpAndSettle();

    expect(calls, ['http://reserve.local:9090']);
    expect(
      find.textContaining(
        'Saved. New requests go to http://reserve.local:9090',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an empty address is refused, not silently kept', (tester) async {
    final calls = <String>[];
    await pumpSettings(
      tester,
      onSaveServer: (server) async => calls.add(server),
    );

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Save address'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter the address of the reserve office.'),
      findsOneWidget,
    );
    expect(calls, isEmpty);
  });

  testWidgets('the reference section reports the count it was given', (
    tester,
  ) async {
    var forced = false;
    await pumpSettings(
      tester,
      onLoadReference: ({required bool forceRefresh}) async {
        forced = forced || forceRefresh;
        return ReferenceLoadResult(
          speciesCount: forceRefresh ? 7 : 6,
          problem: forceRefresh ? 'timed out' : null,
        );
      },
    );

    expect(find.text('6 species on this phone.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
    await tester.pumpAndSettle();

    expect(forced, isTrue);
    expect(find.text('7 species on this phone.'), findsOneWidget);
    expect(find.textContaining('Could not refresh: timed out'), findsOneWidget);
  });

  testWidgets('sign-in from settings reports the name back', (tester) async {
    await pumpSettings(tester, onSignIn: () async => 'Ranger N');

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in as Ranger N.'), findsOneWidget);
  });

  testWidgets('backing out of sign-in leaves the account untouched', (
    tester,
  ) async {
    await pumpSettings(tester, onSignIn: () async => null);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Not sending yet. Records are safe on this phone.'),
      findsOneWidget,
    );
  });

  testWidgets('theme selector shows three chips and highlights current', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      currentThemeMode: ThemeMode.dark,
      onThemeModeChanged: (mode) {},
    );

    // All three chips present
    expect(find.text('Canopy'), findsOneWidget);
    expect(find.text('Sunlight'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Canopy (dark) chip is selected - verify the selected chip has the dust
    // background by finding all AnimatedContainers with that color and
    // confirming at least one exists (the selected one)
    final selectedContainers = find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == FieldColours.dark.dust,
    );
    expect(selectedContainers, findsAtLeastNWidgets(1));
  });

  testWidgets('tapping a theme chip calls onThemeModeChanged', (tester) async {
    // Use a stateful wrapper so the widget's currentThemeMode updates
    // when the callback is called, simulating real app behavior.
    ThemeMode currentMode = ThemeMode.dark;
    final calls = <ThemeMode>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => SettingsScreen(
            initialServer: 'http://test',
            currentThemeMode: currentMode,
            onThemeModeChanged: (mode) {
              calls.add(mode);
              currentMode = mode;
              // Need to rebuild to update the widget's currentThemeMode
              // This is handled by the parent in real usage.
            },
          ),
        ),
      ),
    );

    // Tap Sunlight chip (changes from dark -> light)
    await tester.tap(find.text('Sunlight'));
    await tester.pumpAndSettle();

    expect(calls, [ThemeMode.light]);

    // Update the mode for the next interaction
    currentMode = ThemeMode.light;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => SettingsScreen(
            initialServer: 'http://test',
            currentThemeMode: currentMode,
            onThemeModeChanged: (mode) {
              calls.add(mode);
              currentMode = mode;
            },
          ),
        ),
      ),
    );

    // Tap Auto chip (changes from light -> system)
    await tester.tap(find.text('Auto'));
    await tester.pumpAndSettle();

    expect(calls, [ThemeMode.light, ThemeMode.system]);

    currentMode = ThemeMode.system;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => SettingsScreen(
            initialServer: 'http://test',
            currentThemeMode: currentMode,
            onThemeModeChanged: (mode) {
              calls.add(mode);
              currentMode = mode;
            },
          ),
        ),
      ),
    );

    // Tap Canopy chip (changes from system -> dark)
    await tester.tap(find.text('Canopy'));
    await tester.pumpAndSettle();

    expect(calls, [ThemeMode.light, ThemeMode.system, ThemeMode.dark]);

    // Tap Canopy again (already dark, should not call callback)
    currentMode = ThemeMode.dark;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => SettingsScreen(
            initialServer: 'http://test',
            currentThemeMode: currentMode,
            onThemeModeChanged: (mode) {
              calls.add(mode);
              currentMode = mode;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Canopy'));
    await tester.pumpAndSettle();

    // Callback should not be called again since value hasn't changed
    expect(calls, [ThemeMode.light, ThemeMode.system, ThemeMode.dark]);
  });

  testWidgets(
    'theme selector unavailable when onThemeModeChanged not provided',
    (tester) async {
      // Don't pass onThemeModeChanged
      await pumpSettings(
        tester,
        currentThemeMode: ThemeMode.dark,
        onThemeModeChanged: null,
      );

      expect(find.text('Theme control unavailable.'), findsOneWidget);
      expect(find.text('Canopy'), findsNothing);
    },
  );
}
