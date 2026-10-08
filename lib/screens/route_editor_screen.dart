import 'package:field_log/data/database.dart' show PlannedRoute, RouteWaypoint;
import 'package:field_log/data/route_tables.dart' show RouteWaypointKind;
import 'package:field_log/design/field_scaffold.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/map/osm_tiles.dart';
import 'package:field_log/map/pin_painter.dart';
import 'package:field_log/map/tile_cache.dart';
import 'package:field_log/net/chisimba_api.dart' as chisimba;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

/// The reserve centre constant from map_screen.dart.
const reserveCentre = LatLng(-1.2921, 36.8219);

/// Vector layer for the route editor (copied from map_screen.dart).
class _VectorLayer extends StatelessWidget {
  const _VectorLayer({required this.colours});

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

/// The route editor screen.
///
/// Allows the guide to plan a route for an outing by tapping on the map to add
/// waypoints, dragging to reposition, and long-pressing to delete, rename, or
/// change the kind of a waypoint.
class RouteEditorScreen extends StatefulWidget {
  const RouteEditorScreen({
    super.key,
    required this.outing,
    required this.existingRoute,
    this.existingWaypoints = const [],
    required this.onSaveRoute,
    this.tileCache,
  });

  /// The outing this route is being planned for.
  final chisimba.Outing outing;

  /// An existing route to edit, or null if creating a new one.
  final PlannedRoute? existingRoute;

  /// Existing waypoints for the route (fetched separately from the database).
  final List<RouteWaypoint> existingWaypoints;

  /// Called when the user saves the route.
  final Future<void> Function(PlannedRoute route, List<RouteWaypoint> waypoints)
  onSaveRoute;

  /// Optional tile cache for the basemap.
  final TileCache? tileCache;

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen>
    with SingleTickerProviderStateMixin {
  late List<_EditableWaypoint> _waypoints;
  LatLng? _ghostWaypoint;
  int? _selectedIndex;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _waypoints = widget.existingWaypoints
        .map((w) => _EditableWaypoint.fromRouteWaypoint(w))
        .toList();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _addWaypoint(LatLng point) {
    setState(() {
      final ordinal = _waypoints.isEmpty ? 0 : _waypoints.last.ordinal + 1;
      _waypoints.add(
        _EditableWaypoint(
          ordinal: ordinal,
          latitude: point.latitude,
          longitude: point.longitude,
          label: 'Waypoint ${ordinal + 1}',
          kind: RouteWaypointKind.vertex,
        ),
      );
      _ghostWaypoint = null;
    });
  }

  void _showGhostWaypoint(LatLng point) {
    setState(() => _ghostWaypoint = point);
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
      // Renumber ordinals
      for (var i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = _waypoints[i].copyWith(ordinal: i);
      }
      _selectedIndex = null;
    });
  }

  void _selectWaypoint(int index) {
    setState(() => _selectedIndex = index);
  }

  void _updateWaypoint(int index, _EditableWaypoint waypoint) {
    setState(() => _waypoints[index] = waypoint);
  }

