import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A byte cache for map tiles that treats the network as optional.
///
/// The design prototype ships no basemap because offline is the point of the
/// client. A real map is still more use to a trainee in a vehicle than contour
/// bands alone, so tiles are added — but they are never allowed to become the
/// thing the screen depends on. This cache serves a tile from disk when it can,
/// from the network when it can, and reports failure plainly when it can do
/// neither.
/// There is no state in which a missing tile blanks the map.
///
/// Cached tiles are addressed by zoom, x, y and a source namespace, so the
/// cache key is derived from the coordinates rather than from a URL. The
/// namespace separates different tile hosts or styles: a MapTiler tile must
/// never silently read the bytes of an OpenStreetMap tile that happens to
/// share its coordinates, because the two are different pictures. Within one
/// source, the same tile fetched twice is one file.
class TileCache extends ChangeNotifier {
  TileCache({
    required this.directory,
    http.Client? client,
    this.maxBytes = 0,
    this.requestSpacing = const Duration(milliseconds: 120),
  }) : _client = client ?? http.Client();

  /// Where cached tiles live. The caller supplies this so tests can use a
  /// temporary directory and never touch the real one.
  final Directory directory;

  /// A ceiling on the cache, in bytes. Zero disables the eviction pass. The
  /// default is set by [TileCache.forDevice] because an unbounded cache on a
  /// phone is an outage waiting to happen: a trainee who pans across a reserve
  /// at several zoom levels will otherwise fill the device.
  final int maxBytes;

  final http.Client _client;
  final _pending = <String, Future<Uint8List?>>{};

  /// Minimum time between two network requests, shared by every tile in the
  /// cache. OpenStreetMap now rate-limits per IP on the higher, on-demand
  /// zoom levels, and a pan that fires thirty requests at once is precisely
  /// the burst that trips it (HTTP 403 "Access blocked"). Booking a slot
  /// before each request turns a burst into a smooth trickle — around eight
  /// tiles a second at the default spacing — which is the difference between
  /// looking around the map and being mistaken for a scraper.
  final Duration requestSpacing;

  /// When each tile source was refused by the server, keyed by the source
  /// namespace. A refused source rests until this time instead of being
  /// hammered again: the map degrades to the vector layer, which is the
  /// designed offline behaviour, and the block is not prolonged by retries.
  final Map<String, DateTime> _blockedUntil = {};

  /// The next moment a request may go out, shared across the whole cache.
  DateTime? _nextRequestAt;

  /// User-Agent required by OSM's tile usage policy. The URL names this app's
  /// real repository (github.com/chisimba-revival/mobile); OSM refuses
  /// requests whose identification is generic, spoofed or non-existent, so
  /// the contact has to be an address that actually resolves.
  /// See https://operations.osmfoundation.org/policies/tiles/
  static const _userAgent =
      'ChisimbaFieldLog/1.0 (+https://github.com/chisimba-revival/mobile)';

  /// The app's home, also sent on every tile request. OSM requires websites
  /// to identify via Referer and applications via User-Agent; sending both
  /// leaves no identification gap, whatever the block rules are checking.
  static const _referer = 'https://github.com/chisimba-revival/mobile';

  /// Open a cache in the application's own storage.
  ///
  /// Deliberately not the cache or documents directory: tile bytes are
  /// disposable, and the OS may reclaim them under storage pressure. Losing them
  /// costs a download, never a record.
  static Future<TileCache> forDevice({
    int maxBytes = 48 * 1024 * 1024,
    Duration requestSpacing = const Duration(milliseconds: 120),
  }) async {
    final support = await getApplicationSupportDirectory();
    return TileCache(
      directory: Directory(p.join(support.path, 'tiles')),
      maxBytes: maxBytes,
      requestSpacing: requestSpacing,
    );
  }

