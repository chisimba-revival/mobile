import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import 'tile_cache.dart';

/// OpenStreetMap raster tiles, served out of a disk cache.
///
/// The design's prototype ships no basemap at all, on the grounds that offline
/// is the point. That is right about the *dependency* and wrong about the
/// consequence: a field guide with no map is a field guide with no idea where
/// anything is. So the tiles are wanted, and the offline case is engineered
/// rather than avoided.
///
/// A tile that is neither cached nor reachable returns null, which renders as
/// nothing at all, and the vector contour layer underneath shows through. That
/// is a legible map without basemap rather than a grey square with a spinner:
/// the contours, the water and the boundary are local data and are always
/// present. Nothing here blocks on the network, and nothing waits for a
/// timeout before the trainee can place a pin.
///
/// A null tile is not an error. It is the expected state of the app in a
/// vehicle with no signal, which is the situation this was built for.
class OsmTileProvider extends TileProvider {
  OsmTileProvider({
    required this.cache,
    required this.online,
    this.template = defaultUrlTemplate,
    super.headers,
  });

  /// OpenStreetMap's own tile service. No key, no account, no billing, and a
  /// usage policy that a single trainee's phone does not strain.
  static const defaultUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// A visible attribution is a condition of using these tiles, not a
  /// courtesy, so it is a constant here rather than something each screen
  /// might forget.
  static const attribution = '© OpenStreetMap contributors';

  final TileCache cache;

  /// Consulted before every request, so the app can stop asking the network
  /// the moment it knows there is none, rather than discovering it tile by tile.
  final bool Function() online;

  final String template;

  /// Builds the tile URL from the template.
  ///
  /// The package's own populateTemplatePlaceholders is marked protected, so it
  /// is not callable from here, and getTileUrl reads the template off the layer
  /// rather than one passed in. Substituting the three placeholders is the whole
  /// of what an {z}/{x}/{y} template needs.
  String _urlFor(int z, int x, int y) => template
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final bytes = cache.tile(
      coordinates.z,
      coordinates.x,
      coordinates.y,
      urlFor: (z, x, y) => Uri.parse(_urlFor(z, x, y)),
      // Knowing we are offline skips the request outright rather than paying a
      // timeout on every tile the viewport wants.
      fetch: online,
    );

    return _CachedTileImage(bytes);
  }
}

/// Serves bytes that are already in hand, or nothing at all.
///
/// [ImageProvider] rather than a widget, because the tile layer drives its own
/// painting. The bytes may still be arriving from disk or the network, so this
/// hands back a provider that resolves later; the tile layer is built to wait.
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  _CachedTileImage(this._bytes);

  final Future<Uint8List?> _bytes;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration _) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(key._resolve());
  }

  Future<ImageInfo> _resolve() async {
    final bytes = await _bytes;

    // Nothing cached and nothing reachable. flutter_map already carries a
    // transparent PNG for exactly this case, so there is no reason to keep a
    // second copy of one here.
    final image = (bytes == null || bytes.isEmpty)
        ? TileProvider.transparentImage
        : bytes;

    final completer = Completer<ImageInfo>();
    // A tile that cannot be decoded is a tile that is not drawn. It must not
    // take the map down with it, so the failure travels as this future's error
    // and the layer reports it rather than propagating it into the widget tree.
    // decodeImageFromList hands back a raw ui.Image; ImageInfo is the wrapper
    // the image stream wants, carrying the scale alongside it.
    ui.decodeImageFromList(
      image,
      (decoded) => completer.complete(ImageInfo(image: decoded)),
    );
    return completer.future;
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage && other._bytes == _bytes;

  @override
  int get hashCode => _bytes.hashCode;
}
