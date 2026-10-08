import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/net/chisimba_api.dart' show AuthFailure;
import 'package:field_log/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server field's whole purpose is that the request goes where the
/// operator said. These tests assert the ordering (save before sign-in) and
/// the normalisation (what a person types vs what the client needs), since
/// both are invisible once the screen is working.
Future<void> pumpSignIn(
  WidgetTester tester, {
  required Future<void> Function(String, String) onSignIn,
  String initialServer = 'http://old.example:8080',
  Future<void> Function(String)? onSaveServer,
}) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: fieldTheme(FieldColours.dark),
      home: SignInScreen(
        onSignIn: onSignIn,
        initialServer: initialServer,
        onSaveServer: onSaveServer,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fills username and password so a submit is possible in every test.
Future<void> fillCredentials(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(1), 'ranger');
  await tester.enterText(find.byType(TextField).at(2), 'secret');
}

void main() {
  testWidgets('the address field starts at the current server', (tester) async {
    await pumpSignIn(tester, onSignIn: (_, _) async {});
    final field = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(field.controller?.text, 'http://old.example:8080');
  });

  testWidgets('an empty address is a problem, not a silent fallback', (
    tester,
  ) async {
    var signedIn = false;
    await pumpSignIn(tester, onSignIn: (_, _) async => signedIn = true);
    await tester.enterText(find.byType(TextField).at(0), '   ');
    await fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter the address of the reserve office.'),
      findsOneWidget,
    );
    expect(
      signedIn,
      isFalse,
      reason: 'signing in at the wrong server is worse',
    );
  });

  testWidgets('a changed address is saved before sign-in', (tester) async {
    final calls = <String>[];
    var signedInAfterSave = false;
    await pumpSignIn(
      tester,
      onSignIn: (_, _) async {
        signedInAfterSave = calls.isNotEmpty;
      },
      onSaveServer: (server) async => calls.add(server),
    );
    await tester.enterText(
      find.byType(TextField).at(0),
      'http://new.example:9090',
    );
    await fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(calls, ['http://new.example:9090']);
    expect(
      signedInAfterSave,
      isTrue,
      reason: 'the request must already point at the new server',
    );
  });

  testWidgets('an untouched address does not rewrite the saved one', (
    tester,
  ) async {
    var saved = false;
    var signedIn = false;
    await pumpSignIn(
      tester,
      onSignIn: (_, _) async => signedIn = true,
      onSaveServer: (_) async => saved = true,
    );
    await fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(saved, isFalse);
    expect(signedIn, isTrue);
  });

  testWidgets('a scheme-less address gets the scheme it needs', (tester) async {
    final calls = <String>[];
    await pumpSignIn(
      tester,
      onSignIn: (_, _) async {},
      onSaveServer: (server) async => calls.add(server),
    );
    await tester.enterText(
      find.byType(TextField).at(0),
      '  reserve.local:8080/  ',
    );
    await fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(calls, ['http://reserve.local:8080']);
  });

  testWidgets('a successful sign-in closes the screen', (tester) async {
    var signedIn = false;
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // A stack rather than a bare home: the screen pops itself on success,
    // and a route with nothing under it cannot pop. The map this would
    // reveal in the real app stands in as the route below.
    await tester.pumpWidget(
      MaterialApp(
        theme: fieldTheme(FieldColours.dark),
        home: const Scaffold(body: Text('map beneath')),
        routes: {
          '/sign-in': (_) => SignInScreen(
            onSignIn: (_, _) async => signedIn = true,
            initialServer: 'http://old.example:8080',
          ),
        },
      ),
    );
    Navigator.of(tester.element(find.text('map beneath')))
        .pushNamed('/sign-in');
    await tester.pumpAndSettle();

    await fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(signedIn, isTrue);
    expect(find.byType(SignInScreen), findsNothing);
    expect(
      find.text('map beneath'),
      findsOneWidget,
      reason: 'the map underneath must be what the operator lands on',
    );
  });

  testWidgets('a failed sign-in stays open and says why', (tester) async {
    var attempts = 0;
    await pumpSignIn(
      tester,
      onSignIn: (_, _) async {
        attempts += 1;
        throw AuthFailure('Wrong username or password.');
      },
    );
    await fillCredentials(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Wrong username or password.'), findsOneWidget);
  });
}