  /// A cache rooted in [path], for tests. No platform directories involved.
  static TileCache inDirectory(
    String path, {
    int maxBytes = 0,
    http.Client? client,
    Duration requestSpacing = const Duration(milliseconds: 120),
  }) => TileCache(
    directory: Directory(path),
    maxBytes: maxBytes,
    client: client,
    requestSpacing: requestSpacing,
  );

  /// Resolve one tile, or null when it is neither cached nor fetchable.
  ///
  /// A null return is an ordinary outcome and not an error: it is what an
  /// uncached tile looks like while offline, and the caller draws the vector
  /// layer for it. [fetch] decides whether the network is tried at all, so a
  /// caller that knows it is offline can skip the attempt entirely rather than
  /// paying a timeout per tile.
  Future<Uint8List?> tile(
    int zoom,
    int x,
    int y, {
    required Uri Function(int zoom, int x, int y) urlFor,
    bool Function()? fetch,
    Duration timeout = const Duration(seconds: 8),
    String source = '',
  }) async {
    final key = _keyFor(zoom, x, y, source);
    final onDisk = await _read(key);
    if (onDisk != null) {
      return onDisk;
    }
    if (fetch != null && !fetch()) {
      return null;
    }
    if (blocked(source)) {
      // A source the server refused is resting. Cached tiles still serve
      // (this check is after the disk read), but the network is not asked
      // again until the backoff expires.
      return null;
    }
    return _download(key, urlFor(zoom, x, y), timeout, source);
  }

  /// True while [source] is resting after the server refused it (HTTP 403 or
  /// 429). The map uses this to explain a missing basemap instead of showing
  /// nothing, and every fetch consults it so a refused source is not asked
  /// again during the rest.
  bool blocked(String source) {
    final until = _blockedUntil[source];
    return until != null && until.isAfter(DateTime.now());
  }

  /// Book the next request slot and wait for it.
  ///
  /// The slot is booked *before* the wait, so concurrent callers line up
  /// instead of all deciding to fire at the same moment: the first books n,
  /// the second books n + spacing, and the wall of parallel requests a pan
  /// wants to make becomes a stream no faster than one per [requestSpacing].
  Future<void> _pace() {
    final now = DateTime.now();
    final earliest = _nextRequestAt == null || !_nextRequestAt!.isAfter(now)
        ? now
        : _nextRequestAt!;
    _nextRequestAt = earliest.add(requestSpacing);
    return Future<void>.delayed(earliest.difference(now));
  }

