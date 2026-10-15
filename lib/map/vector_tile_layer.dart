import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pmtiles/pmtiles.dart';

import 'mvt_decoder.dart';
import 'mvt_renderer.dart';

import 'package:field_log/design/tokens.dart';

/// A style definition for a vector tile layer.
///
/// Used by the PMTiles vector layer renderer to style MVT layers.
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

/// The reserve's map symbols, built from the active design tokens.
///
/// The archive tags every feature with a `kind` — boundary, contours, roads,
/// waterholes, acacia — so the keys here are those kinds (plus the synthetic
/// `contours_index` for the heavier index lines). Everything adapts to the
/// app's settings rather than being fixed:
///
/// * [colours] supplies every colour, so the light/dark appearance and the
///   high-contrast and sepia variants all carry through to the map.
/// * [density] scales the stroke weights and point sizes.
/// * [preset] decides what the map leans on: survey on the ground (boundary
///   and contours), navigation on the ways through it (roads and water),
///   field on the habitat (vegetation and water).
Map<String, VectorLayerStyle> reserveVectorStyles({
  required FieldColours colours,
  Density density = Density.comfortable,
  MapStylePreset preset = MapStylePreset.field,
}) {
  final scale = density.scale;
  double w(double base) => base * scale;

  final survey = preset == MapStylePreset.survey;
  final navigation = preset == MapStylePreset.navigation;

  // Labels always use a dark ink: the renderer paints a light halo behind
  // them, so the contrast comes from the halo and works on light or dark
  // ground alike. `inkOn` would tie the ink to the palette and lose that.
  const labelInk = Color(0xFF1A1510);

  return {
    // Reserve boundary — the reference outline, strongest under survey.
    'boundary': VectorLayerStyle(
      fillColor: colours.straw,
      fillOpacity: 0.06,
      strokeColor: survey ? colours.bone : colours.ash1,
      strokeWidth: w(survey ? 3.0 : 2.4),
      minZoom: 5,
      maxZoom: 18,
    ),

    // Roads — the ways through the reserve, strongest under navigation.
    'roads': VectorLayerStyle(
      strokeColor: navigation ? colours.bone : colours.ash2,
      strokeWidth: w(navigation ? 2.6 : 2.0),
      minZoom: navigation ? 6 : 7,
      maxZoom: 18,
    ),

    // Waterholes (points) with their names.
    'waterholes': VectorLayerStyle(
      fillColor: colours.water,
      strokeColor: colours.bone,
      strokeWidth: w(1.5),
      minZoom: 6,
      maxZoom: 18,
      labelProperty: 'name',
      labelStyle: const TextStyle(
        fontFamily: 'LibreBaskerville',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: labelInk,
      ),
      labelMinZoom: 12,
    ),

    // Acacia stands — the habitat layer, strongest under field.
    'acacia': VectorLayerStyle(
      fillColor: colours.moss,
      fillOpacity: preset == MapStylePreset.field ? 0.24 : 0.14,
      strokeColor: colours.moss,
      strokeWidth: w(1.0),
      strokeOpacity: 0.7,
      minZoom: 6,
      maxZoom: 18,
    ),

    // Intermediate contours (10m).
    'contours': VectorLayerStyle(
      strokeColor: colours.contour,
      strokeWidth: w(0.6),
      strokeOpacity: survey ? 0.6 : 0.4,
      minZoom: survey ? 9 : 11,
      maxZoom: 18,
    ),

    // Index contours (50m) with elevation labels.
    'contours_index': VectorLayerStyle(
      strokeColor: colours.contour,
      strokeWidth: w(1.2),
      strokeOpacity: 0.85,
      minZoom: 9,
      maxZoom: 18,
      labelProperty: 'elevation',
      labelStyle: const TextStyle(
        fontFamily: 'LibreBaskerville',
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: labelInk,
      ),
      labelMinZoom: 12,
    ),
  };
}

