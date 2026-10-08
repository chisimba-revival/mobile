import 'dart:io';

import 'package:drift/native.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/reference_loader.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:field_log/net/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// A session file with usable tokens, so [ReferenceLoader] attempts a refresh.
Future<SessionStore> usableSession(Directory temp) async {
  final store = SessionStore(file: File('${temp.path}/session.json'));
  await store.write(
    const StoredTokens(accessToken: 'access', refreshToken: 'refresh'),
  );
  return store;
}

/// Serves canned lists and counts calls, so a test can tell a refresh from a
/// cache hit without a network.
class FakeApi extends ChisimbaApi {
  FakeApi({
    this.species = const [],
    this.outings = const [],
    this.competencies = const [],
    this.fail = false,
  }) : super(baseUrl: 'http://localhost');

  List<Species> species;
  List<Outing> outings;
  List<Competency> competencies;
  bool fail;
  int calls = 0;

  void _hit() {
    calls++;
    if (fail) {
      throw const SocketException('network is down');
    }
  }

  @override
  Future<SpeciesList> getSpecies(String accessToken) async {
    _hit();
    return SpeciesList(species: species);
  }

  @override
  Future<OutingList> getOutings(String accessToken) async {
    _hit();
    return OutingList(outings: outings);
  }

  @override
  Future<CompetencyList> getCompetencies(String accessToken) async {
    _hit();
    return CompetencyList(competencies: competencies);
  }
}

Species aSpecies(String code, String common) => Species(
  code: code,
  commonName: common,
  scientificName: 'Scientificus $code',
  description: '',
);

Competency aCompetency(String name, String category, {bool retired = false}) =>
    Competency(
      code: name,
      name: name,
      category: category,
      level: 1,
      description: '',
      retired: retired,
    );

Outing anOuting(String id) => Outing(
  id: id,
  kind: 'drive',
  contextCode: 'north',
  guideId: 'g1',
  traineeIds: const ['t1'],
  status: 'active',
  plannedStart: '2026-10-07T06:00:00Z',
  revision: 1,
);

void main() {
  late FieldLogDatabase db;
  late Directory temp;

  setUp(() async {
    db = FieldLogDatabase(NativeDatabase.memory(logStatements: false));
    temp = await Directory.systemTemp.createTemp('ref_loader_test');
  });

  tearDown(() async {
    await db.close();
    if (await temp.exists()) {
      await temp.delete(recursive: true);
    }
  });

  group('ReferenceLoader.load', () {
    test(
      'refreshes, writes the cache, and serves the fresh snapshot',
      () async {
        final api = FakeApi(
          species: [aSpecies('ZEBR', 'Zebra'), aSpecies('ELEPH', 'Elephant')],
          outings: [anOuting('out-1')],
          competencies: [
            aCompetency('Walking quietly', 'Behaviour'),
            aCompetency('Adult', 'Demographics'),
          ],
        );
        final loader = ReferenceLoader(
          database: db,
          api: api,
          sessions: await usableSession(temp),
        );

        final snapshot = await loader.load();

        expect(api.calls, 3);
        expect(snapshot.fromCache, isFalse);
        expect(snapshot.refreshError, isNull);
        expect(
          snapshot.species.map((s) => s.code),
          ['ELEPH', 'ZEBR'], // sorted by common name: Elephant, Zebra
        );
        expect(snapshot.species.first.scientificName, 'Scientificus ELEPH');
        expect(snapshot.outings.single.id, 'out-1');
        expect(snapshot.reference.behaviours, ['walking_quietly']);
        expect(snapshot.reference.ageSexClasses, ['adult']);

        // The cache now holds every kind, including the freshness marker.
        final rows = await db.select(db.referenceData).get();
        expect(rows.where((r) => r.kind == 'species').length, 2);
        expect(rows.where((r) => r.kind == 'outing').length, 1);
        expect(rows.where((r) => r.kind == 'behaviour').length, 1);
        expect(rows.where((r) => r.kind == 'age_sex_class').length, 1);
        expect(
          rows.where((r) => r.kind == 'meta' && r.code == 'fetched_at'),
          hasLength(1),
        );
      },
    );

    test('serves the cache with an error when the refresh fails', () async {
      final api = FakeApi(
        species: [aSpecies('LION', 'Lion')],
        outings: const [],
        competencies: const [],
      );
      final loader = ReferenceLoader(
        database: db,
        api: api,
        sessions: await usableSession(temp),
      );
      await loader.load(); // seed: success now

      api.fail = true;
      final snapshot = await loader.load(forceRefresh: true);

      expect(snapshot.refreshError, isNotNull);
      expect(snapshot.fromCache, isTrue);
      expect(snapshot.species.single.code, 'LION');
    });

    test(
      'within the freshness window the cache answers without a fetch',
      () async {
        final api = FakeApi(species: [aSpecies('LION', 'Lion')]);
        final loader = ReferenceLoader(
          database: db,
          api: api,
          sessions: await usableSession(temp),
        );
        await loader.load(); // 3 calls, writes fetched_at

        final snapshot = await loader.load();
        expect(api.calls, 3, reason: 'second load hits the TTL and skips');
        expect(snapshot.species.single.code, 'LION');
      },
    );

    test('forceRefresh bypasses the freshness window', () async {
      final api = FakeApi(species: [aSpecies('LION', 'Lion')]);
      final loader = ReferenceLoader(
        database: db,
        api: api,
        sessions: await usableSession(temp),
      );
      await loader.load();

      final snapshot = await loader.load(forceRefresh: true);
      expect(api.calls, 6, reason: 'retry must fetch even when cache is fresh');
      expect(snapshot.fromCache, isFalse);
    });

    test('signed out: the cache answers and no fetch is attempted', () async {
      final api = FakeApi(species: [aSpecies('LION', 'Lion')]);
      final loader = ReferenceLoader(
        database: db,
        api: api,
        sessions: SessionStore(file: File('${temp.path}/absent.json')),
      );

      final snapshot = await loader.load();
      expect(api.calls, 0);
      expect(snapshot.species, isEmpty);
      expect(snapshot.fromCache, isFalse);
    });

    test('signed out after a fetch: cached data still serves', () async {
      final api = FakeApi(species: [aSpecies('LION', 'Lion')]);
      final sessions = await usableSession(temp);
      final loader = ReferenceLoader(
        database: db,
        api: api,
        sessions: sessions,
      );
      await loader.load(); // seed with a session

      await sessions.clear(); // now signed out
      final signedOut = ReferenceLoader(
        database: db,
        api: FakeApi(),
        sessions: sessions,
      );

      final snapshot = await signedOut.load(forceRefresh: true);
      expect(snapshot.species.single.code, 'LION');
      expect(snapshot.refreshError, isNull);
    });

    test('falls back to the built-in reference lists when competencies are '
        'empty or retired', () async {
      final api = FakeApi(
        species: const [],
        outings: const [],
        competencies: [
          aCompetency('Old skill', 'Behaviour', retired: true),
          aCompetency('Unrelated', 'Navigation'),
        ],
      );
      final loader = ReferenceLoader(
        database: db,
        api: api,
        sessions: await usableSession(temp),
      );

      final snapshot = await loader.load();
      expect(snapshot.reference.behaviours, contains('grazing'));
      expect(snapshot.reference.ageSexClasses, contains('female'));
    });
  });
}
