import 'package:field_log/design/field_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The scaffold is the app's only way out of a pushed screen on desktop,
/// so what these lock down is the presence and behaviour of that door —
/// not the styling, which the tokens tests already own.
void main() {
  group('FieldScaffold', () {
    testWidgets('no back arrow when there is nothing to pop', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FieldScaffold(
            title: 'Where you are',
            body: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('Where you are'), findsOneWidget);
    });

    testWidgets('shows a back arrow when the route can pop', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FieldScaffold(
                      title: 'What is waiting to upload',
                      eyebrow: 'Offline queue',
                      body: SizedBox.shrink(),
                    ),
                  ),
                ),
                child: const Text('open queue'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open queue'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text('Offline queue'), findsOneWidget);
      expect(find.text('What is waiting to upload'), findsOneWidget);
    });

    testWidgets('the back arrow leaves the screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FieldScaffold(
                      title: 'Your trail',
                      body: SizedBox.shrink(),
                    ),
                  ),
                ),
                child: const Text('open tally'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open tally'));
      await tester.pumpAndSettle();
      expect(find.text('Your trail'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Your trail'), findsNothing);
      expect(find.text('open tally'), findsOneWidget);
    });

    testWidgets('body and bottom dock both render', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FieldScaffold(
            title: 'Field card',
            body: const Text('the form'),
            bottom: const Text('save dock'),
          ),
        ),
      );

      expect(find.text('the form'), findsOneWidget);
      expect(find.text('save dock'), findsOneWidget);
    });
  });
}
