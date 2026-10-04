import 'dart:io';
import 'dart:typed_data';

import 'package:field_log/map/tile_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Bytes standing in for a tile. This is the eight byte PNG signature, not a
/// decodable image, and nothing here decodes it: these tests are about which
/// bytes are stored, served and evicted, so any distinct byte string would do.
final aPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
]);

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('field_log_tiles');
  });

  tearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  TileCache cache({int maxBytes = 0, http.Client? client}) =>
      TileCache.inDirectory(directory.path, maxBytes: maxBytes, client: client);

  group('a tile that is cached', () {
    test('is served from disk without asking the network again', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response.bytes(aPng, 200);
      });
      final subject = cache(client: client);
      Uri urlFor(int z, int x, int y) =>
          Uri.parse('https://tiles.test/1/2/3.png');

      final first = await subject.tile(1, 2, 3, urlFor: urlFor);
      expect(first, isNotNull);
      expect(requests, 1);

      final second = await subject.tile(1, 2, 3, urlFor: urlFor);
      expect(second, isNotNull);
      expect(
        requests,
        1,
        reason: 'the second read is a cache hit, so nothing is fetched',
      );
    });
  });

  group('a tile that is not cached', () {
    test('returns nothing when the caller knows it is offline', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response.bytes(aPng, 200);
      });
      final subject = cache(client: client);

      final bytes = await subject.tile(
        4,
        5,
        6,
        urlFor: (z, x, y) => Uri.parse('https://tiles.test/4/5/6.png'),
        fetch: () => false,
      );

      expect(bytes, isNull);
      expect(
        requests,
        0,
        reason: 'an offline caller must not pay a timeout per tile',
      );
    });

    test(
      'returns nothing rather than throwing when the network fails',
      () async {
        final client = MockClient(
          (request) async => throw const SocketException('no route'),
        );
        final subject = cache(client: client);

        final bytes = await subject.tile(
          7,
          8,
          9,
          urlFor: (z, x, y) => Uri.parse('https://tiles.test/7/8/9.png'),
        );

        expect(
          bytes,
          isNull,
          reason: 'a missing tile is an outcome, not a crash',
        );
      },
    );
  });

  group('the cache is keyed by tile, not by url', () {
    test('so the same tile is one file however it is asked for', () async {
      final first = MockClient(
        (request) async => http.Response.bytes(aPng, 200),
      );
      await cache(client: first).tile(
        10,
        11,
        12,
        urlFor: (z, x, y) => Uri.parse('https://one.test/10/11/12.png'),
      );

      var secondHostRequests = 0;
      final second = MockClient((request) async {
        secondHostRequests++;
        return http.Response.bytes(aPng, 200);
      });
      // Same z/x/y, different host, same directory. The key does not mention
      // the host, so this is a hit on the first host's bytes and no request is
      // made. That is the documented trade-off rather than an accident: one
      // file per tile is what makes a repeat fetch free, and it is correct as
      // long as every tile comes from one source. Change the source and the
      // cache has to be cleared, which is why clear() is public. Asserting it
      // here is what keeps it from quietly becoming a bug.
      final bytes = await cache(client: second).tile(
        10,
        11,
        12,
        urlFor: (z, x, y) => Uri.parse('https://two.test/10/11/12.png'),
      );

      expect(bytes, isNotNull);
      expect(secondHostRequests, 0);
    });

    test('and clear is what a provider change has to call', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(aPng, 200),
      );
      final subject = cache(client: client);
      await subject.tile(
        13,
        1,
        1,
        urlFor: (z, x, y) => Uri.parse('https://one.test/13/1/1.png'),
      );
      expect(await subject.bytesOnDisk(), greaterThan(0));

      await subject.clear();
      expect(await subject.bytesOnDisk(), 0);
    });
  });

  group('a cache with a byte budget', () {
    test('evicts the least recently written tile', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(aPng, 200),
      );
      final subject = cache(maxBytes: aPng.length * 2, client: client);

      Uri url(int n) => Uri.parse('https://tiles.test/1/$n/1.png');

      await subject.tile(1, 1, 1, urlFor: (z, x, y) => url(1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subject.tile(1, 2, 1, urlFor: (z, x, y) => url(2));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // A third tile over budget evicts the oldest.
      await subject.tile(1, 3, 1, urlFor: (z, x, y) => url(3));

      expect(
        await subject.tile(1, 3, 1, urlFor: (z, x, y) => url(3)),
        isNotNull,
      );
      // Asserting on the file, not on a second tile() call: a miss against a
      // live MockClient just refetches and hands back bytes, so asking again
      // would pass whether or not the eviction happened.
      expect(
        File('${directory.path}/1/1/1.tile').existsSync(),
        isFalse,
        reason: 'the oldest tile was evicted',
      );
      expect(File('${directory.path}/1/2/1.tile').existsSync(), isTrue);
    });
  });
}
