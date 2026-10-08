import 'package:field_log/data/recent_species.dart';
import 'package:field_log/field/card_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SpeciesChoice choice(String code, {String common = 'Common'}) => SpeciesChoice(
  code: code,
  commonName: common,
  scientificName: 'Scientificus $code',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecentSpecies', () {
    test('starts empty', () async {
      final recents = await RecentSpecies.open();
      expect(await recents.list(), isEmpty);
    });

    test('notes a species and reads it back, newest first', () async {
      final recents = await RecentSpecies.open();
      await recents.note(choice('ELEPH'));
      await recents.note(choice('LION'));

      final list = await recents.list();
      expect(list.map((s) => s.code), ['LION', 'ELEPH']);
      expect(list.first.commonName, 'Common');
      expect(list.first.scientificName, 'Scientificus LION');
    });

    test(
      'moves a repeat sighting to the front instead of duplicating',
      () async {
        final recents = await RecentSpecies.open();
        await recents.note(choice('ELEPH'));
        await recents.note(choice('LION'));
        await recents.note(choice('ELEPH'));

        final list = await recents.list();
        expect(list.map((s) => s.code), ['ELEPH', 'LION']);
      },
    );

    test('trims to the cap of eight', () async {
      final recents = await RecentSpecies.open();
      for (var i = 0; i < 12; i++) {
        await recents.note(choice('SP$i'));
      }

      final list = await recents.list();
      expect(list, hasLength(8));
      expect(list.first.code, 'SP11', reason: 'newest first');
      expect(list.last.code, 'SP4', reason: 'oldest trimmed away');
    });

    test('ignores an empty code', () async {
      final recents = await RecentSpecies.open();
      await recents.note(choice(''));
      expect(await recents.list(), isEmpty);
    });

    test('survives a corrupt stored value', () async {
      SharedPreferences.setMockInitialValues({
        'recent_species': 'not json at all',
      });
      final recents = await RecentSpecies.open();
      expect(await recents.list(), isEmpty);

      // And the store remains usable afterwards.
      await recents.note(choice('ELEPH'));
      expect((await recents.list()).single.code, 'ELEPH');
    });
  });
}
