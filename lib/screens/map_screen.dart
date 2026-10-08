import 'package:field_log/data/database.dart' show PlannedRoute, RouteWaypoint;
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/osm_tiles.dart';
import 'package:field_log/map/route_layer.dart';
import 'package:field_log/map/tile_cache.dart';
import 'package:field_log/map/pin_painter.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// flutter_map's barrel does not re-export this, though its own source uses it.
import 'package:latlong2/latlong.dart';

/// The reserve this build knows about.
///
/// A placeholder until the reserve's real bounds are configured. The app must
/// not guess a centre from the sightings it happens to hold, because a map that
/// opens somewhere arbitrary is worse than one that opens somewhere named.
final reserveCentre = LatLng(-1.2921, 36.8219);

/// How accurate the position fix is, and when it was taken.
///
/// Accuracy is part of the record, so it is never hidden: a trainee who
/// recorded something at "plus or minus 40 metres" needs to see that, not
/// discover it later when a reviewer asks.
class GpsReading {
  const GpsReading({
    required this.accuracyMetres,
    required this.satellites,
    required this.fixedAt,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  final double accuracyMetres;
  final int satellites;
  final DateTime fixedAt;
  final double latitude;
  final double longitude;
}

/// One observation as the map shows it.
class MapPin {
  const MapPin({
    required this.localId,
    required this.latitude,
    required this.longitude,
    required this.visual,
    required this.count,
  });

  final String localId;
  final double latitude;
  final double longitude;
  final PinVisual visual;
  final int? count;

  LatLng get point => LatLng(latitude, longitude);
}

/// The map screen: the ground, the observations on it, and nothing else.
///
/// The observation pin never moves once placed. A position is corrected with a
/// note, never by dragging, because a logbook that can be quietly tidied into a
/// shape is not a logbook.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.pins,
    required this.queuedCount,
    required this.colours,
    required this.online,
    required this.gps,
    required this.onRecordSighting,
    required this.onOpenLedger,
    required this.onOpenTally,
    required this.onOpenSighting,
    this.tileCache,
    this.signedInAs,
    this.onTapSignedInAs,
    this.onOpenSettings,
    this.onMapTap,
    this.selectedLocalId,
    this.onDropPin,
    this.route,
    this.routeWaypoints,
    this.currentPosition,
  });

  final List<MapPin> pins;
  final int queuedCount;
  final FieldColours colours;
  final bool online;
  final GpsReading gps;
  final TileCache? tileCache;
  final VoidCallback? onRecordSighting;
  final VoidCallback? onOpenLedger;

  /// Called with a sighting's local id when its pin is tapped.
  ///
  /// A callback rather than a route pushed from here, because this screen does
  /// not know what a pin can become. Keeping the decision at the top means the
  /// map can be built and tested without a navigator at all.
  final void Function(String localId)? onOpenSighting;

  final VoidCallback? onOpenTally;
  final String? selectedLocalId;

  /// Who is holding the phone. Null when nobody is signed in, which is the
  /// ordinary state on a device that has never connected.
  ///
  /// This screen does not know what a user is. It is handed the shortest name
  /// that identifies the person and draws it, so the map can be built and
  /// tested with no account and no network.
  final String? signedInAs;

  /// Opens the account. The chip is the only control on the map that belongs to
  /// the person rather than to the ground, so tapping it should do the one
  /// thing a person would expect: show them their account.
  ///
  /// It must never sign the person out: a name you can press by accident is
  /// not a name you can trust to stay pressed. Signing out lives inside the
  /// account screen, behind a question.
  final VoidCallback? onTapSignedInAs;

  /// Opens the menu: account, server address, reference data, about. Always
  /// offered, signed in or not, so a signed-out device whose sign-in banner
  /// was dismissed still has a door back in.
  final VoidCallback? onOpenSettings;

  /// Called when the map is tapped (not a pin). Used to drop a pin at the
  /// tapped location.
  final void Function(LatLng point)? onMapTap;

  /// Called when the user long-presses the map to drop a pin. Receives the
  /// tapped coordinate. The caller decides what to do (e.g., open field card).
  final void Function(LatLng point)? onDropPin;

  /// Optional planned route to display on the map.
  final PlannedRoute? route;

  /// Waypoints for the planned route.
  final List<RouteWaypoint>? routeWaypoints;

  /// Current GPS position for active segment highlighting.
  final LatLng? currentPosition;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  LatLng? _ghostPin;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showGhostPin(LatLng point) {
    setState(() {
      _ghostPin = point;
      _pulseController.repeat(reverse: true);
    });
  }

  void _clearGhostPin() {
    setState(() {
      _ghostPin = null;
      _pulseController.stop();
      _pulseController.reset();
    });
  }

  void _confirmGhostPin() {
    final point = _ghostPin;
    if (point == null) return;
    _clearGhostPin();
    widget.onDropPin?.call(point);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              // The default is a light grey, which would flash through every
              // tile the cache cannot supply. The inset colour is what the
              // vector layer below draws on, so a missing tile shows the ground
              // rather than a hole.
              backgroundColor: widget.colours.inset,
              initialCenter: reserveCentre,
              initialZoom: 14,
              minZoom: 8,
              maxZoom: 18,
              onTap: widget.onMapTap == null
                  ? null
                  : (tapPosition, point) => widget.onMapTap!(point),
              onLongPress: widget.onDropPin == null
                  ? null
                  : (tapPosition, point) => _showGhostPin(point),
            ),
            children: [
              // Mobile layers, so they move and rotate with the map.
              _VectorLayer(colours: widget.colours),
              _TileLayer(cache: widget.tileCache, online: widget.online),
              // Planned route layer (if available)
              if (widget.route != null &&
                  widget.routeWaypoints != null &&
                  widget.routeWaypoints!.isNotEmpty)
                RouteLayer(
                  route: widget.route!,
                  waypoints: widget.routeWaypoints!,
                  colours: widget.colours,
                  currentPosition: widget.currentPosition ?? LatLng(0, 0),
                ),
              MarkerLayer(
                markers: [
                  for (final pin in widget.pins)
                    Marker(
                      key: ValueKey(pin.localId),
                      point: pin.point,
                      // Big enough for the tab plus its badge, and anchored
                      // bottom-centre so the tab's point sits on the position.
                      width: 46,
                      height: 46,
                      alignment: Alignment.bottomCenter,
                      child: _Pin(
                        pin: pin,
                        colours: widget.colours,
                        onTap: widget.onOpenSighting == null
                            ? null
                            : () => widget.onOpenSighting!(pin.localId),
                      ),
                    ),
                  // Ghost pin marker (appears on long-press)
                  if (_ghostPin != null)
                    Marker(
                      key: const ValueKey('ghost-pin'),
                      point: _ghostPin!,
                      width: 46,
                      height: 46,
                      alignment: Alignment.bottomCenter,
                      child: _GhostPin(
                        colours: widget.colours,
                        animation: _pulseAnimation,
                        onTap: _confirmGhostPin,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Static chrome.
          _AppBar(
            colours: widget.colours,
            text: text,
            online: widget.online,
            signedInAs: widget.signedInAs,
            onTapSignedInAs: widget.onTapSignedInAs,
            onOpenSettings: widget.onOpenSettings,
          ),
          _GpsBar(
            gps: widget.gps,
            colours: widget.colours,
            online: widget.online,
          ),
          _Dock(
            colours: widget.colours,
            text: text,
            queuedCount: widget.queuedCount,
            onRecordSighting: widget.onRecordSighting,
            onOpenLedger: widget.onOpenLedger,
            onOpenTally: widget.onOpenTally,
          ),
        ],
      ),
    );
  }
}

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

