import 'package:field_log/data/database.dart' show PlannedRoute, RouteWaypoint;
import 'package:field_log/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'dart:math' as math;

/// Paints a planned route on the map: dashed line + numbered waypoint markers.
///
/// The route line uses [dust] on both themes, 2.5px dashed 8/4 with round caps.
/// Waypoint markers are 24px circles with kind color fill, [canopy] 2px stroke,
/// order number in bookSerif 10px centered.
/// Active segment (next waypoint) is solid [dust] 3px with pulse animation.
/// POI waypoints (gate, waterhole, landmark, custom) show their kind color and label.
class RouteLayer extends StatelessWidget {
  const RouteLayer({
    super.key,
    required this.route,
    required this.waypoints,
    required this.colours,
    required this.currentPosition,
    this.animation,
  });

  /// The planned route to display.
  final PlannedRoute route;

  /// The waypoints for this route, sorted by ordinal.
  final List<RouteWaypoint> waypoints;

  /// Current GPS position, used to determine the active segment. Null while
  /// there is no fix: the route still draws, but no segment can be called
  /// "ahead" of a position that is not known, so none is highlighted.
  final LatLng? currentPosition;

  /// Colours for the current theme.
  final FieldColours colours;

  /// Optional animation for active segment pulse.
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    if (waypoints.length < 2) {
      return const SizedBox.shrink();
    }

    // Sort waypoints by ordinal
    final sortedWaypoints = List<RouteWaypoint>.from(waypoints)
      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));

    // Determine active segment (next waypoint ahead of current position). With
    // no fix there is no active segment: -1 leaves the dashed route intact.
    final activeIndex = currentPosition == null
        ? -1
        : _findActiveSegment(sortedWaypoints, currentPosition!);

    final points = sortedWaypoints
        .map((w) => LatLng(w.latitude, w.longitude))
        .toList();

    return Stack(
      children: [
        // Full route as dashed line
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              color: colours.dust,
              strokeWidth: 2.5,
              pattern: StrokePattern.dashed(segments: [8.0, 4.0]),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        ),
        // Active segment as solid line with pulse
        if (activeIndex >= 0 && activeIndex < sortedWaypoints.length - 1)
          _AnimatedActiveSegment(
            start: LatLng(
              sortedWaypoints[activeIndex].latitude,
              sortedWaypoints[activeIndex].longitude,
            ),
            end: LatLng(
              sortedWaypoints[activeIndex + 1].latitude,
              sortedWaypoints[activeIndex + 1].longitude,
            ),
            colour: colours.dust,
            animation: animation,
          ),
        // Waypoint markers
        MarkerLayer(
          markers: [
            for (var i = 0; i < sortedWaypoints.length; i++)
              _makeWaypointMarker(
                point: LatLng(
                  sortedWaypoints[i].latitude,
                  sortedWaypoints[i].longitude,
                ),
                index: sortedWaypoints[i].ordinal + 1,
                isActive: i == activeIndex,
                isPoi: _isPoi(sortedWaypoints[i].kind),
                kind: sortedWaypoints[i].kind,
                label: sortedWaypoints[i].label,
                colours: colours,
              ),
          ],
        ),
      ],
    );
  }

  bool _isPoi(String kind) => kind != 'vertex';

  int _findActiveSegment(List<RouteWaypoint> waypoints, LatLng position) {
    if (waypoints.length < 2) return -1;

    double minDist = double.infinity;
    int closestIdx = 0;
    for (var i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final dist = _distance(
        position.latitude,
        position.longitude,
        wp.latitude,
        wp.longitude,
      );
      if (dist < minDist) {
        minDist = dist;
        closestIdx = i;
      }
    }

    if (closestIdx < waypoints.length - 1) {
      return closestIdx;
    }
    return -1;
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180;
}

/// Creates a waypoint marker for the map.
Marker _makeWaypointMarker({
  required LatLng point,
  required int index,
  required bool isActive,
  required bool isPoi,
  required String kind,
  required String? label,
  required FieldColours colours,
}) {
  final fillColor = _kindColor(kind, colours);
  final strokeColor = colours.canopy;
  final textColor = colours.bone;

  return Marker(
    point: point,
    width: isPoi ? 70 : 36,
    height: isPoi ? 70 : 36,
    alignment: Alignment.center,
    child: _WaypointMarkerWidget(
      index: index,
      isActive: isActive,
      isPoi: isPoi,
      fillColor: fillColor,
      strokeColor: strokeColor,
      textColor: textColor,
      label: label,
      colours: colours,
    ),
  );
}

Color _kindColor(String kind, FieldColours colours) {
  switch (kind) {
    case 'gate':
      return colours.dust;
    case 'waterhole':
      return colours.moss;
    case 'landmark':
      return colours.straw;
    case 'custom':
      return colours.blood;
    default:
      return colours.dust;
  }
}

/// Animated active segment that pulses.
class _AnimatedActiveSegment extends StatefulWidget {
  const _AnimatedActiveSegment({
    required this.start,
    required this.end,
    required this.colour,
    this.animation,
  });

  final LatLng start;
  final LatLng end;
  final Color colour;
  final Animation<double>? animation;

  @override
  State<_AnimatedActiveSegment> createState() => _AnimatedActiveSegmentState();
}

class _AnimatedActiveSegmentState extends State<_AnimatedActiveSegment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animation != null) {
      _pulseAnimation = widget.animation!;
    } else {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(
        begin: 1.0,
        end: 1.3,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AnimatedActiveSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return PolylineLayer(
          polylines: [
            Polyline(
              points: [widget.start, widget.end],
              color: widget.colour.withValues(alpha: _pulseAnimation.value),
              strokeWidth: 3.0 * _pulseAnimation.value,
              pattern: StrokePattern.solid(),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
          ],
        );
      },
    );
  }
}

/// Waypoint marker widget.
class _WaypointMarkerWidget extends StatelessWidget {
  const _WaypointMarkerWidget({
    super.key,
    required this.index,
    required this.isActive,
    required this.isPoi,
    required this.fillColor,
    required this.strokeColor,
    required this.textColor,
    required this.label,
    required this.colours,
  });

  final int index;
  final bool isActive;
  final bool isPoi;
  final Color fillColor;
  final Color strokeColor;
  final Color textColor;
  final String? label;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring for active waypoint
        if (isActive)
          AnimatedBuilder(
            animation: AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: fillColor, width: 2),
                ),
              );
            },
          ),
        // Main marker circle
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: strokeColor, width: 2),
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        // POI label below marker
        if (isPoi && label != null && label!.isNotEmpty)
          Positioned(
            top: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colours.canopyRaised.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: fillColor),
              ),
              child: Text(
                label!,
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: fillColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