/// The reserve's default symbols for callers with no theme context (the
/// painted fallback and legend swatches), expressed in the dark palette.
Map<String, VectorLayerStyle> get defaultVectorLayerStyles =>
    reserveVectorStyles(colours: FieldColours.dark);

/// A vector tile layer for reserve features (boundaries, roads, water, vegetation, contours).
///
/// Visual design principles:
/// - All reserve features are **muted and low-contrast** so pins, route, and GPS
///   fix remain the visual focus. The map is a canvas; the data is the paint.
/// - Each layer has an independent opacity control (0.0–1.0) exposed via
///   [ReserveLayerConfig], defaulting to subtle values.
/// - Colors are chosen from the design's [FieldColours] palette so light/dark
///   themes both work without custom theming.
/// - At zoom < 12, only the reserve boundary shows (context). At zoom ≥ 12,
///   roads, water, vegetation, and contours appear progressively.
class ReserveVectorLayer extends StatelessWidget {
  const ReserveVectorLayer({
    super.key,
    required this.config,
    required this.colours,
    this.tileProvider,
  });

  final ReserveLayerConfig config;
  final FieldColours colours;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    // When a PMTiles source is available, use it as a single tile layer.
    // Otherwise, return an empty widget — the programmatic layers are added
    // directly to FlutterMap's children list in map_screen.dart.
    if (tileProvider != null) {
      return TileLayer(
        tileProvider: tileProvider!,
        keepBuffer: 4,
        panBuffer: 2,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Builds the list of programmatic reserve layers for FlutterMap.
///
/// Call this from map_screen.dart's FlutterMap children when no tileProvider
/// is configured. Returns layers in z-order: boundary → roads → water.
List<Widget> buildProgrammaticReserveLayers({
  required ReserveLayerConfig config,
  required FieldColours colours,
}) {
  final layers = <Widget>[];

  if (!config.showBoundary) return layers;

  // Example reserve boundary (roughly Big 5 Reserve area)
  final boundary = <LatLng>[
    LatLng(-24.15, 31.60),
    LatLng(-24.15, 31.85),
    LatLng(-24.35, 31.85),
    LatLng(-24.35, 31.60),
    LatLng(-24.15, 31.60),
  ];

  // Boundary polygon (always shown for context)
  layers.add(
    PolygonLayer(
      polygons: [
        Polygon(
          points: boundary,
          color: colours.straw.withValues(alpha: config.boundaryOpacity * 0.3),
          borderColor: colours.straw.withValues(alpha: config.boundaryOpacity),
          borderStrokeWidth: 1.5,
        ),
      ],
    ),
  );

  // Detail layers only at zoom >= minZoomForDetails (handled by map zoom, not here)
  if (config.minZoomForDetails <= 12) {
    // Major management roads
    if (config.showRoads) {
      layers.add(
        PolylineLayer(
          polylines: [
            Polyline(
              points: [
                LatLng(-24.15, 31.72),
                LatLng(-24.25, 31.72),
                LatLng(-24.25, 31.80),
              ],
              color: colours.ash2.withValues(alpha: config.roadsOpacity),
              strokeWidth: 1.5,
              pattern: StrokePattern.dashed(segments: [6.0, 4.0]),
            ),
            Polyline(
              points: [LatLng(-24.20, 31.60), LatLng(-24.20, 31.85)],
              color: colours.ash2.withValues(alpha: config.roadsOpacity),
              strokeWidth: 1.5,
              pattern: StrokePattern.dashed(segments: [6.0, 4.0]),
            ),
          ],
        ),
      );
    }

    // Water features
    if (config.showWater) {
      layers.add(
        PolygonLayer(
          polygons: [
            Polygon(
              points: [
                LatLng(-24.22, 31.68),
                LatLng(-24.23, 31.68),
                LatLng(-24.23, 31.70),
                LatLng(-24.22, 31.70),
                LatLng(-24.22, 31.68),
              ],
              color: colours.moss.withValues(alpha: config.waterOpacity),
              borderColor: colours.moss.withValues(
                alpha: config.waterOpacity * 1.5,
              ),
              borderStrokeWidth: 0.8,
            ),
          ],
        ),
      );
    }
  }

  return layers;
}

/// Configuration for each reserve vector layer.
///
/// All values are clamped to sensible ranges; the defaults are deliberately
/// subtle so the reserve data never competes with sighting pins or the route.
class ReserveLayerConfig {
  const ReserveLayerConfig({
    this.boundaryOpacity = 0.35,
    this.roadsOpacity = 0.25,
    this.waterOpacity = 0.20,
    this.vegetationOpacity = 0.15,
    this.contoursOpacity = 0.18,
    this.showBoundary = true,
    this.showRoads = true,
    this.showWater = true,
    this.showVegetation = true,
    this.showContours = true,
    this.minZoomForDetails = 12,
  });

  /// Reserve boundary polygon outline + fill.
  final double boundaryOpacity;

  /// Road network (tracks, management roads).
  final double roadsOpacity;

  /// Water features (rivers, pans, dams).
  final double waterOpacity;

  /// Vegetation communities (acacia, mopane, grassland).
  final double vegetationOpacity;

  /// Elevation contours (10m interval).
  final double contoursOpacity;

  /// Master toggles for each layer.
  final bool showBoundary;
  final bool showRoads;
  final bool showWater;
  final bool showVegetation;
  final bool showContours;

  /// Below this zoom, only the boundary is drawn (context view).
  final int minZoomForDetails;

  ReserveLayerConfig copyWith({
    double? boundaryOpacity,
    double? roadsOpacity,
    double? waterOpacity,
    double? vegetationOpacity,
    double? contoursOpacity,
    bool? showBoundary,
    bool? showRoads,
    bool? showWater,
    bool? showVegetation,
    bool? showContours,
    int? minZoomForDetails,
  }) => ReserveLayerConfig(
    boundaryOpacity: (boundaryOpacity ?? this.boundaryOpacity).clamp(0.0, 0.6),
    roadsOpacity: (roadsOpacity ?? this.roadsOpacity).clamp(0.0, 0.5),
    waterOpacity: (waterOpacity ?? this.waterOpacity).clamp(0.0, 0.4),
    vegetationOpacity: (vegetationOpacity ?? this.vegetationOpacity).clamp(
      0.0,
      0.35,
    ),
    contoursOpacity: (contoursOpacity ?? this.contoursOpacity).clamp(0.0, 0.4),
    showBoundary: showBoundary ?? this.showBoundary,
    showRoads: showRoads ?? this.showRoads,
    showWater: showWater ?? this.showWater,
    showVegetation: showVegetation ?? this.showVegetation,
    showContours: showContours ?? this.showContours,
    minZoomForDetails: (minZoomForDetails ?? this.minZoomForDetails).clamp(
      8,
      16,
    ),
  );
}

/// Bottom sheet for toggling reserve vector layers and adjusting opacity.
///
/// Follows the same design language as the fold menu: slides up from the
/// bottom, dark backdrop, sectioned controls with clear labels.
class ReserveLayerBottomSheet extends StatefulWidget {
  const ReserveLayerBottomSheet({
    super.key,
    required this.config,
    required this.colours,
    required this.onChanged,
    this.muteBasemap = true,
    this.onMuteBasemapChanged,
  });

  final ReserveLayerConfig config;
  final FieldColours colours;
  final ValueChanged<ReserveLayerConfig> onChanged;
  final bool muteBasemap;
  final ValueChanged<bool>? onMuteBasemapChanged;

  @override
  State<ReserveLayerBottomSheet> createState() =>
      _ReserveLayerBottomSheetState();
}

class _ReserveLayerBottomSheetState extends State<ReserveLayerBottomSheet> {
  late ReserveLayerConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _update(ReserveLayerConfig next) {
    setState(() => _config = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colours = widget.colours;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Corners.sheet),
        ),
        border: Border(top: BorderSide(color: colours.rule)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: Insets.sm),
            decoration: BoxDecoration(
              color: colours.ruleStrong,
              borderRadius: BorderRadius.circular(Corners.chip),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Reserve Map Layers',
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.label,
                        fontWeight: FontWeight.w600,
                        color: colours.bone,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: colours.ash1),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                // Basemap mute toggle (only relevant for OSM tiles)
                _BasemapMuteToggle(
                  value: widget.muteBasemap,
                  onChanged:
                      widget.onMuteBasemapChanged ??
                      (v) {}, // No-op if not provided
                  colours: colours,
                ),
                const SizedBox(height: Insets.sm),
                _LayerToggle(
                  label: 'Reserve Boundary',
                  subtitle: 'Fence line & extent',
                  value: _config.showBoundary,
                  onChanged: (v) => _update(_config.copyWith(showBoundary: v)),
                  opacity: _config.boundaryOpacity,
                  onOpacityChanged: (v) =>
                      _update(_config.copyWith(boundaryOpacity: v)),
                  colour: colours.straw,
                  colours: colours,
                ),
                const SizedBox(height: Insets.sm),
                _LayerToggle(
                  label: 'Management Roads',
                  subtitle: 'Tracks & access routes',
                  value: _config.showRoads,
                  onChanged: (v) => _update(_config.copyWith(showRoads: v)),
                  opacity: _config.roadsOpacity,
                  onOpacityChanged: (v) =>
                      _update(_config.copyWith(roadsOpacity: v)),
                  colour: colours.ash2,
                  colours: colours,
                  enabled: _config.minZoomForDetails <= 12,
                ),
                const SizedBox(height: Insets.sm),
                _LayerToggle(
                  label: 'Water Features',
                  subtitle: 'Rivers, pans, dams',
                  value: _config.showWater,
                  onChanged: (v) => _update(_config.copyWith(showWater: v)),
                  opacity: _config.waterOpacity,
                  onOpacityChanged: (v) =>
                      _update(_config.copyWith(waterOpacity: v)),
                  colour: colours.moss,
                  colours: colours,
                  enabled: _config.minZoomForDetails <= 12,
                ),
                const SizedBox(height: Insets.sm),
                _LayerToggle(
                  label: 'Vegetation',
                  subtitle: 'Acacia, mopane, grassland',
                  value: _config.showVegetation,
                  onChanged: (v) =>
                      _update(_config.copyWith(showVegetation: v)),
                  opacity: _config.vegetationOpacity,
                  onOpacityChanged: (v) =>
                      _update(_config.copyWith(vegetationOpacity: v)),
                  colour: colours.moss,
                  colours: colours,
                  enabled: _config.minZoomForDetails <= 12,
                ),
                const SizedBox(height: Insets.sm),
                _LayerToggle(
                  label: 'Contours (10 m)',
                  subtitle: 'Elevation lines',
                  value: _config.showContours,
                  onChanged: (v) => _update(_config.copyWith(showContours: v)),
                  opacity: _config.contoursOpacity,
                  onOpacityChanged: (v) =>
                      _update(_config.copyWith(contoursOpacity: v)),
                  colour: colours.ash1,
                  colours: colours,
                  enabled: _config.minZoomForDetails <= 12,
                ),
                const SizedBox(height: Insets.lg),
                _Supporting(
                  'Layers appear at zoom ≥ ${_config.minZoomForDetails}. '
                  'Lower opacity = more subtle. Pins and route always stay on top.',
                  colours,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({
    super.key,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.opacity,
    required this.onOpacityChanged,
    required this.colour,
    required this.colours,
    this.enabled = true,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double opacity;
  final ValueChanged<double> onOpacityChanged;
  final Color colour;
  final FieldColours colours;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: value ? colour : colours.inset,
                  border: Border.all(color: colour, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.body,
                        color: colours.bone,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.stamp,
                        color: colours.ash2,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: colour,
                activeTrackColor: colour.withValues(alpha: 0.3),
                inactiveThumbColor: colours.ash3,
                inactiveTrackColor: colours.inset,
              ),
            ],
          ),
          if (value && enabled) ...[
            const SizedBox(height: Insets.xs),
            Row(
              children: [
                const SizedBox(width: 28),
                Text(
                  'Opacity',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    color: colours.ash2,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Slider(
                    value: opacity,
                    min: 0.0,
                    max: _maxOpacityForLabel(label),
                    divisions: 10,
                    activeColor: colour,
                    inactiveColor: colours.inset,
                    onChanged: onOpacityChanged,
                  ),
                ),
                Text(
                  '${(opacity * 100).round()}%',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    color: colours.ash2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _maxOpacityForLabel(String label) {
    switch (label) {
      case 'Reserve Boundary':
        return 0.6;
      case 'Management Roads':
        return 0.5;
      case 'Water Features':
        return 0.4;
      case 'Vegetation':
        return 0.35;
      case 'Contours (10 m)':
        return 0.4;
      default:
        return 0.5;
    }
  }
}

class _Supporting extends StatelessWidget {
  const _Supporting(this.text, this.colours);

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Faces.ui.first,
        fontSize: Faces.supporting,
        height: 1.4,
        color: colours.ash3,
      ),
    );
  }
}

/// Toggle for muting the OSM basemap (desaturate + darken).
/// Only applies when using OSM tiles (no MapTiler key).
class _BasemapMuteToggle extends StatelessWidget {
  const _BasemapMuteToggle({
    required this.value,
    required this.onChanged,
    required this.colours,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: value ? colours.straw : colours.inset,
            border: Border.all(color: colours.straw, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basemap Style',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.body,
                  color: colours.bone,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value ? 'Muted (pins pop)' : 'Full colour',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.stamp,
                  color: colours.ash2,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colours.straw,
          activeTrackColor: colours.straw.withValues(alpha: 0.3),
          inactiveThumbColor: colours.ash3,
          inactiveTrackColor: colours.inset,
        ),
      ],
    );
  }
}

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

    // Render the archive's MVT tiles. An empty style map means "use the
    // reserve's default style".
    return TileLayer(
      tileProvider: _PmTilesProvider(
        archive: _archive!,
        maxZoom: widget.maxZoom,
        layerStyles: widget.layerStyles.isNotEmpty
            ? widget.layerStyles
            : defaultVectorLayerStyles,
      ),
    );
  }
}

/// A stable fingerprint of a style map, for the tile image cache.
///
/// Flutter keys decoded images by [ImageProvider] equality, so the styles have
/// to be part of that equality: otherwise a palette, density, preset or
/// visibility change would keep serving the tiles drawn with the old styles.
/// The values are joined in sorted key order so map ordering cannot change the
/// fingerprint.
@visibleForTesting
String pmTilesStyleSignature(Map<String, VectorLayerStyle> styles) {
  final keys = styles.keys.toList()..sort();
  final buffer = StringBuffer();
  for (final key in keys) {
    final s = styles[key]!;
    buffer
      ..write(key)
      ..write('\u0000')
      ..write(s.fillColor?.toARGB32() ?? '')
      ..write('\u0000')
      ..write(s.strokeColor?.toARGB32() ?? '')
      ..write('\u0000')
      ..write(s.strokeWidth)
      ..write('\u0000')
      ..write(s.fillOpacity)
      ..write('\u0000')
      ..write(s.strokeOpacity)
      ..write('\u0000')
      ..write(s.minZoom)
      ..write('\u0000')
      ..write(s.maxZoom)
      ..write('\u0000')
      ..write(s.labelProperty ?? '')
      ..write('\u0000')
      ..write(s.labelMinZoom)
      ..write('\u0000')
      ..write(s.labelStyle?.color?.toARGB32() ?? '')
      ..write('\u0000')
      ..write(s.labelStyle?.fontSize ?? '')
      ..write('\u0000');
  }
  return buffer.toString();
}

/// TileProvider that reads tiles from a PMTiles archive.
class _PmTilesProvider extends TileProvider {
  _PmTilesProvider({
    required this.archive,
    required this.maxZoom,
    required this.layerStyles,
  }) : styleSignature = pmTilesStyleSignature(layerStyles);

  final PmTilesArchive archive;
  final int maxZoom;
  final Map<String, VectorLayerStyle> layerStyles;
  final String styleSignature;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _PmTilesImage(
      archive: archive,
      coordinates: coordinates,
      layerStyles: layerStyles,
      styleSignature: styleSignature,
    );
  }
}

/// Placeholder image provider for PMTiles.
class _PmTilesImage extends ImageProvider<_PmTilesImage> {
  _PmTilesImage({
    required this.archive,
    required this.coordinates,
    required this.layerStyles,
    required this.styleSignature,
  });