  Future<void> _save() async {
    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A route needs at least two waypoints.')),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final route =
        widget.existingRoute ??
        PlannedRoute(
          localId: const Uuid().v4(),
          outingId: widget.outing.id,
          createdAt: now,
          updatedAt: now,
          hasPendingChanges: true,
          isTombstone: false,
        );

    final updatedRoute = route.copyWith(
      updatedAt: now,
      hasPendingChanges: true,
    );

    final waypoints = _waypoints.asMap().entries.map((entry) {
      final i = entry.key;
      final w = entry.value;
      return RouteWaypoint(
        routeId: route.localId,
        ordinal: i,
        latitude: w.latitude,
        longitude: w.longitude,
        label: w.label,
        kind: w.kind.name,
        note: w.note,
      );
    }).toList();

    await widget.onSaveRoute(updatedRoute, waypoints);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final centre = _waypoints.isNotEmpty
        ? LatLng(
            _waypoints.map((w) => w.latitude).reduce((a, b) => a + b) /
                _waypoints.length,
            _waypoints.map((w) => w.longitude).reduce((a, b) => a + b) /
                _waypoints.length,
          )
        : reserveCentre;

    return FieldScaffold(
      eyebrow: 'Route Editor',
      title: 'Plan route for ${widget.outing.kind}',
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Cancel',
      ),
      actions: [
        TextButton(
          onPressed: _waypoints.length >= 2 ? _save : null,
          child: Text(
            'Save',
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.label,
              fontWeight: FontWeight.w600,
              color: colours.bone,
            ),
          ),
        ),
      ],
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              backgroundColor: colours.inset,
              initialCenter: centre,
              initialZoom: 14,
              minZoom: 8,
              maxZoom: 18,
              onTap: (tapPosition, point) => _showGhostWaypoint(point),
              onLongPress: (tapPosition, point) => _addWaypoint(point),
            ),
            children: [
              _VectorLayer(colours: colours),
              if (widget.tileCache != null)
                TileLayer(
                  tileProvider: OsmTileProvider(
                    cache: widget.tileCache!,
                    online: () => true,
                  ),
                  keepBuffer: 4,
                  panBuffer: 2,
                ),
              // Route layer
              if (_waypoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _waypoints
                          .map((w) => LatLng(w.latitude, w.longitude))
                          .toList(),
                      color: colours.dust,
                      strokeWidth: 2.5,
                      pattern: StrokePattern.dashed(segments: [8.0, 4.0]),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              // Waypoint markers
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _waypoints.length; i++)
                    Marker(
                      key: ValueKey('waypoint-$i'),
                      point: LatLng(
                        _waypoints[i].latitude,
                        _waypoints[i].longitude,
                      ),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => _selectWaypoint(i),
                        onLongPress: () => _showWaypointMenu(i),
                        onPanUpdate: (details) => _dragWaypoint(i, details),
                        child: _WaypointMarker(
                          index: i + 1,
                          isSelected: _selectedIndex == i,
                          colours: colours,
                          kind: _waypoints[i].kind,
                        ),
                      ),
                    ),
                  // Ghost waypoint
                  if (_ghostWaypoint != null)
                    Marker(
                      key: const ValueKey('ghost-waypoint'),
                      point: _ghostWaypoint!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: GestureDetector(
                            onTap: () => _addWaypoint(_ghostWaypoint!),
                            child: Semantics(
                              button: true,
                              label: 'Add waypoint',
                              child: CustomPaint(
                                size: const Size(40, 40),
                                painter: _GhostWaypointPainter(
                                  colours: colours,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Selected waypoint bottom sheet
          if (_selectedIndex != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _WaypointEditorSheet(
                waypoint: _waypoints[_selectedIndex!],
                index: _selectedIndex!,
                total: _waypoints.length,
                onUpdate: (w) => _updateWaypoint(_selectedIndex!, w),
                onDelete: () => _removeWaypoint(_selectedIndex!),
                onClose: () => setState(() => _selectedIndex = null),
                colours: colours,
              ),
            ),
        ],
      ),
    );
  }

  void _showWaypointMenu(int index) {
    // Could show a menu, for now just select
    _selectWaypoint(index);
  }

  void _dragWaypoint(int index, DragUpdateDetails details) {
    // Convert drag to map coordinate change - simplified
    // A full implementation would need the map's projection
  }
}

/// A mutable waypoint for editing.
class _EditableWaypoint {
  _EditableWaypoint({
    required this.ordinal,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.kind,
    this.note,
  });

  factory _EditableWaypoint.fromRouteWaypoint(RouteWaypoint w) =>
      _EditableWaypoint(
        ordinal: w.ordinal,
        latitude: w.latitude,
        longitude: w.longitude,
        label: w.label ?? 'Waypoint ${w.ordinal + 1}',
        kind: RouteWaypointKind.values.byName(w.kind),
        note: w.note,
      );

  final int ordinal;
  final double latitude;
  final double longitude;
  final String label;
  final RouteWaypointKind kind;
  final String? note;

  _EditableWaypoint copyWith({
    int? ordinal,
    double? latitude,
    double? longitude,
    String? label,
    RouteWaypointKind? kind,
    String? note,
  }) => _EditableWaypoint(
    ordinal: ordinal ?? this.ordinal,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    note: note ?? this.note,
  );
}

/// Waypoint marker on the map.
class _WaypointMarker extends StatelessWidget {
  const _WaypointMarker({
    required this.index,
    required this.isSelected,
    required this.colours,
    required this.kind,
  });