class _TileLayer extends StatelessWidget {
  const _TileLayer({required this.cache, required this.online});

  final TileCache? cache;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final cache = this.cache;
    if (cache == null) {
      // No cache means no tile layer at all, which is the correct behaviour
      // rather than a degraded one: the vector layer alone is still a map.
      return const SizedBox.shrink();
    }
    return TileLayer(
      tileProvider: OsmTileProvider(cache: cache, online: () => online),
      // Buffering tiles beyond the viewport means a small pan does not
      // immediately need tiles that have never been fetched.
      keepBuffer: 4,
      panBuffer: 2,
      // No errorTileCallback is needed: a tile that cannot be fetched resolves
      // to a transparent image, so the reserve's own contours show through.
      // That is what "degrade to vectors" means in practice, and it is why the
      // vector layer sits underneath rather than being swapped in.
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.pin, required this.colours, this.onTap});

  final MapPin pin;
  final FieldColours colours;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // The tab is a shape, not an icon, so it carries its own label for a
      // screen reader rather than relying on the glyph.
      child: Semantics(
        button: true,
        label: pin.visual.spoken,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(
              size: const Size(46, 46),
              painter: PinPainter(
                visual: pin.visual,
                colours: colours,
                selected: false,
              ),
            ),
            if ((pin.count ?? 0) > 1 && !pin.visual.isNote)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: CustomPaint(
                  size: const Size(14, 14),
                  painter: CountBadgePainter(
                    count: pin.count!,
                    colours: colours,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A ghost pin that appears on long-press, pulsing to invite confirmation.
///
/// Tapping it confirms the location and opens the field card with the
/// coordinates pre-filled. The pulse animation runs at 50% opacity so it
/// reads as provisional, not committed.
class _GhostPin extends StatelessWidget {
  const _GhostPin({
    required this.colours,
    required this.animation,
    required this.onTap,
  });

  final FieldColours colours;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: onTap,
            child: Semantics(
              button: true,
              label: 'Confirm pin location',
              child: CustomPaint(
                size: const Size(46, 46),
                painter: PinPainter(
                  visual: ghostPinVisual,
                  colours: colours,
                  selected: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.colours,
    required this.text,
    required this.online,
    required this.signedInAs,
    required this.onTapSignedInAs,
    required this.onOpenSettings,
  });

  final String? signedInAs;
  final VoidCallback? onTapSignedInAs;
  final VoidCallback? onOpenSettings;

  final FieldColours colours;
  final TextTheme text;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: colours.canopy.withValues(alpha: 0.92),
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.xxxl + Insets.sm,
          Insets.lg,
          Insets.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trail · Big 5 Reserve · 12 Sep',
                    style: text.labelSmall?.copyWith(color: colours.ash2),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    'Field LogBook',
                    style: text.titleMedium?.copyWith(color: colours.bone),
                  ),
                ],
              ),
            ),
            if (signedInAs != null)
              _WhoChip(
                name: signedInAs!,
                colours: colours,
                onTap: onTapSignedInAs,
              ),
            _NetworkChip(online: online, colours: colours),
            if (onOpenSettings != null)
              IconButton(
                onPressed: onOpenSettings,
                icon: Icon(Icons.menu, color: colours.ash1),
                tooltip: 'Settings',
                padding: const EdgeInsets.all(Insets.xs),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
          ],
        ),
      ),
    );
  }
}

