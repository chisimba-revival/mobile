import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:field_log/map/pin_painter.dart';
import 'package:field_log/design/tokens.dart';

/// A vector layer that paints the reserve's surveyed features (boundary, roads,
/// waterholes, contours) using a [CustomPainter].
///
/// This is the fallback when no PMTiles archive is available, or when the
/// PMTiles archive fails to load.
import 'package:field_log/map/vector_tile_layer.dart';
class VectorLayer extends StatelessWidget {
  const VectorLayer({required this.colours, super.key});

  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return MobileLayerTransformer(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ReserveVectorPainter(colours: colours),
          size: Size.infinite,
        ),
      ),
    );
  }
}