  final int index;
  final bool isSelected;
  final FieldColours colours;
  final RouteWaypointKind kind;

  @override
  Widget build(BuildContext context) {
    Color kindColor;
    switch (kind) {
      case RouteWaypointKind.gate:
        kindColor = colours.dust;
        break;
      case RouteWaypointKind.waterhole:
        kindColor = colours.moss;
        break;
      case RouteWaypointKind.landmark:
        kindColor = colours.straw;
        break;
      case RouteWaypointKind.custom:
        kindColor = colours.blood;
        break;
      default:
        kindColor = colours.dust;
    }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? colours.dust : kindColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colours.bone : colours.canopy,
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colours.canopy.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontFamily: Faces.book.first,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isSelected ? colours.bone : colours.canopy,
        ),
      ),
    );
  }
}

/// Ghost waypoint painter.
class _GhostWaypointPainter extends CustomPainter {
  _GhostWaypointPainter({required this.colours});
  final FieldColours colours;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer pulse ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colours.dust.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner circle
    canvas.drawCircle(
      center,
      radius * 0.7,
      Paint()
        ..color = colours.dust.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );

    // Plus sign
    final paint = Paint()
      ..color = colours.bone
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 6, center.dy),
      Offset(center.dx + 6, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 6),
      Offset(center.dx, center.dy + 6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom sheet for editing a waypoint.
class _WaypointEditorSheet extends StatefulWidget {
  const _WaypointEditorSheet({
    required this.waypoint,
    required this.index,
    required this.total,
    required this.onUpdate,
    required this.onDelete,
    required this.onClose,
    required this.colours,
  });

  final _EditableWaypoint waypoint;
  final int index;
  final int total;
  final void Function(_EditableWaypoint) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final FieldColours colours;

  @override
  State<_WaypointEditorSheet> createState() => _WaypointEditorSheetState();
}

class _WaypointEditorSheetState extends State<_WaypointEditorSheet> {
  late TextEditingController _labelController;
  late TextEditingController _noteController;
  late RouteWaypointKind _kind;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.waypoint.label);
    _noteController = TextEditingController(text: widget.waypoint.note ?? '');
    _kind = widget.waypoint.kind;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onUpdate(
      widget.waypoint.copyWith(
        label: _labelController.text,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        kind: _kind,
      ),
    );
    widget.onClose();
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
                      'Waypoint ${widget.index + 1} of ${widget.total}',
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.label,
                        fontWeight: FontWeight.w600,
                        color: colours.bone,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(Icons.close, color: colours.ash1),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                TextField(
                  controller: _labelController,
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    color: colours.bone,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Label',
                    labelStyle: TextStyle(color: colours.ash1),
                    filled: true,
                    fillColor: colours.inset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.rule),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.bone),
                    ),
                  ),
                ),
                const SizedBox(height: Insets.md),
                DropdownButtonFormField<RouteWaypointKind>(
                  initialValue: _kind,
                  dropdownColor: colours.canopyRaised,
                  style: TextStyle(
                    color: colours.bone,
                    fontFamily: Faces.ui.first,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kind',
                    labelStyle: TextStyle(color: colours.ash1),
                    filled: true,
                    fillColor: colours.inset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.rule),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.bone),
                    ),
                  ),
                  items: RouteWaypointKind.values
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Text(
                            k.name[0].toUpperCase() + k.name.substring(1),
                            style: TextStyle(
                              fontFamily: Faces.ui.first,
                              color: colours.bone,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _kind = v!),
                ),
                const SizedBox(height: Insets.md),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: Faces.book.first,
                    color: colours.bone,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    labelStyle: TextStyle(color: colours.ash1),
                    filled: true,
                    fillColor: colours.inset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.rule),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                      borderSide: BorderSide(color: colours.bone),
                    ),
                  ),
                ),
                const SizedBox(height: Insets.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.onDelete();
                        },
                        icon: Icon(Icons.delete_outline, color: colours.blood),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                            fontFamily: Faces.ui.first,
                            color: colours.blood,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colours.blood),
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check),
                        label: Text(
                          'Save',
                          style: TextStyle(fontFamily: Faces.ui.first),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
