import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:field_log/data/database.dart' show PlannedRoute, RouteWaypoint;
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/osm_tiles.dart';
import 'package:field_log/map/maptiler_tiles.dart';
import 'package:field_log/map/reserve_topology.dart';
import 'package:field_log/map/route_layer.dart';
import 'package:field_log/map/south_africa.dart';
import 'package:field_log/map/tile_cache.dart';
import 'package:field_log/map/pin_painter.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/map/progress_overlay.dart';
import 'package:field_log/map/vector_tile_layer.dart';
import 'package:field_log/progress/progress_summary.dart';
import 'package:field_log/screens/map_legend_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
// flutter_map's barrel does not re-export this, though its own source uses it.
import 'package:latlong2/latlong.dart';

/// How accurate the position fix is, and when it was taken.

final southAfricaCentre = LatLng(-28.5, 24.6);

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

  /// Whether this reading is a real fix rather than the empty placeholder the
  /// home screen starts with. A device with no satellites, or one that has not
  /// reported since boot (an epoch timestamp), has no position to move to.
  bool get hasFix =>
      satellites > 0 &&
      fixedAt.millisecondsSinceEpoch != 0 &&
      !(latitude == 0 && longitude == 0);
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
    required this.onOpenDrive,
    required this.onOpenSighting,
    this.onOpenTrail,
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
    this.mapStylePreset = MapStylePreset.field,
    this.onMapStylePresetChanged,
    this.progress,
    this.activeOuting,
    this.subtitle,
    this.onDeleteSighting,
    this.onDismissProgress,
    this.onOpenObservations,
    this.syncing = false,
    this.lastSyncedAt,
    this.syncError,
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

  /// Opens the drive logbook: start a drive, watch it, close it.
  final VoidCallback? onOpenDrive;

  /// Opens the trail logbook: start a walk, watch it, close it.
  final VoidCallback? onOpenTrail;

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

  /// Current map style preset (Field, Navigation, Survey).
  final MapStylePreset mapStylePreset;

  /// Called when the user selects a new map style preset.
  final void Function(MapStylePreset)? onMapStylePresetChanged;

  /// The time this device has walked and driven, for the progress card. Null
  /// when the caller has nothing to show yet, which keeps the card off screen.
  final OutingProgress? progress;

  /// An outing currently running on this phone, drawn on the progress card so
  /// it can be watched — and stopped — without opening its logbook.
  final ActiveOuting? activeOuting;

  /// The line above the map's title: the outing in hand, or the reserve the
  /// device is working in. Null falls back to the default place name.
  final String? subtitle;

  /// Removes a sighting, by local id, from whatever store owns it.
  final Future<void> Function(String localId)? onDeleteSighting;

  /// Dismisses the progress card from the map without stopping the outing.
  final VoidCallback? onDismissProgress;

  /// Opens the observations logbook: every record and what happened to it.
  final VoidCallback? onOpenObservations;

  /// Whether a sync pass is running right now.
  final bool syncing;

  /// When the last sync pass finished, or null if it never has.
  final DateTime? lastSyncedAt;

  /// The last sync error, or null when the last pass was clean.
  final String? syncError;

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  /// Frames the camera to contain [bounds] with optional [padding].
  bool fitCamera(CameraFit cameraFit) {
    return _mapController.fitCamera(cameraFit);
  }

  LatLng? _ghostPin;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// Device heading in degrees clockwise from north, or null when the device
  /// has no magnetometer or has not reported yet.
  double? _heading;

  /// The map camera, mirrored into state so the scale bar can redraw. The map
  /// owns these values; this is only a read-only copy for the chrome.
  double _zoom = 14;
  LatLng _center = southAfricaCentre;

  /// Whether the user has moved the camera by hand. Once true, a position fix
  /// that lands late must not yank the map back to the walker.
  bool _userMoved = false;

  /// Whether the fold-out menu is open.
  bool _menuOpen = false;

  /// Whether the map legend is on screen.
  bool _showLegend = false;

  /// Path to the reserve's surveyed topology archive, or null when the build
  /// shipped one that has not been copied yet — or never shipped one at all.
  /// null is a legitimate steady state: the painted vector map below it is
  /// the fallback and needs no data file to be correct.
  String? _topologyPath;

  /// Topology layers the user has switched off. The layers are drawn by
  /// leaving out styles while the archive is present; the painted map has
  /// no per-layer switch of its own.
  final Set<String> _hiddenTopologyLayers = {};

  late MapStylePreset _mapStylePreset;
  late Map<String, bool> _layerVisibility;

  StreamSubscription<CompassEvent>? _compassSub;

  @override
  void initState() {
    super.initState();

    // Initialize map style preset and layer visibility.
    _mapStylePreset = widget.mapStylePreset;
    _layerVisibility = _defaultLayerVisibility(_mapStylePreset);

    // Open where the device is if it already knows, otherwise show the reserve
    // at country scale rather than a hole. The first real fix moves the camera
    // in (see didUpdateWidget) unless the user has already chosen otherwise.
    if (widget.gps.hasFix) {
      _center = LatLng(widget.gps.latitude, widget.gps.longitude);
      _zoom = 14;
    } else {
      _center = southAfricaCentre;
      _zoom = countryZoom;
    }

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // A device with no compass reports a null stream; a device that has one and
    // then errors must not take the map down, so the errors are swallowed and
    // the compass simply stays hidden.
    final compass = FlutterCompass.events;
    if (compass != null) {
      _compassSub = compass.listen((event) {
        if (!mounted) return;
        final heading = event.heading;
        if (heading == null) return;
        setState(() => _heading = heading);
      }, onError: (_) {});
    }

    // The archive copy is one small file, so this is quick; the screen shows
    // the painted map until it lands, then swaps to the surveyed one without
    // any visual "loading" step.
    prepareReserveTopology().then((path) {
      if (!mounted || path == null || path == _topologyPath) return;
      setState(() => _topologyPath = path);
    });
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A fix that lands after the screen was built moves the camera in, once,
    // unless the user has already moved the map themselves.
    final gainedFix = !oldWidget.gps.hasFix && widget.gps.hasFix;
    if (gainedFix && !_userMoved) {
      _mapController.move(
        LatLng(widget.gps.latitude, widget.gps.longitude),
        14,
      );
    }

    // When the map style preset changes (from settings), sync the internal
    // state so the layer visibility and tile provider update immediately.
    if (oldWidget.mapStylePreset != widget.mapStylePreset) {
      _mapStylePreset = widget.mapStylePreset;
      _layerVisibility = _defaultLayerVisibility(_mapStylePreset);
    }
  }

  /// Returns the default layer visibility for a given map style preset.
  Map<String, bool> _defaultLayerVisibility(MapStylePreset preset) {
    switch (preset) {
      case MapStylePreset.field:
        return {
          'basemap': true,
          'topology': true,
          'observations': true,
          'routes': false,
          'waypoints': false,
          'tracks': false,
          'bearing': false,
          'compass': false,
          'boundaries': false,
          'transects': false,
          'quadrats': false,
          'scale': false,
        };
      case MapStylePreset.navigation:
        return {
          'basemap': true,
          'topology': true,
          'observations': false,
          'routes': true,
          'waypoints': true,
          'tracks': true,
          'bearing': true,
          'compass': true,
          'boundaries': false,
          'transects': false,
          'quadrats': false,
          'scale': false,
        };
      case MapStylePreset.survey:
        return {
          'basemap': true,
          'topology': true,
          'observations': false,
          'routes': false,
          'waypoints': false,
          'tracks': false,
          'bearing': false,
          'compass': false,
          'boundaries': true,
          'transects': true,
          'quadrats': true,
          'scale': true,
        };
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Mirrors the camera into state, but only after the frame, so a position
  /// change arriving mid-build cannot trigger a build during build.
  void _onCameraChanged(MapCamera camera) {
    final zoom = camera.zoom;
    final center = camera.center;
    if (_zoom == zoom && _center == center) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _zoom = zoom;
        _center = center;
      });
    });
  }

  void _resetNorth() {
    _mapController.rotate(0);
  }

  void _recenterOnGps() {
    if (!widget.gps.hasFix || widget.currentPosition == null) return;
    _userMoved = true;
    _mapController.move(widget.currentPosition!, 14);
  }

  /// Steps the map zoom towards where the user wants it. The move reports
  /// back through [onPositionChanged], so the scale bar follows without this
  /// method touching the state directly.
  void _zoomBy(double delta) {
    final target = (_zoom + delta).clamp(minZoom, maxZoom).toDouble();
    if (target == _zoom) return;
    _userMoved = true;
    _mapController.move(_center, target);
  }

  /// The topology layers the user has left switched on. Passing a shorter map
  /// than the defaults is how a layer is turned off: the provider skips any
  /// layer it has no style for.
  Map<String, VectorLayerStyle> get _visibleTopologyStyles {
    return {
      for (final entry in defaultVectorLayerStyles.entries)
        if (!_hiddenTopologyLayers.contains(entry.key)) entry.key: entry.value,
    };
  }

  /// Opens the legend as a sheet with per-layer switches, since that is the
  /// map shape that understands layers. The painted map below keeps the old
  /// chip panel: its features have no switches, just colours.
  void _toggleLegend() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MapLegendSheet(
        layerStyles: defaultVectorLayerStyles,
        initialVisibility: {
          for (final name in defaultVectorLayerStyles.keys)
            name: !_hiddenTopologyLayers.contains(name),
        },
        onVisibilityChanged: (name, visible) {
          if (!mounted) return;
          setState(() {
            if (visible) {
              _hiddenTopologyLayers.remove(name);
            } else {
              _hiddenTopologyLayers.add(name);
            }
          });
        },
      ),
    );
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

  void _showPinMenu(MapPin pin) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(Insets.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onOpenSighting?.call(pin.localId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final didConfirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete sighting?'),
                        content: const Text(
                          'This will mark the sighting as deleted. It will still appear as part of the day\'s trail.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                  if (didConfirm != true) return;
                  widget.onDeleteSighting?.call(pin.localId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sighting deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // The default is a light grey, which would flash through every
              // tile the cache cannot supply. The inset colour is what the
              // vector layer below draws on, so a missing tile shows the ground
              // rather than a hole.
              backgroundColor: widget.colours.inset,
              initialCenter: _center,
              initialZoom: _zoom,
              minZoom: minZoom,
              maxZoom: maxZoom,
              onPositionChanged: (camera, hasGesture) {
                // A hand on the map is the user's choice of where to look; a
                // late fix from didUpdateWidget must then leave them be.
                if (hasGesture) _userMoved = true;
                _onCameraChanged(camera);
              },
              onTap: widget.onMapTap == null
                  ? null
                  : (tapPosition, point) => widget.onMapTap!(point),
              onLongPress: widget.onDropPin == null
                  ? null
                  : (tapPosition, point) => _showGhostPin(point),
            ),
            children: [
              // Mobile layers, so they move and rotate with the map. The tile
              // basemap paints first and the reserve's own features on top of
              // it: the legend explains features that are actually on the
              // ground, not ones hidden under a loaded tile.
              // Basemap layer
              _TileLayer(cache: widget.tileCache, online: widget.online),
              // Topology layer (surveyed contours/boundaries)
              if ((_layerVisibility['topology'] ?? true) &&
                  _topologyPath != null)
                PmTilesVectorLayer(
                  archivePath: _topologyPath!,
                  // The archive is built to z14; beyond that its tiles stop.
                  maxZoom: 14,
                  layerStyles: _visibleTopologyStyles,
                )
              else if (_layerVisibility['topology'] ?? true)
                _VectorLayer(
                  colours: widget.colours,
                  hiddenLayers: _hiddenTopologyLayers,
                ),
              // Planned route layer (if available)
              if ((_layerVisibility['routes'] ?? false) &&
                  widget.route != null &&
                  widget.routeWaypoints != null &&
                  widget.routeWaypoints!.isNotEmpty)
                RouteLayer(
                  route: widget.route!,
                  waypoints: widget.routeWaypoints!,
                  colours: widget.colours,
                  currentPosition: widget.currentPosition ?? LatLng(0, 0),
                ),
              // Observations layer (pins)
              if (_layerVisibility['observations'] ?? true)
                MarkerLayer(
                  markers: [
                    for (final pin in widget.pins)
                      Marker(
                        key: ValueKey(pin.localId),
                        point: pin.point,
                        width: 46,
                        height: 46,
                        alignment: Alignment.bottomCenter,
                        child: _Pin(
                          pin: pin,
                          colours: widget.colours,
                          onTap: widget.onOpenSighting == null
                              ? null
                              : () => widget.onOpenSighting!(pin.localId),
                          onLongPress: () => _showPinMenu(pin),
                          onSecondaryTap: () => _showPinMenu(pin),
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
                    // GPS position marker (when we have a fix)
                    if (widget.gps.hasFix && widget.currentPosition != null)
                      Marker(
                        key: const ValueKey('gps-position'),
                        point: widget.currentPosition!,
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: _GpsPositionMarker(
                          colours: widget.colours,
                          accuracyMetres: widget.gps.accuracyMetres,
                          heading: widget.gps.satellites > 0
                              ? widget.gps.latitude
                              : 0.0,
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
            subtitle: widget.subtitle,
            legendOpen: _showLegend,
            onToggleLegend: _toggleLegend,
            menuOpen: _menuOpen,
            onToggleMenu: () => setState(() => _menuOpen = !_menuOpen),
          ),
          _GpsBar(
            gps: widget.gps,
            colours: widget.colours,
            online: widget.online,
          ),
          // The compass is only shown when the device has reported a heading:
          // a compass rose that always points north is a decoration, not a
          // bearing.
          _MapLayersPanel(
            colours: widget.colours,
            hiddenLayers: _hiddenTopologyLayers,
            onToggleLayer: (name, visible) {
              if (!mounted) return;
              setState(() {
                if (visible) {
                  _hiddenTopologyLayers.remove(name);
                } else {
                  _hiddenTopologyLayers.add(name);
                }
              });
            },
          ),
          if (_heading != null)
            _Compass(
              colours: widget.colours,
              heading: _heading!,
              onTap: _resetNorth,
            ),
          _ScaleBar(
            colours: widget.colours,
            zoom: _zoom,
            latitude: _center.latitude,
          ),
          _ZoomButtons(
            colours: widget.colours,
            onZoomIn: () => _zoomBy(1),
            onZoomOut: () => _zoomBy(-1),
            onRecenter: _recenterOnGps,
            gpsHasFix: widget.gps.hasFix,
          ),
          _Attribution(
            text: maptilerEnabled
                ? maptilerAttribution
                : OsmTileProvider.attribution,
            colours: widget.colours,
          ),
          _Dock(
            colours: widget.colours,
            text: text,
            queuedCount: widget.queuedCount,
            onRecordSighting: widget.onRecordSighting,
            onOpenLedger: widget.onOpenLedger,
          ),
          // The progress card: the time this device has walked and driven,
          // and — while an outing is running — the live indicator for it.
          // Only shown when an outing is actually active, so it never
          // distracts when the user is just looking at the map.
          if (widget.progress != null && widget.activeOuting != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 168,
              child: ProgressOverlay(
                progress: widget.progress!,
                colours: widget.colours,
                activeOuting: widget.activeOuting,
                onDismiss: widget.onDismissProgress,
              ),
            ),
          if (widget.syncing || widget.syncError != null)
            _SyncStatus(
              colours: widget.colours,
              syncing: widget.syncing,
              syncError: widget.syncError,
              lastSyncedAt: widget.lastSyncedAt,
            ),
          // Drawn last so an open menu sits above every other chip.
          _MapMenu(
            colours: widget.colours,
            text: text,
            open: _menuOpen,
            onClose: () => setState(() => _menuOpen = false),
            onOpenDrive: widget.onOpenDrive,
            onOpenTrail: widget.onOpenTrail,
            onOpenObservations: widget.onOpenObservations,
            onOpenTally: widget.onOpenTally,
            onOpenSettings: widget.onOpenSettings,
            onToggleLegend: _toggleLegend,
          ),
        ],
      ),
    );
  }
}

class _VectorLayer extends StatelessWidget {
  const _VectorLayer({required this.colours, this.hiddenLayers = const {}});

  final FieldColours colours;
  final Set<String> hiddenLayers;

  @override
  Widget build(BuildContext context) {
    return MobileLayerTransformer(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ReserveVectorPainter(
            colours: colours,
            hiddenLayers: hiddenLayers,
          ),
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
    // The basemap is remote raster imagery. MapTiler's light, clean tiles are
    // the deliberate "proper map" look and go on un-muted; the OSM fallback is
    // dimmed (see _mute below) so the reserve's own symbols still read over a
    // busy light basemap. The filter wraps the layer itself, so it applies only
    // to tiles, never to the vector features that paint above them.
    final tiles = TileLayer(
      tileProvider: OsmTileProvider(
        cache: cache,
        online: () => online,
        template: maptilerEnabled
            ? maptilerUrlTemplate()
            : OsmTileProvider.defaultUrlTemplate,
        // MapTiler and OSM are different pictures; each must live in its own
        // cache namespace so one style can never serve the other's bytes.
        cacheNamespace: maptilerEnabled ? 'maptiler-$maptilerStyle' : '',
      ),
      // Buffering tiles beyond the viewport means a small pan does not
      // immediately need tiles that have never been fetched.
      keepBuffer: 4,
      panBuffer: 2,
      // No errorTileCallback is needed: a tile that cannot be fetched resolves
      // to a transparent image, so the map stays usable with nothing more than
      // the reserve's own features. That is what "degrade to vectors" means in
      // practice, and it is why the vector layer needs no handling when the
      // tile source goes away.
    );
    return maptilerEnabled
        ? tiles
        : ColorFiltered(colorFilter: _mute, child: tiles);
  }

  /// The tile basemap is remote raster imagery rendered by OSM, so no local
  /// token can ever restyle it. This filter mutates the view instead: each
  /// channel is pulled 70% toward its luminance (desaturation) and the result
  /// is darkened to 62%, which puts the comparatively bright reserve symbols
  /// on a quiet, dark ground instead of a busy light one. The on-disk cache
  /// is untouched; a cache hit always returns the original tiles.
  ///
  /// Matrix math: luminance is Rec.709 (0.2126R + 0.7152G + 0.0722B).
  ///   C' = 0.62 * (0.30 * C + 0.70 * L)
  /// R row: 0.62*(0.30 + 0.70*0.2126) = 0.2783 (R coefficient)
  ///         0.62*0.70*0.7152        = 0.3104 (G coefficient)
  ///         0.62*0.70*0.0722        = 0.0313 (B coefficient)
  static const ColorFilter _mute = ColorFilter.matrix(<double>[
    0.2783,
    0.3104,
    0.0313,
    0,
    0,
    0.2783,
    0.3104,
    0.0313,
    0,
    0,
    0.2783,
    0.3104,
    0.0313,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.pin,
    required this.colours,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
  });

  final MapPin pin;
  final FieldColours colours;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
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

/// GPS position marker with accuracy circle and heading indicator.
class _GpsPositionMarker extends StatelessWidget {
  const _GpsPositionMarker({
    required this.colours,
    required this.accuracyMetres,
    required this.heading,
  });

  final FieldColours colours;
  final double accuracyMetres;
  final double heading;

  @override
  Widget build(BuildContext context) {
    // 1 degree ≈ 111km at equator, so 1m ≈ 1/111000 degrees
    // At zoom 14, 1 degree ≈ 111000/2^14 px ≈ 6.8 px per meter
    // At zoom 18, 1 degree ≈ 111000/2^18 px ≈ 0.42 px per meter
    // We'll just draw a circle with radius proportional to accuracy

    return Stack(
      alignment: Alignment.center,
      children: [
        // Accuracy circle
        if (accuracyMetres > 0)
          Container(
            width: (accuracyMetres * 0.5).clamp(20.0, 100.0),
            height: (accuracyMetres * 0.5).clamp(20.0, 100.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colours.straw.withValues(alpha: 0.5),
                width: 2,
              ),
              color: colours.straw.withValues(alpha: 0.1),
            ),
          ),
        // GPS position marker (arrow pointing to heading)
        Transform.rotate(
          angle: heading * math.pi / 180,
          child: Icon(
            Icons.navigation,
            size: 28,
            color: colours.dust,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
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
    required this.subtitle,
    required this.legendOpen,
    required this.onToggleLegend,
    required this.menuOpen,
    required this.onToggleMenu,
  });

  final String? signedInAs;
  final VoidCallback? onTapSignedInAs;
  final String? subtitle;
  final bool legendOpen;
  final VoidCallback onToggleLegend;
  final bool menuOpen;
  final VoidCallback onToggleMenu;

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
                    subtitle ?? 'Trail · Big 5 Reserve · 12 Sep',
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
            IconButton(
              onPressed: onToggleLegend,
              icon: Icon(
                legendOpen ? Icons.layers_clear : Icons.layers,
                color: legendOpen ? colours.straw : colours.ash1,
              ),
              tooltip: 'Legend',
              padding: const EdgeInsets.all(Insets.xs),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            IconButton(
              onPressed: onToggleMenu,
              icon: Icon(
                menuOpen ? Icons.close : Icons.menu,
                color: colours.ash1,
              ),
              tooltip: 'Menu',
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
  });

  final FieldColours colours;
  final TextTheme text;
  final int queuedCount;
  final VoidCallback? onRecordSighting;
  final VoidCallback? onOpenLedger;

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
                  child: _PrimaryButton(
                    label: 'Record a sighting',
                    colours: colours,
                    onPressed: onRecordSighting,
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

/// The fold-out menu: the way in to every other logbook from the map.
///
/// The rows stay mounted even when the menu is shut, so it can animate open
/// without the text appearing a frame early, but they are clipped to no height
/// and ignore pointers until it is open — a shut door, not an invisible one.
class _MapMenu extends StatelessWidget {
  const _MapMenu({
    required this.colours,
    required this.text,
    required this.open,
    required this.onClose,
    required this.onOpenDrive,
    required this.onOpenTrail,
    required this.onOpenObservations,
    required this.onOpenTally,
    required this.onOpenSettings,
    required this.onToggleLegend,
  });

  final FieldColours colours;
  final TextTheme text;
  final bool open;
  final VoidCallback onClose;
  final VoidCallback? onOpenDrive;
  final VoidCallback? onOpenTrail;
  final VoidCallback? onOpenObservations;
  final VoidCallback? onOpenTally;
  final VoidCallback? onOpenSettings;
  final VoidCallback onToggleLegend;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: Insets.huge + Insets.xxxl,
      right: Insets.md,
      child: IgnorePointer(
        ignoring: !open,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topRight,
            heightFactor: open ? 1.0 : 0.0,
            // A Positioned with only `top` and `right` set hands its child
            // unbounded constraints, so the Column's stretch would ask for an
            // infinite width. IntrinsicWidth gives the card the width of its
            // widest row, which the rows then stretch to fill.
            child: IntrinsicWidth(
              child: Container(
                decoration: BoxDecoration(
                  color: colours.canopyRaised,
                  borderRadius: BorderRadius.circular(Corners.sheet),
                  border: Border.all(color: colours.ruleStrong),
                ),
                padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row('Drive', onOpenDrive),
                    _row('Trail', onOpenTrail),
                    _row('Observations', onOpenObservations),
                    _row('Progress', onOpenTally),
                    _row('Settings', onOpenSettings),
                    _row('Legend', onToggleLegend),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, VoidCallback? onTap) {
    return InkWell(
      onTap: () {
        onClose();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Text(
          label,
          style: text.bodyMedium?.copyWith(color: colours.bone),
        ),
      ),
    );
  }
}

/// A small pill reporting the last sync pass, shown only while one is running
/// or after one has failed. A clean, idle sync says nothing at all.
class _SyncStatus extends StatelessWidget {
  const _SyncStatus({
    required this.colours,
    required this.syncing,
    required this.syncError,
    required this.lastSyncedAt,
  });

  final FieldColours colours;
  final bool syncing;
  final String? syncError;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color colour;
    if (syncError != null) {
      label = 'Sync failed';
      colour = colours.blood;
    } else if (syncing) {
      label = 'Syncing…';
      colour = colours.straw;
    } else {
      label = lastSyncedAt == null ? 'Not yet synced' : 'Synced';
      colour = colours.moss;
    }
    return Positioned(
      top: Insets.huge + Insets.xxxl,
      left: Insets.md,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.xs,
        ),
        decoration: BoxDecoration(
          color: colours.canopyRaised,
          borderRadius: BorderRadius.circular(Corners.chip),
          border: Border.all(color: colour),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colour),
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

/// A small compass rose that shows which way the device is pointing.
///
/// The needle rotates against the device heading so that the straw north half
/// always points to true north on screen. Tapping it puts the map back to
/// north-up, which is the one thing a turned map makes hard to do by eye.
class _Compass extends StatelessWidget {
  const _Compass({
    required this.colours,
    required this.heading,
    required this.onTap,
  });

  final FieldColours colours;

  /// Degrees clockwise from north.
  final double heading;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    return Positioned(
      top: Insets.huge + Insets.xl + size,
      right: Insets.md,
      child: Semantics(
        button: true,
        label:
            'Compass, bearing ${heading.round()} degrees. Tap to reset north.',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colours.canopyRaised.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: colours.ruleStrong),
            ),
            child: Transform.rotate(
              angle: -heading * math.pi / 180,
              child: CustomPaint(
                painter: _CompassNeedlePainter(colours: colours),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  const _CompassNeedlePainter({required this.colours});

  final FieldColours colours;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    final north = ui.Path()
      ..moveTo(centre.dx, centre.dy - radius)
      ..lineTo(centre.dx - 5, centre.dy)
      ..lineTo(centre.dx + 5, centre.dy)
      ..close();
    final south = ui.Path()
      ..moveTo(centre.dx, centre.dy + radius)
      ..lineTo(centre.dx - 5, centre.dy)
      ..lineTo(centre.dx + 5, centre.dy)
      ..close();
    canvas.drawPath(north, Paint()..color = colours.straw);
    canvas.drawPath(south, Paint()..color = colours.ash1);
  }

  @override
  bool shouldRepaint(_CompassNeedlePainter oldDelegate) =>
      oldDelegate.colours != colours;
}

/// A scale bar, so distance on the map can be read without guessing.
///
/// The metres-per-pixel comes from the Web Mercator zoom, adjusted for
/// latitude. The bar is a round distance (1, 2 or 5 times a power of ten) so
/// the label is a number a person can hold in their head.
class _ScaleBar extends StatelessWidget {
  const _ScaleBar({
    required this.colours,
    required this.zoom,
    required this.latitude,
  });

  final FieldColours colours;
  final double zoom;
  final double latitude;

  /// The largest round distance no bigger than [raw].
  static double _niceMetres(double raw) {
    if (raw <= 0) return 1;
    final exponent = (math.log(raw) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    for (final step in const [5.0, 2.0, 1.0]) {
      final candidate = step * magnitude;
      if (candidate <= raw) return candidate;
    }
    return magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final metresPerPixel =
        156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);
    final metres = _niceMetres(metresPerPixel * 90);
    final width = (metres / metresPerPixel).clamp(24.0, 160.0).toDouble();
    final label = metres >= 1000
        ? '${(metres / 1000).toStringAsFixed(metres % 1000 == 0 ? 0 : 1)} km'
        : '${metres.round()} m';
    return Positioned(
      left: Insets.md,
      bottom: 200,
      child: Semantics(
        label: 'Scale bar, $label',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                color: colours.bone,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: width,
              height: 6,
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colours.bone, width: 2),
                  right: BorderSide(color: colours.bone, width: 2),
                  bottom: BorderSide(color: colours.bone, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The [+]/[-] pair that steps the map's zoom.
///
/// Pinch and scroll zoom the map already; these exist so a one-handed thumb
/// can do it too, which is how a field logger is usually holding the phone.
class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({
    required this.colours,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
    required this.gpsHasFix,
  });

  final FieldColours colours;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;
  final bool gpsHasFix;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: Insets.md,
      // Level with the scale bar, clear of the dock.
      bottom: 200,
      child: Container(
        decoration: BoxDecoration(
          color: colours.canopyRaised.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(Corners.sheet),
          border: Border.all(color: colours.ruleStrong),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onZoomOut,
              icon: Icon(Icons.remove, color: colours.bone),
              tooltip: 'Zoom out',
              padding: const EdgeInsets.all(Insets.xs),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            Container(height: 1, color: colours.rule),
            IconButton(
              onPressed: onZoomIn,
              icon: Icon(Icons.add, color: colours.bone),
              tooltip: 'Zoom in',
              padding: const EdgeInsets.all(Insets.xs),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            Container(height: 1, color: colours.rule),
            IconButton(
              onPressed: gpsHasFix ? onRecenter : null,
              icon: Icon(
                Icons.my_location,
                color: gpsHasFix ? colours.bone : colours.ash3,
              ),
              tooltip: 'Recenter on GPS',
              padding: const EdgeInsets.all(Insets.xs),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tile licence, shown because both OpenStreetMap and MapTiler make it a
/// condition of using their imagery rather than a courtesy. It sits just above
/// the dock, clear of the scale bar (left) and the zoom control (right).
class _Attribution extends StatelessWidget {
  const _Attribution({required this.text, required this.colours});

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 192,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colours.canopyRaised.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(Corners.chip),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colours.ash1,
                fontSize: 10,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the symbols on the map mean.
///
/// Every glyph is drawn from the same token the map itself paints with, so
/// the legend cannot drift from the ground it explains.
/// Top-left map layers panel with toggle switches and icons.
class _MapLayersPanel extends StatelessWidget {
  const _MapLayersPanel({
    required this.colours,
    required this.hiddenLayers,
    required this.onToggleLayer,
  });

  final FieldColours colours;
  final Set<String> hiddenLayers;
  final void Function(String layerName, bool visible) onToggleLayer;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: Insets.huge + Insets.xl + Insets.giant,
      left: Insets.md,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colours.canopyRaised.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(Corners.sheet),
          border: Border.all(color: colours.ruleStrong),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers, size: Faces.cardTitle, color: colours.bone),
                const SizedBox(width: Insets.sm),
                Text(
                  'Map Layers',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.cardTitle,
                    fontWeight: FontWeight.w600,
                    color: colours.bone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            _LayerToggleRow(
              colours: colours,
              label: 'Waterholes',
              icon: Icons.water_drop,
              layerName: 'waterholes',
              isVisible: !hiddenLayers.contains('waterholes'),
              onChanged: onToggleLayer,
            ),
            _LayerToggleRow(
              colours: colours,
              label: 'Roads',
              icon: Icons.alt_route,
              layerName: 'roads',
              isVisible: !hiddenLayers.contains('roads'),
              onChanged: onToggleLayer,
            ),
            _LayerToggleRow(
              colours: colours,
              label: 'Acacia Stands',
              icon: Icons.forest,
              layerName: 'acacia',
              isVisible: !hiddenLayers.contains('acacia'),
              onChanged: onToggleLayer,
            ),
            _LayerToggleRow(
              colours: colours,
              label: 'Reserve Boundary',
              icon: Icons.map,
              layerName: 'boundary',
              isVisible: !hiddenLayers.contains('boundary'),
              onChanged: onToggleLayer,
            ),
            const Divider(height: Insets.lg, thickness: 0.5),
            _LayerToggleRow(
              colours: colours,
              label: 'Index Contours (50m)',
              icon: Icons.show_chart,
              layerName: 'contours_index',
              isVisible: !hiddenLayers.contains('contours_index'),
              onChanged: onToggleLayer,
            ),
            _LayerToggleRow(
              colours: colours,
              label: 'Contours (10m)',
              icon: Icons.terrain,
              layerName: 'contours',
              isVisible: !hiddenLayers.contains('contours'),
              onChanged: onToggleLayer,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single layer toggle row with icon, label, and switch.
class _LayerToggleRow extends StatelessWidget {
  const _LayerToggleRow({
    required this.colours,
    required this.label,
    required this.icon,
    required this.layerName,
    required this.isVisible,
    required this.onChanged,
  });

  final FieldColours colours;
  final String label;
  final IconData icon;
  final String layerName;
  final bool isVisible;
  final void Function(String layerName, bool visible) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colours.canopyOverlay,
              borderRadius: BorderRadius.circular(Corners.chip),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colours.bone.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.label,
                color: colours.bone,
              ),
            ),
          ),
          Switch(
            value: isVisible,
            onChanged: (v) => onChanged(layerName, v),
            activeThumbColor: colours.moss,
            activeTrackColor: colours.moss.withValues(alpha: 0.5),
            inactiveThumbColor: colours.ash3,
            inactiveTrackColor: colours.rule,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// The symbols on the map, drawn as small glyphs with the same tokens the map
/// paints with, so the legend cannot drift from the ground it explains. Each
/// sits on a light chip so it reads against the dark panel and the tiles
/// beyond it.
enum _LegendGlyphKind { sighting, water, drainage, scrub, contour }

class _LegendGlyph extends StatelessWidget {
  const _LegendGlyph({required this.kind, required this.colours});

  final _LegendGlyphKind kind;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colours.bone,
        borderRadius: BorderRadius.circular(Corners.control),
        border: Border.all(color: colours.ruleStrong),
      ),
      child: SizedBox(
        width: 26,
        height: 26,
        child: CustomPaint(
          painter: _LegendGlyphPainter(kind: kind, colours: colours),
        ),
      ),
    );
  }
}

class _LegendGlyphPainter extends CustomPainter {
  const _LegendGlyphPainter({required this.kind, required this.colours});

  final _LegendGlyphKind kind;
  final FieldColours colours;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final s = size.shortestSide;
    switch (kind) {
      case _LegendGlyphKind.sighting:
        canvas.drawCircle(
          centre,
          s * 0.30,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = colours.ruleStrong,
        );
        canvas.drawCircle(centre, s * 0.18, Paint()..color = colours.dust);
      case _LegendGlyphKind.water:
        canvas.drawCircle(
          centre,
          s * 0.32,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = colours.ruleStrong,
        );
        canvas.drawCircle(
          centre.translate(0, s * 0.03),
          s * 0.18,
          Paint()..color = colours.water,
        );
      case _LegendGlyphKind.drainage:
        canvas.drawPath(
          _wavyLine(Rect.fromLTWH(2, 9, 22, 10), amplitude: 3, cycles: 1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round
            ..color = colours.drainage,
        );
      case _LegendGlyphKind.scrub:
        const spots = [
          Offset(0.26, 0.28),
          Offset(0.68, 0.16),
          Offset(0.52, 0.48),
          Offset(0.22, 0.66),
          Offset(0.72, 0.72),
        ];
        for (final spot in spots) {
          canvas.drawCircle(
            Offset(
              centre.dx + (spot.dx - 0.5) * s,
              centre.dy + (spot.dy - 0.5) * s,
            ),
            s * 0.085,
            Paint()..color = colours.moss.withValues(alpha: 0.40),
          );
        }
      case _LegendGlyphKind.contour:
        canvas.drawPath(
          _wavyRing(centre, s * 0.34, wobble: s * 0.06, steps: 24),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = colours.ruleStrong,
        );
        canvas.drawPath(
          _wavyRing(centre, s * 0.20, wobble: s * 0.05, steps: 20),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = colours.rule,
        );
    }
  }

  /// A gentle wave across a horizontal strip, mirroring the drainage stream
  /// on the map.
  ui.Path _wavyLine(
    Rect bounds, {
    required double amplitude,
    required double cycles,
  }) {
    final path = ui.Path();
    const steps = 20;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final point = Offset(
        bounds.left + bounds.width * t,
        bounds.center.dy + math.sin(t * 2 * math.pi * cycles) * amplitude,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  /// A closed wobbly loop, mirroring one contour band on the map.
  ui.Path _wavyRing(
    Offset centre,
    double radius, {
    required double wobble,
    required int steps,
  }) {
    final path = ui.Path();
    for (var i = 0; i < steps; i++) {
      final angle = (i / steps) * 2 * math.pi;
      final r = radius + math.sin(angle * 2) * wobble;
      final point = centre + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_LegendGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.colours != colours;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.colours,
    required this.label,
    required this.glyph,
  });

  final FieldColours colours;
  final String label;
  final Widget glyph;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          glyph,
          const SizedBox(width: Insets.sm),
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
    );
  }
}
