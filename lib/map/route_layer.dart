import 'package:field_log/data/database.dart' show PlannedRoute, RouteWaypoint;
import 'package:field_log/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'dart:math' as math;

/// Paints a planned route on the map: dashed line + numbered waypoint markers.
///
/// The route line uses [dust] on both themes, 2.5px dashed 8/4 with round caps.
/// Waypoint markers are 10px circles with [dust] fill, [canopy] 2px stroke,
/// order number in bookSerif 10px centered.
/// Active segment (next waypoint) is solid [dust] 3px.
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

  /// Current GPS position, used to determine active segment.
  final LatLng currentPosition;

  /// Colours for the current theme.
  final FieldColours colours;

  /// Optional animation for active segment pulse.
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    if (waypoints.length < 2) {
      // Not enough waypoints to draw a route
      return const SizedBox.shrink();
    }

    // Sort waypoints by ordinal
    final sortedWaypoints = List<RouteWaypoint>.from(waypoints)
      ..sort((a, b) => a.ordinal.compareTo(b.ordinal));

    // Determine active segment (next waypoint ahead of current position)
    final activeIndex = _findActiveSegment(sortedWaypoints, currentPosition);

    final points = waypoints
        .map((w) => LatLng(w.latitude, w.longitude))
        .toList();

    return PolylineLayer(
      polylines: [
        // Full route as dashed line
        Polyline(
          points: points,
          color: colours.dust,
          strokeWidth: 2.5,
          pattern: StrokePattern.dashed(segments: [8.0, 4.0]),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
        // Active segment as solid line
        if (activeIndex >= 0 && activeIndex < waypoints.length - 1)
          Polyline(
            points: [
              LatLng(
                waypoints[activeIndex].latitude,
                waypoints[activeIndex].longitude,
              ),
              LatLng(
                waypoints[activeIndex + 1].latitude,
                waypoints[activeIndex + 1].longitude,
              ),
            ],
            color: colours.dust,
            strokeWidth: 3.0,
            pattern: StrokePattern.solid(),
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
      ],
    );
  }

  int _findActiveSegment(List<RouteWaypoint> waypoints, LatLng position) {
    if (waypoints.length < 2) return -1;

    // Find the closest waypoint to current position
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

    // Active segment is the one starting at the closest waypoint
    // (if we're near a waypoint, the next segment is active)
    if (closestIdx < waypoints.length - 1) {
      return closestIdx;
    }
    return -1;
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000; // Earth radius in meters
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
