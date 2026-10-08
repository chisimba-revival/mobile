import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';

/// A byte cache for map tiles that treats the network as optional.
///
/// The design prototype ships no basemap because offline is the point of the
/// client. A real map is still more use to a trainee in a vehicle than contour
/// bands alone, so tiles are added — but they are never allowed to become the
/// thing the screen depends on. This cache serves a tile from disk when it can,
/// from the network when it can, and reports failure plainly when it can do
/// neither, so the caller can fall back to the vector layer underneath. There
/// is no state in which a missing tile blanks the map.
///
/// Cached tiles are addressed by zoom, x and y, so the cache key is derived from
/// the coordinates rather than from a URL. That means a different tile host with
/// different styling cannot silently read another host's tiles, and it means
/// the same tile fetched twice is one file.
class TileCache {
  TileCache({
    required this.directory,
    http.Client? client,
    this.maxBytes = 0,
    this.pmtilesArchive,
  }) : _client = client ?? http.Client();

  /// Where cached tiles live. The caller supplies this so tests can use a
  /// temporary directory and never touch the real one.
  final Directory directory;

  /// A ceiling on the cache, in bytes. Zero disables the eviction pass. The
  /// default is set by [TileCache.forDevice] because an unbounded cache on a
  /// phone is an outage waiting to happen: a trainee who pans across a reserve
  /// at several zoom levels will otherwise fill the device.
  final int maxBytes;

  /// Optional PMTiles archive for vector tiles.
  ///
  /// If provided, vector tiles are served from this archive instead of the
  /// network. The archive is a single .pmtiles file that contains all vector
  /// tiles for the reserve.
  final PmTilesArchive? pmtilesArchive;

  final http.Client _client;
  final _pending = <String, Future<Uint8List?>>{};

  static const _userAgent = 'field-log/1.0 (offline field client)';

  /// Open a cache in the application's own storage.
  ///
  /// Deliberately not the cache or documents directory: tile bytes are
  /// disposable, and the OS may reclaim them under storage pressure. Losing them
  /// costs a download, never a record.
  static Future<TileCache> forDevice({
    int maxBytes = 48 * 1024 * 1024,
    String? pmtilesPath,
  }) async {
    final support = await getApplicationSupportDirectory();
    PmTilesArchive? archive;
    if (pmtilesPath != null) {
      try {
        archive = await PmTilesArchive.from(pmtilesPath);
      } catch (e) {
        debugPrint('Failed to open PMTiles archive: $e');
      }
    }
    return TileCache(
      directory: Directory(p.join(support.path, 'tiles')),
      maxBytes: maxBytes,
      pmtilesArchive: archive,
    );
  }

  /// A cache rooted in [path], for tests. No platform directories involved.
  static TileCache inDirectory(
    String path, {
    int maxBytes = 0,
    http.Client? client,
    PmTilesArchive? pmtilesArchive,
  }) => TileCache(
    directory: Directory(path),
    maxBytes: maxBytes,
    client: client,
    pmtilesArchive: pmtilesArchive,
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
  }) async {
    final key = _keyFor(zoom, x, y);
    final onDisk = await _read(key);
    if (onDisk != null) {
      return onDisk;
    }
    if (fetch != null && !fetch()) {
      return null;
    }
    return _download(key, urlFor(zoom, x, y), timeout);
  }

  /// Resolve a vector tile from the PMTiles archive.
  ///
  /// Returns the raw MVT bytes for the given tile coordinates, or null if the
  /// archive is not available or the tile doesn't exist. This is used by the
  /// vector tile layer to render vector features.
  Future<Uint8List?> vectorTile(int zoom, int x, int y) async {
    if (pmtilesArchive == null) {
      return null;
    }
    try {
      final tileId = ZXY(zoom, x, y).toTileId();
      final tile = await pmtilesArchive!.tile(tileId);
      final bytes = tile.bytes();
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('Failed to load vector tile $zoom/$x/$y: $e');
      return null;
    }
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

  String _keyFor(int zoom, int x, int y) => '$zoom/$x/$y.tile';

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
  Future<Uint8List?> _download(String key, Uri url, Duration timeout) {
    return _pending.putIfAbsent(key, () async {
      try {
        final response = await _client
            .get(url, headers: {'User-Agent': _userAgent})
            .timeout(timeout);
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
      final files = <File>[];
      var total = 0;
      // Recursive: tiles live at zoom/x/y.tile, so a walk of the cache root
      // alone finds only directories and total stays zero, which makes the
      // budget check below pass on every write and the cache grow forever.
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
          files.add(entity);
        }
      }
      if (total <= maxBytes || files.isEmpty) {
        return;
      }

      files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      for (final file in files) {
        if (total <= maxBytes) {
          return;
        }
        final length = await file.length();
        await file.delete();
        total -= length;
      }
    } on FileSystemException catch (error) {
      debugPrint('tile cache eviction failed: ${error.message}');
    }
  }
}
