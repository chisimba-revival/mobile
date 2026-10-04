import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/sighting_amendments.dart';
import 'package:field_log/data/tables.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pull_engine_test.dart' show memoryStore, pendingSighting;

/// An addition is somebody's observation. These tests exist because the
/// temptation is to make "add a note" overwrite the note, and because a record
/// that shows an addition the queue has never heard of is a change the client
/// believes it has made and will never send.
void main() {
  late FieldLogDatabase db;
  late OperationQueue queue;
  late SightingAmender amender;

  setUp(() {
    db = memoryStore();
    queue = OperationQueue(db);
    amender = SightingAmender(db, queue);
  });

  tearDown(() => db.close());

  Future<String> aStoredRecord({
    String notes = 'Three across the road.',
  }) async {
    await db
        .into(db.sightings)
        .insert(
          pendingSighting().copyWith(
            notes: Value(notes),
            revision: const Value(4),
            hasPendingChanges: const Value(false),
          ),
        );
    return 'local-1';
  }

  /// The record, which every test here expects to exist.
  ///
  /// Throwing rather than returning null: a test that means to read a record
  /// and finds none should fail on that fact, not on a null dereference twenty
  /// lines later.
  Future<SightingRow> theRow() async {
    final row = await (db.select(
      db.sightings,
    )..where((t) => t.localId.equals('local-1'))).getSingleOrNull();
    if (row == null) {
      throw StateError('expected the record to still be there');
    }
    return row;
  }

  group('adding a note', () {
    test('appends rather than replacing', () async {
      final id = await aStoredRecord();
      await amender.amend(
        id,
        const SightingAmendment(
          AmendmentKind.note,
          'Same animal, moving east.',
        ),
      );

      final row = await theRow();
      expect(row.notes, contains('Three across the road.'));
      expect(row.notes, contains('Same animal, moving east.'));
    });

    test('keeps two additions as two separate things', () async {
      final id = await aStoredRecord();
      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.note, 'First addition.'),
      );
      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.note, 'Second addition.'),
      );

      final row = await theRow();
      // Two additions run together into one sentence is a record nobody can
      // read back later.
      expect(row.notes, contains('First addition.\n\nSecond addition.'));
    });

    test('lands in a record that had no note at all', () async {
      final id = await aStoredRecord(notes: '');
      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.note, 'Only this.'),
      );

      expect((await theRow()).notes, 'Only this.');
    });

    test('leaves the trainee\'s species and count alone', () async {
      final id = await aStoredRecord();
      final before = await theRow();

      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.note, 'A note.'),
      );

      final after = await theRow();
      // A note is about the note. Touching anything else is how a record loses
      // the identification somebody spent a walk on.
      expect(after.speciesCode, before.speciesCode);
      expect(after.count, before.count);
      expect(after.recordedSpeciesCode, before.recordedSpeciesCode);
    });
  });

  group('adding a behaviour or an age and sex', () {
    test('sets the behaviour without touching the notes', () async {
      final id = await aStoredRecord();

      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.behaviour, 'drinking'),
      );

      final row = await theRow();
      expect(row.behaviour, 'drinking');
      expect(row.notes, 'Three across the road.');
    });

    test('sets the age and sex without blanking the behaviour', () async {
      final id = await aStoredRecord();
      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.behaviour, 'feeding'),
      );
      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.ageSex, 'adult_female'),
      );

      final row = await theRow();
      expect(row.ageSexClass, 'adult_female');
      expect(row.behaviour, 'feeding');
    });
  });

  group('every addition is queued', () {
    test('one addition makes one queued update', () async {
      final id = await aStoredRecord();

      final operationId = await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.note, 'A note.'),
      );

      expect(operationId, isNot(equals(null)));
      final queued = await db.select(db.queuedOperations).get();
      expect(queued, hasLength(1));
      expect(queued.single.operationId, operationId);
      expect(queued.single.entityId, 'local-1');
      expect(queued.single.state, OperationState.pending);
    });

    test('the update is based on the revision this client holds', () async {
      final id = await aStoredRecord();

      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.note, 'A note.'),
      );

      final queued = await db.select(db.queuedOperations).getSingle();
      // Based on 4, so the service can tell an addition made on top of what we
      // knew from one made on top of something else.
      expect(queued.baseRevision, 4);
    });

    test('the payload says what was added, not the whole record', () async {
      final id = await aStoredRecord();

      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.ageSex, 'juvenile'),
      );

      final queued = await db.select(db.queuedOperations).getSingle();
      final payload = decodePayload(queued.payload)!;
      expect(payload['amendment'], 'age_sex');
      expect(payload['value'], 'juvenile');
      // The whole record is not resent. An update carries the change.
      expect(payload.containsKey('species_code'), isFalse);
    });

    test('the record is marked as having unsent changes', () async {
      final id = await aStoredRecord();

      await amender.amend(
        id,
        const SightingAmendment(AmendmentKind.note, 'A note.'),
      );

      expect((await theRow()).hasPendingChanges, isTrue);
    });

    test('an unreadable kind is refused rather than guessed at', () {
      // The screen reports what it added. Anything else is a caller that has
      // drifted from this enum, and writing a guessed amendment to somebody's
      // record as though they had said it is the worst available outcome.
      expect(AmendmentKind.fromWire('note'), AmendmentKind.note);
      expect(AmendmentKind.fromWire('age_sex'), AmendmentKind.ageSex);
      expect(AmendmentKind.fromWire('colour'), equals(null));
      expect(AmendmentKind.fromWire(''), equals(null));
    });
  });

  group('the record write and the queue write are one thing', () {
    test('a crash between them loses the addition entirely', () async {
      final id = await aStoredRecord();

      // Break the queue table so the enqueue cannot succeed. If the record
      // write were outside the transaction, the note would be on the row and
      // the queue would know nothing about it: a change the client believes it
      // has made and will never send.
      await db.customStatement('DROP TABLE queued_operations');

      await expectLater(
        amender.amend(
          id,
          const SightingAmendment(AmendmentKind.note, 'Never sent.'),
        ),
        throwsA(anything),
      );

      final row = await theRow();
      expect(
        row.notes,
        'Three across the road.',
        reason: 'the addition must not survive without its queue entry',
      );
    });
  });

  group('a record that is not there', () {
    test('reports that it could not add rather than inventing one', () async {
      final operationId = await amender.amend(
        'no-such-record',
        const SightingAmendment(AmendmentKind.note, 'Orphan.'),
      );

      expect(operationId, equals(null));
      expect(await db.select(db.sightings).get(), isEmpty);
      expect(await db.select(db.queuedOperations).get(), isEmpty);
    });
  });
}