  final PmTilesArchive archive;
  final TileCoordinates coordinates;
  final Map<String, VectorLayerStyle> layerStyles;
  final String styleSignature;

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
      final bytes = Uint8List.fromList(tile.bytes());

      if (bytes.isEmpty) return await _transparentTile();

      final layers = decodeMvtTile(bytes);
      if (layers.isEmpty) return await _transparentTile();

      final image = await renderMvtTile(
        layers: layers,
        styles: layerStyles,
        zoom: coordinates.z,
      );
      return ImageInfo(image: image);
    } catch (e) {
      debugPrint('Failed to render PMTiles tile: $e');
      return await _transparentTile();
    }
  }

  Future<ImageInfo> _transparentTile() async {
    final codec = await ui.instantiateImageCodec(TileProvider.transparentImage);
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image);
  }

  @override
  bool operator ==(Object other) =>
      other is _PmTilesImage &&
      other.archive == archive &&
      other.coordinates == coordinates &&
      other.styleSignature == styleSignature;

  @override
  int get hashCode => Object.hash(archive, coordinates, styleSignature);
}

/// A custom painter that renders reserve vector features.
///
/// Used when no PMTiles archive is available — renders a simplified
/// painted map with boundary, roads, and water features.
class ReserveVectorPainter extends CustomPainter {
  ReserveVectorPainter({required this.colours, this.hiddenLayers = const {}});

