import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'mvt_decoder.dart';
import 'vector_tile_layer.dart';

/// Rasterizes decoded MVT layers into a single transparent [ui.Image].
///
/// Geometry arrives in extent coordinates (tippecanoe's default is 4096)
/// and is scaled so a full tile fills [pixelSize] pixels. Stroke widths and
/// label sizes are expressed relative to a 256px tile, so symbols keep a
/// constant on-screen size whatever zoom the tile is drawn at, matching how
/// the style widths read in a 256px tile view.
///
/// A fully transparent image is returned when there is nothing to draw,
/// which lets the tile stack show the basemap through it. The image is
/// always rasterized at [pixelSize] x [pixelSize]; the caller decides the
/// factor (512 = 2x of the 256px logical tile, crisp on 1x and 2x displays).
Future<ui.Image> renderMvtTile({
  required List<MvtLayer> layers,
  required Map<String, VectorLayerStyle> styles,
  required int zoom,
  double pixelSize = 512,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  for (final layer in layers) {
    final style = styles[layer.name];
    if (style == null) continue;
    if (zoom < style.minZoom || zoom > style.maxZoom) continue;
    _paintLayer(canvas, layer, style, zoom, pixelSize);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(pixelSize.round(), pixelSize.round());
  picture.dispose();
  return image;
}

/// The default raster size. Tiles are 256px logical in flutter_map; 512px
/// gives sharp rendering on 1x and 2x displays.
const double kMvtTilePixelSize = 512;

void _paintLayer(
  Canvas canvas,
  MvtLayer layer,
  VectorLayerStyle style,
  int zoom,
  double pixelSize,
) {
  final scale = pixelSize / layer.extent;
  canvas.save();
  canvas.scale(scale, scale);

  for (final feature in layer.features) {
    switch (feature.type) {
      case MvtGeometryType.polygon:
        _paintPolygon(canvas, feature, style, layer.extent);
      case MvtGeometryType.lineString:
        _paintLine(canvas, feature, style, layer.extent);
      case MvtGeometryType.point:
        _paintPoint(canvas, feature, style, layer.extent);
      case MvtGeometryType.unknown:
        break;
    }
  }

  canvas.restore();

  if (zoom >= style.labelMinZoom && style.labelProperty != null) {
    _paintLabels(canvas, layer, style, pixelSize);
  }
}

/// Logical-pixel width expressed in extent units for a 256px tile.
double _width(double styleWidth, int extent) => styleWidth * extent / 256;

void _paintPolygon(
  Canvas canvas,
  MvtFeature feature,
  VectorLayerStyle style,
  int extent,
) {
  final rings = feature.paths.where((r) => r.length >= 3).toList();
  if (rings.isEmpty) return;

  final fill = ui.Path()..fillType = ui.PathFillType.evenOdd;
  for (final ring in rings) {
    fill.moveTo(ring.first.dx, ring.first.dy);
    for (final p in ring.skip(1)) {
      fill.lineTo(p.dx, p.dy);
    }
    fill.close();
  }

  final fillColor = style.fillColor;
  if (fillColor != null) {
    canvas.drawPath(
      fill,
      Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor.withValues(alpha: style.fillOpacity),
    );
  }

  // Outline the outer ring only; the fill already carves the holes with the
  // even-odd rule, and stroking every ring would outline the holes too.
  final strokeColor = style.strokeColor;
  if (strokeColor != null && style.strokeWidth > 0) {
    final outer = rings.first;
    final path = ui.Path()..moveTo(outer.first.dx, outer.first.dy);
    for (final p in outer.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _width(style.strokeWidth, extent)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor.withValues(alpha: style.strokeOpacity),
    );
  }
}

void _paintLine(
  Canvas canvas,
  MvtFeature feature,
  VectorLayerStyle style,
  int extent,
) {
  final strokeColor = style.strokeColor;
  if (strokeColor == null || style.strokeWidth <= 0) return;

  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _width(style.strokeWidth, extent)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = strokeColor.withValues(alpha: style.strokeOpacity);

  for (final path in feature.paths) {
    if (path.length < 2) continue;
    final p = ui.Path()..moveTo(path.first.dx, path.first.dy);
    for (final point in path.skip(1)) {
      p.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(p, paint);
  }
}

void _paintPoint(
  Canvas canvas,
  MvtFeature feature,
  VectorLayerStyle style,
  int extent,
) {
  final fillColor = style.fillColor ?? style.strokeColor;
  if (fillColor == null) return;

  // A point's on-screen radius grows with its priority: the stroke width is
  // styleable per layer, which is how waterholes stay small but visible.
  final radius = _width(32, extent);

  for (final path in feature.paths) {
    final p = path.first;
    canvas.drawCircle(
      p,
      radius,
      Paint()..color = fillColor.withValues(alpha: style.fillOpacity),
    );
    final strokeColor = style.strokeColor;
    if (strokeColor != null && style.strokeWidth > 0) {
      canvas.drawCircle(
        p,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _width(style.strokeWidth, extent)
          ..color = strokeColor.withValues(alpha: style.strokeOpacity),
      );
    }
  }
}

/// The value of [style.labelProperty] for [feature], if present.
String? _labelFor(MvtFeature feature, MvtLayer layer, String property) {
  final tags = feature.tags;
  for (var i = 0; i + 1 < tags.length; i += 2) {
    final keyIdx = tags[i];
    final valueIdx = tags[i + 1];
    if (keyIdx >= layer.keys.length || valueIdx >= layer.values.length) {
      continue;
    }
    if (layer.keys[keyIdx] == property) {
      final value = layer.values[valueIdx].value;
      if (value != null) return value.toString();
    }
  }
  return null;
}

/// Anchor for a label: the centroid of a point, the midway point of a line,
/// or the bounds centre of a polygon's largest ring.
ui.Offset _labelAnchor(MvtFeature feature) {
  if (feature.paths.isEmpty) return ui.Offset.zero;
  final primary = feature.paths.first;
  if (primary.isEmpty) return ui.Offset.zero;

  if (feature.type == MvtGeometryType.polygon) {
    var minX = primary.first.dx, maxX = minX;
    var minY = primary.first.dy, maxY = minY;
    for (final p in primary) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return ui.Offset((minX + maxX) / 2, (minY + maxY) / 2);
  }

  if (feature.type == MvtGeometryType.lineString) {
    return primary[primary.length ~/ 2];
  }

  return primary.first;
}

void _paintLabels(
  Canvas canvas,
  MvtLayer layer,
  VectorLayerStyle style,
  double pixelSize,
) {
  final property = style.labelProperty!;
  final baseStyle = style.labelStyle;
  if (baseStyle == null) return;

  final textScale = pixelSize / 256;

  for (final feature in layer.features) {
    final text = _labelFor(feature, layer, property);
    if (text == null || text.isEmpty) continue;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 10) * textScale,
          shadows: [
            const Shadow(color: Color(0x99FFFFFF), blurRadius: 3),
            const Shadow(color: Color(0x66FFFFFF), blurRadius: 1),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final anchor = _labelAnchor(feature);
    final x = anchor.dx * (pixelSize / layer.extent) - painter.width / 2;
    final y = anchor.dy * (pixelSize / layer.extent) - painter.height / 2;
    painter.paint(canvas, ui.Offset(x, y));
  }
}
