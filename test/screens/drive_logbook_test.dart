import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/drive_writer.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/screens/drive_logbook_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The drive logbook, asserted where a guide can see it.
///
/// The rules are the field card's: a disabled save says which fact is
/// missing, and nothing on screen is a score.
Future<void> pumpDrive(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(theme: fieldTheme(FieldColours.dark), home: child),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FieldLogDatabase db;
  late OperationQueue queue;
  late DriveWriter writer;

  setUp(() {
    db = FieldLogDatabase(NativeDatabase.memory(logStatements: false));
    queue = OperationQueue(db);
    writer = DriveWriter(db, queue);
  });
  tearDown(() => db.close());

  DriveLogbookScreen aScreen() => DriveLogbookScreen(
    database: db,
    writer: writer,
    contextCode: 'field:write',
    guideId: 'usr_trainee',
  );

  Future<void> startDrive(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Start the drive'));
    await tester.pumpAndSettle();
  }

  testWidgets('starting a drive opens the live panel', (tester) async {
    await pumpDrive(tester, aScreen());
    expect(find.text('Start a drive'), findsOneWidget);

    await startDrive(tester);

    expect(find.text('On the drive'), findsOneWidget);
    expect(find.text('Pause at this stop'), findsOneWidget);
    // Nothing can be sent yet — the service needs the close-out facts — and
    // the screen does not pretend otherwise with a queued badge.
    expect(await queue.pending(), isEmpty);
  });

  testWidgets('the drive will not close without a head count', (tester) async {
    await pumpDrive(tester, aScreen());
    await startDrive(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'End the drive'));
    await tester.pumpAndSettle();
    expect(find.text('Close the drive'), findsOneWidget);

    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save the drive'),
    );
    expect(save.onPressed, isNull);
    // And it says why, rather than presenting a dead end.
    expect(
      find.text('A head count is needed: how many passengers were aboard?'),
      findsOneWidget,
      reason: 'a disabled control with no explanation is a dead end',
    );
    expect(
      await queue.pending(),
      isEmpty,
      reason: 'nothing is queued until the drive is actually saved',
    );
  });

  testWidgets('keeping driving returns to the live panel with the clock', (
    tester,
  ) async {
    await pumpDrive(tester, aScreen());
    await startDrive(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'End the drive'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep driving'));
    await tester.pumpAndSettle();

    expect(find.text('On the drive'), findsOneWidget);
    expect(find.text('End the drive'), findsOneWidget);
  });

  testWidgets('a drive already open on this device is picked up', (
    tester,
  ) async {
    await db
        .into(db.drives)
        .insert(
          DrivesCompanion.insert(
            localId: 'drive-open',
            contextCode: 'field:write',
            startedAt: DateTime.utc(2026, 10, 4, 5, 30),
            status: const Value('planned'),
            vehicleId: const Value('KAB 123X'),
          ),
        );

    await pumpDrive(tester, aScreen());

    expect(find.text('On the drive'), findsOneWidget);
    expect(find.textContaining('KAB 123X'), findsOneWidget);
    expect(find.text('Start the drive'), findsNothing);
  });
}