  final FieldColours colours;
  final Set<String> hiddenLayers;

  @override
  void paint(Canvas canvas, Size size) {
    // Boundary
    if (!hiddenLayers.contains('boundary')) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = colours.straw.withValues(alpha: 0.5);
      final rect = Rect.fromLTWH(20, 20, size.width - 40, size.height - 40);
      canvas.drawRect(rect, paint);
    }

    // Contours
    if (!hiddenLayers.contains('contours')) {
      final contourPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = colours.contour.withValues(alpha: 0.3);
      for (var i = 0; i < 5; i++) {
        final y = size.height * (0.2 + i * 0.15);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), contourPaint);
      }
    }

    // Roads
    if (!hiddenLayers.contains('roads')) {
      final roadPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = colours.ash2.withValues(alpha: 0.4);
      canvas.drawLine(
        Offset(size.width * 0.1, size.height * 0.1),
        Offset(size.width * 0.9, size.height * 0.9),
        roadPaint,
      );
    }

    // Waterholes
    if (!hiddenLayers.contains('waterholes')) {
      final waterPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = colours.water.withValues(alpha: 0.3);
      canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.4),
        12,
        waterPaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.6),
        8,
        waterPaint,
      );
    }

    // Acacia stands
    if (!hiddenLayers.contains('acacia')) {
      final acaciaPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = colours.moss.withValues(alpha: 0.2);
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.3),
        20,
        acaciaPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReserveVectorPainter oldDelegate) =>
      oldDelegate.colours != colours ||
      oldDelegate.hiddenLayers != hiddenLayers;
}