/// Who is holding the phone.
///
/// A name in the corner rather than an avatar: the device is shared between
/// trainees, and knowing whose notes these are is the first question asked
/// when a walk ends.
class _WhoChip extends StatelessWidget {
  const _WhoChip({required this.name, required this.colours, this.onTap});

  final String name;
  final FieldColours colours;

  /// Null renders a chip rather than a control, so a map built for a test or a
  /// device with no account carries no button that does nothing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      label: 'Signed in as $name',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.xs,
        ),
        decoration: BoxDecoration(
          color: colours.canopyRaised,
          borderRadius: BorderRadius.circular(Corners.chip),
          border: Border.all(color: colours.rule),
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.stamp,
            color: colours.ash1,
          ),
        ),
      ),
    );

    if (onTap == null) {
      return chip;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.chip),
      child: chip,
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.online, required this.colours});

  final bool online;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    // Offline is a normal state to be in, not an error, so it is stated plainly
    // rather than dressed as a warning.
    final label = online ? 'Online' : 'Offline';
    final dot = online ? colours.moss : colours.ash2;
    return Semantics(
      label: 'Network: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colours.rule),
          borderRadius: BorderRadius.circular(Corners.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: Insets.xs),
            Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                color: colours.ash1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsBar extends StatelessWidget {
  const _GpsBar({
    required this.gps,
    required this.colours,
    required this.online,
  });

  final GpsReading gps;
  final FieldColours colours;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final time = gps.fixedAt.toIso8601String().substring(11, 19);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.only(top: Insets.huge + Insets.xl),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.xs,
            ),
            decoration: BoxDecoration(
              color: colours.canopy.withValues(alpha: 0.92),
              border: Border.all(color: colours.rule),
              borderRadius: BorderRadius.circular(Corners.chip),
            ),
            child: Text(
              'GPS ±${gps.accuracyMetres.round()} m · '
              '${gps.satellites} sats · fix $time',
              style: text.labelSmall?.copyWith(color: colours.ash1),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.colours,
    required this.text,
    required this.queuedCount,
    required this.onRecordSighting,
    required this.onOpenLedger,
    required this.onOpenTally,
  });

  final FieldColours colours;
  final TextTheme text;
  final int queuedCount;
  final VoidCallback? onRecordSighting;
  final VoidCallback? onOpenLedger;
  final VoidCallback? onOpenTally;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: colours.canopy,
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          Insets.md,
          Insets.md,
          Insets.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QueueRow(
              colours: colours,
              text: text,
              queuedCount: queuedCount,
              onTap: onOpenLedger,
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _PrimaryButton(
                    label: 'Record a sighting',
                    colours: colours,
                    onPressed: onRecordSighting,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  flex: 2,
                  child: _GhostButton(
                    label: 'Progress',
                    colours: colours,
                    onPressed: onOpenTally,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.colours,
    required this.text,
    required this.queuedCount,
    required this.onTap,
  });

  final FieldColours colours;
  final TextTheme text;
  final int queuedCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (queuedCount == 0) {
      return const SizedBox.shrink();
    }
    final plural = queuedCount == 1 ? 'observation' : 'observations';
    return Semantics(
      button: true,
      label: '$queuedCount $plural waiting to upload. Opens the queue.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.control),
        child: Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: colours.canopyRaised,
            border: Border.all(color: colours.rule),
            borderRadius: BorderRadius.circular(Corners.control),
          ),
          child: Row(
            children: [
              _QueueCount(count: queuedCount, colours: colours),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$queuedCount $plural waiting to upload',
                      style: text.labelLarge?.copyWith(color: colours.bone),
                    ),
                    const SizedBox(height: Insets.xs),
                    Text(
                      // Nothing here is ever pressed in a moving vehicle, and
                      // saying so is the point of the row.
                      'Queued locally · uploads when you have signal',
                      style: text.bodySmall?.copyWith(color: colours.ash2),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colours.ash2),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueCount extends StatelessWidget {
  const _QueueCount({required this.count, required this.colours});

  final int count;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colours.dust, shape: BoxShape.circle),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: Faces.stamp,
          fontWeight: FontWeight.w700,
          color: colours.inkOn(colours.dust),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.colours,
    required this.onPressed,
  });

  final String label;
  final FieldColours colours;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colours.bone,
        foregroundColor: colours.canopy,
        disabledBackgroundColor: colours.ash2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
      child: Text(label, style: TextStyle(fontFamily: Faces.ui.first)),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.colours,
    required this.onPressed,
  });

  final String label;
  final FieldColours colours;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colours.bone,
        side: BorderSide(color: colours.ruleStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
      child: Text(label, style: TextStyle(fontFamily: Faces.ui.first)),
    );
  }
}

/// Latitude and longitude for a sighting, used when placing a pin.
///