  /// How many bytes are held, for the ledger screen to report.
  Future<int> bytesOnDisk() async {
    if (!await directory.exists()) {
      return 0;
    }
    var total = 0;
    // Recursive, because tiles are stored as zoom/x/y.tile. A plain list() of
    // the cache root only ever finds zoom directories, so a non-recursive walk
    // reports nothing and every total comes out as zero.
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Delete every cached tile.
  ///
  /// Offered deliberately rather than hidden: a trainee on a metered or shared
  /// connection may want the space back, and a cache the app owns but never
  /// offers to empty is a small grievance.
  Future<void> clear() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  /// The source namespace keeps different tile hosts or styles apart: two
  /// sources with the same coordinates are different pictures and must not
  /// share cache files. An empty source keeps the historical layout used by
  /// the OpenStreetMap tiles that predate the namespace.
  String _keyFor(int zoom, int x, int y, String source) =>
      source.isEmpty ? '$zoom/$x/$y.tile' : '$source/$zoom/$x/$y.tile';

  File _fileFor(String key) => File(p.join(directory.path, key));

  Future<Uint8List?> _read(String key) async {
    try {
      final file = _fileFor(key);
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsBytes();
    } on FileSystemException catch (error) {
      // A cache that cannot be read is a cache miss, not a crash. The tile is
      // simply not available offline, which is the same as not having it.
      debugPrint('tile cache could not read $key: ${error.message}');
      return null;
    }
  }

  /// Fetch and store, coalescing concurrent requests for the same tile.
  ///
  /// The in-flight map matters because the map asks for the same tile again the
  /// moment it is panned back over it, and without this a pan across a cached
  /// area fires one request per tile per frame.
  Future<Uint8List?> _download(
    String key,
    Uri url,
    Duration timeout,
    String source,
  ) {
    return _pending.putIfAbsent(key, () async {
      try {
        // The pace is shared across the whole cache, not per tile: this is
        // what keeps a pan that wants thirty tiles at once inside the
        // provider's per-IP limit.
        await _pace();
        final response = await _client
            .get(url, headers: {'User-Agent': _userAgent, 'Referer': _referer})
            .timeout(timeout);
        if (response.statusCode == 403 || response.statusCode == 429) {
          // The provider refuses this client: a block (403) or a rate limit
          // (429). Rest the whole source so the app stops asking — hammering
          // a limited IP is what turns a short block into a long one — and
          // notify the map, so it can say why the basemap is missing.
          _blockedUntil[source] = DateTime.now().add(
            response.statusCode == 429
                ? const Duration(minutes: 2)
                : const Duration(minutes: 10),
          );
          notifyListeners();
          debugPrint(
            'tile source "$source" refused (HTTP '
            '${response.statusCode}); resting it',
          );
          return null;
        }
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          return null;
        }
        final bytes = response.bodyBytes;
        await _write(key, bytes);
        return bytes;
      } on Object catch (error) {
        // Offline, DNS failure, timeout, a captive portal returning HTML: all
        // of these end with the vector layer drawn underneath and nothing lost.
        debugPrint('tile cache could not fetch $key: $error');
        return null;
      } finally {
        _pending.remove(key);
      }
    });
  }

  Future<void> _write(String key, Uint8List bytes) async {
    try {
      final file = _fileFor(key);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: false);
      if (maxBytes > 0) {
        await _evictIfNeeded();
      }
    } on FileSystemException catch (error) {
      // A cache that cannot be written still served the tile this time. The
      // next request will fetch it again, which is wasteful but not wrong.
      debugPrint('tile cache could not write $key: ${error.message}');
    }
  }

  /// Drop the least recently used tiles until the cache is back under its cap.
  ///
  /// Modification time stands in for recency: a tile read from disk is not
  /// touched, because touching every read to keep an LRU honest would turn a
  /// cache hit into a write. That makes this approximate LRU rather than exact,
  /// which is the right trade for the size of the effect — the tiles dropped
  /// are ones nobody has panned back over recently.
  Future<void> _evictIfNeeded() async {
    try {
      if (!await directory.exists()) {
        return;
      }
      if (maxBytes <= 0) {
        // Zero means unbounded, as the constructor documents. Without this the
        // walk below finds every tile, the total exceeds the budget, and a
        // cache that was explicitly told not to evict deletes itself.
        return;
      }
      final files = <_CacheFile>[];
      var total = 0;
      // Recursive: tiles live at zoom/x/y.tile, so a walk of the cache root
      // alone finds only directories and total stays zero, which makes the
      // budget check below pass on every write and the cache grow forever.
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            final length = stat.size;
            total += length;
            files.add(_CacheFile(entity, stat.modified, length));
          } on FileSystemException {
            // File disappeared between list and stat; skip it.
          }
        }
      }
      if (total <= maxBytes || files.isEmpty) {
        return;
      }

      files.sort((a, b) => a.modified.compareTo(b.modified));
      for (final cacheFile in files) {
        if (total <= maxBytes) {
          return;
        }
        try {
          await cacheFile.file.delete();
          total -= cacheFile.length;
        } on FileSystemException {
          // Already gone; length already subtracted from total.
        }
      }
    } on FileSystemException catch (error) {
      debugPrint('tile cache eviction failed: ${error.message}');
    }
  }
}

/// Internal record for a cache file with its metadata.
class _CacheFile {
  const _CacheFile(this.file, this.modified, this.length);

  final File file;
  final DateTime modified;
  final int length;
}
