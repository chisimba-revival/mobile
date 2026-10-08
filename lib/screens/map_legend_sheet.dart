import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:field_log/map/vector_tile_layer.dart';

/// A bottom sheet for the map legend and layer visibility toggles.
///
/// Shows all vector tile layers with color swatches, labels, and visibility
/// switches. Persists visibility state in SharedPreferences.
class MapLegendSheet extends StatefulWidget {
  const MapLegendSheet({
    super.key,
    required this.layerStyles,
    required this.onVisibilityChanged,
    this.initialVisibility,
  });

  /// The layer styles from the vector tile layer.
  final Map<String, VectorLayerStyle> layerStyles;

  /// Called when a layer's visibility is toggled.
  final void Function(String layerName, bool visible) onVisibilityChanged;

  /// Initial visibility state for each layer. If null, all layers are visible.
  final Map<String, bool>? initialVisibility;

  @override
  State<MapLegendSheet> createState() => _MapLegendSheetState();
}

class _MapLegendSheetState extends State<MapLegendSheet> {
  late Map<String, bool> _visibility;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _visibility = Map.fromEntries(
      widget.layerStyles.keys.map(
        (k) => MapEntry(k, widget.initialVisibility?[k] ?? true),
      ),
    );
  }

  void _toggleLayer(String layerName) {
    setState(() {
      _visibility[layerName] = !(_visibility[layerName] ?? true);
    });
    widget.onVisibilityChanged(layerName, _visibility[layerName]!);
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colours.canopyRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Corners.sheet),
            ),
            border: Border(top: BorderSide(color: colours.rule)),
          ),
          child: Column(
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

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.xs,
                  Insets.lg,
                  Insets.md,
                ),
                child: Row(
                  children: [
                    Text(
                      'Map Layers',
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.cardTitle,
                        fontWeight: FontWeight.w600,
                        color: colours.bone,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: colours.ash1,
                      ),
                    ),
                  ],
                ),
              ),

              // Layer list
              if (_isExpanded)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                    children: [
                      _LegendSection(
                        title: 'Features',
                        children: [
                          _LegendRow(
                            layerName: 'waterholes',
                            label: 'Waterholes',
                            style: defaultVectorLayerStyles['waterholes']!,
                            visible: _visibility['waterholes'] ?? true,
                            onToggle: _toggleLayer,
                            colours: colours,
                          ),
                          _LegendRow(
                            layerName: 'roads',
                            label: 'Roads',
                            style: defaultVectorLayerStyles['roads']!,
                            visible: _visibility['roads'] ?? true,
                            onToggle: _toggleLayer,
                            colours: colours,
                          ),
                          _LegendRow(
                            layerName: 'acacia',
                            label: 'Acacia Stands',
                            style: defaultVectorLayerStyles['acacia']!,
                            visible: _visibility['acacia'] ?? true,
                            onToggle: _toggleLayer,
                            colours: colours,
                          ),
                          _LegendRow(
                            layerName: 'boundary',
                            label: 'Reserve Boundary',
                            style: defaultVectorLayerStyles['boundary']!,
                            visible: _visibility['boundary'] ?? true,
                            onToggle: _toggleLayer,
                            colours: colours,
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                      _LegendSection(
                        title: 'Terrain',
                        children: [
                          _LegendRow(
                            layerName: 'contours_index',
                            label: 'Index Contours (50m)',
                            style: defaultVectorLayerStyles['contours_index']!,
                            visible: _visibility['contours_index'] ?? true,
                            onToggle: _toggleLayer,
                            colours: colours,
                          ),
                          _LegendRow(
                            layerName: 'contours',
                            label: 'Contours (10m)',
                            style: defaultVectorLayerStyles['contours']!,
                            visible: _visibility['contours'] ?? true,
                            onToggle: _toggleLayer,
                            colours: colours,
                          ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                      _LegendSection(
                        title: 'Reference',
                        children: [
                          _LegendRow(
                            layerName: 'boundary',
                            label: 'Reserve Boundary',
                            style: defaultVectorLayerStyles['boundary']!,
                            visible: _visibility['boundary'] ?? true,
                            onToggle: _toggleLayer,
                            colours: colours,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A section in the legend with a title and child rows.
class _LegendSection extends StatelessWidget {
  const _LegendSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.supporting,
            fontWeight: FontWeight.w600,
            color: colours.ash1,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: Insets.xs),
        ...children,
      ],
    );
  }
}

/// A single legend row with color swatch, label, and visibility toggle.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.layerName,
    required this.label,
    required this.style,
    required this.visible,
    required this.onToggle,
    required this.colours,
  });

  final String layerName;
  final String label;
  final VectorLayerStyle style;
  final bool visible;
  final void Function(String) onToggle;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 1.0 : 0.4,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: _Swatch(style: style, colours: colours),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.body,
            color: visible ? colours.bone : colours.ash3,
          ),
        ),
        trailing: Switch(
          value: visible,
          onChanged: (_) => onToggle(layerName),
          activeThumbColor: colours.dust,
          activeTrackColor: colours.dust.withValues(alpha: 0.3),
          inactiveThumbColor: colours.ash3,
          inactiveTrackColor: colours.ash4.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// A color swatch showing the layer's fill and stroke.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.style, required this.colours});

  final VectorLayerStyle style;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    final hasFill = style.fillColor != null;
    final hasStroke = style.strokeColor != null;

    return Container(
      width: 32,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Corners.control),
        border: hasStroke
            ? Border.all(
                color: (style.strokeColor ?? colours.ash1).withValues(
                  alpha: style.strokeOpacity,
                ),
                width: style.strokeWidth,
              )
            : null,
        color: hasFill
            ? (style.fillColor ?? colours.ash1).withValues(
                alpha: style.fillOpacity,
              )
            : null,
      ),
    );
  }
}
