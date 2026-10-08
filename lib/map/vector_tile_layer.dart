import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pmtiles/pmtiles.dart';

/// A vector tile layer that reads MVT tiles from a PMTiles archive.
///
/// This is a simplified implementation that uses flutter_map's TileLayer
/// with a custom TileProvider that reads from PMTiles. The actual MVT
/// rendering would need a vector tile renderer; this provides the tile
/// fetching infrastructure.
class PmTilesVectorLayer extends StatefulWidget {
  const PmTilesVectorLayer({
    super.key,
    required this.archivePath,
    this.maxZoom = 18,
    this.layerStyles = const {},
  });

  /// Path to the PMTiles file (asset or file system path).
  final String archivePath;

  /// Maximum zoom level to fetch tiles for.
  final int maxZoom;

  /// Styling rules for each layer in the vector tiles.
  ///
  /// The key is the layer name as it appears in the MVT (e.g., 'boundary',
  /// 'roads', 'waterholes', 'acacia', 'contours', 'contours_index').
  final Map<String, VectorLayerStyle> layerStyles;

  @override
  State<PmTilesVectorLayer> createState() => _PmTilesVectorLayerState();
}

class _PmTilesVectorLayerState extends State<PmTilesVectorLayer> {
  PmTilesArchive? _archive;

  @override
  void initState() {
    super.initState();
    _openArchive();
  }

  Future<void> _openArchive() async {
    try {
      _archive = await PmTilesArchive.from(widget.archivePath);
      debugPrint('Opened PMTiles archive: ${_archive!.header}');
    } catch (e) {
      debugPrint('Failed to open PMTiles archive: $e');
    }
  }

  @override
  void dispose() {
    _archive?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_archive == null) {
      return const SizedBox.shrink();
    }

    // For now, return a placeholder that shows the archive is loaded.
    // Full MVT rendering would require a vector tile renderer.
    // This provides the infrastructure for fetching tiles from PMTiles.
    return TileLayer(
      tileProvider: _PmTilesProvider(
        archive: _archive!,
        maxZoom: widget.maxZoom,
      ),
    );
  }
}

/// TileProvider that reads tiles from a PMTiles archive.
class _PmTilesProvider extends TileProvider {
  _PmTilesProvider({required this.archive, required this.maxZoom});

  final PmTilesArchive archive;
  final int maxZoom;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // This provider returns a placeholder image.
    // In a full implementation, this would return an ImageProvider
    // that renders the MVT tile content.
    return _PmTilesImage(
      archive: archive,
      coordinates: coordinates,
      layerStyles: const {},
    );
  }
}

/// Placeholder image provider for PMTiles.
class _PmTilesImage extends ImageProvider<_PmTilesImage> {
  _PmTilesImage({
    required this.archive,
    required this.coordinates,
    required this.layerStyles,
  });

  final PmTilesArchive archive;
  final TileCoordinates coordinates;
  final Map<String, VectorLayerStyle> layerStyles;

  @override
  Future<_PmTilesImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _PmTilesImage key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_loadTile());
  }

  Future<ImageInfo> _loadTile() async {
    try {
      final tileId = ZXY(
        coordinates.z,
        coordinates.x,
        coordinates.y,
      ).toTileId();

      final tile = await archive.tile(tileId);
      final bytes = tile.bytes();

      if (bytes.isEmpty) {
        final codec = await ui.instantiateImageCodec(
          TileProvider.transparentImage,
        );
        final frame = await codec.getNextFrame();
        return ImageInfo(image: frame.image);
      }

      // For now, return a placeholder. Full MVT rendering would decode
      // the protobuf and render vector features.
      final codec = await ui.instantiateImageCodec(
        TileProvider.transparentImage,
      );
      final frame = await codec.getNextFrame();
      return ImageInfo(image: frame.image);
    } catch (e) {
      debugPrint('Failed to load PMTiles tile: $e');
      final codec = await ui.instantiateImageCodec(
        TileProvider.transparentImage,
      );
      final frame = await codec.getNextFrame();
      return ImageInfo(image: frame.image);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _PmTilesImage &&
      other.archive == archive &&
      other.coordinates == coordinates;

  @override
  int get hashCode => Object.hash(archive, coordinates);
}

/// Style for a vector tile layer.
class VectorLayerStyle {
  const VectorLayerStyle({
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    this.fillOpacity = 1.0,
    this.strokeOpacity = 1.0,
    this.minZoom = 0,
    this.maxZoom = 22,
    this.labelProperty,
    this.labelStyle,
    this.labelMinZoom = 12,
  });

  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final double fillOpacity;
  final double strokeOpacity;
  final int minZoom;
  final int maxZoom;
  final String? labelProperty;
  final TextStyle? labelStyle;
  final int labelMinZoom;
}

/// Default layer styles matching the reserve palette from the prototype.
///
/// These styles define how each vector tile layer should be rendered.
/// The layer names match the expected MVT layer names from the PMTiles export.
Map<String, VectorLayerStyle> get defaultVectorLayerStyles => {
  // Reserve boundary
  'boundary': VectorLayerStyle(
    fillColor: const Color(0xFF3D352B), // acaciaBark
    fillOpacity: 0.1,
    strokeColor: const Color(0xFF3D352B), // acaciaBark
    strokeWidth: 2.0,
    minZoom: 8,
    maxZoom: 18,
  ),

  // Roads
  'roads': VectorLayerStyle(
    strokeColor: const Color(0xFF6B5B4D), // dryGrass
    strokeWidth: 1.5,
    minZoom: 10,
    maxZoom: 18,
  ),

  // Waterholes (points)
  'waterholes': VectorLayerStyle(
    fillColor: const Color(0xFFF5C542), // dawnGold
    strokeColor: const Color(0xFF3D352B), // acaciaBark
    strokeWidth: 1.5,
    minZoom: 10,
    maxZoom: 18,
    labelProperty: 'name',
    labelStyle: const TextStyle(
      fontFamily: 'LibreBaskerville',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1510), // canopyText
    ),
    labelMinZoom: 12,
  ),

  // Acacia stands
  'acacia': VectorLayerStyle(
    fillColor: const Color(0xFF6B5B4D), // dryGrass
    fillOpacity: 0.15,
    minZoom: 10,
    maxZoom: 18,
  ),

  // Contours (10m)
  'contours': VectorLayerStyle(
    strokeColor: const Color(0xFF3D352B), // acaciaBark
    strokeWidth: 0.5,
    strokeOpacity: 0.3,
    minZoom: 12,
    maxZoom: 18,
  ),

  // Index contours (50m) with labels
  'contours_index': VectorLayerStyle(
    strokeColor: const Color(0xFF3D352B), // acaciaBark
    strokeWidth: 1.0,
    strokeOpacity: 0.5,
    minZoom: 10,
    maxZoom: 18,
    labelProperty: 'elevation',
    labelStyle: const TextStyle(
      fontFamily: 'LibreBaskerville',
      fontSize: 9,
      fontWeight: FontWeight.w500,
      color: Color(0xFF3D352B), // acaciaBark
    ),
    labelMinZoom: 12,
  ),
};
