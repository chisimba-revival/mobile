import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show InsertMode, OrderingTerm;
import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/recent_species.dart';
import 'package:field_log/data/reference_loader.dart';
import 'package:field_log/data/sighting_amendments.dart';
import 'package:field_log/data/sighting_writer.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/card_state.dart';
import 'package:field_log/field/field_card_screen.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/map/tile_cache.dart';
import 'package:field_log/models/geo_point.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:field_log/net/connectivity_watcher.dart';
import 'package:field_log/net/session_store.dart';
import 'package:field_log/screens/map_screen.dart';
import 'package:field_log/screens/pin_detail.dart';
import 'package:field_log/screens/quick_capture_sheet.dart';
import 'package:field_log/screens/route_editor_screen.dart';
import 'package:field_log/screens/settings_screen.dart';
import 'package:field_log/screens/sign_in_screen.dart';
import 'package:field_log/screens/sync_ledger.dart';
import 'package:field_log/screens/tally_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The store is opened before the first frame rather than lazily. A field log
  // that shows an empty map because the database has not opened yet would look
  // exactly like a device that has lost every record, and the design gives no
  // way to tell those apart.
  final database = FieldLogDatabase.open();
  final tileCache = await TileCache.forDevice();
  // Where the reserve office is. This is a build-time value in a real
  // deployment rather than a constant in the source, and it is the one thing
  // that will differ between a device in the reserve and a device in a
  // developer's hands.
  const serviceUrl = String.fromEnvironment(
    'CHISIMBA_API',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );
  runApp(
    FieldLogApp(
      database: database,
      tileCache: tileCache,
      api: ChisimbaApi(baseUrl: serviceUrl),
      sessions: SessionStore(
        // Outside the database on purpose: that file is the logbook, and it is
        // synced and exportable. A credential belongs in neither.
        file: File(
          '${(await getApplicationSupportDirectory()).path}/session.json',
        ),
      ),
      connectivity: ConnectivityWatcher(),
    ),
  );
}

/// The application root.
///
/// Dark first, and this is a field decision: the work happens at first light
/// and a white screen at 05:40 blinds. The choice is remembered per device,
/// and the appearance menu lets a trainee trade that for sunlight when the
/// light lets them.
class FieldLogApp extends StatefulWidget {
  const FieldLogApp({
    super.key,
    required this.database,
    required this.api,
    required this.sessions,
    required this.connectivity,
    this.tileCache,
  });

  final FieldLogDatabase database;
  final ChisimbaApi api;
  final SessionStore sessions;
  final ConnectivityWatcher connectivity;

  /// Absent when the cache could not be opened. The map then runs on the vector
  /// layer alone, which is a map without a basemap rather than a broken one.
  final TileCache? tileCache;

  @override
  State<FieldLogApp> createState() => _FieldLogAppState();
}

class _FieldLogAppState extends State<FieldLogApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _restoreThemeMode();
  }

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = switch (saved) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field log',
      debugShowCheckedModeBanner: false,
      theme: fieldTheme(FieldColours.sunlight),
      darkTheme: fieldTheme(FieldColours.dark),
      themeMode: _themeMode,
      home: FieldLogHome(
        database: widget.database,
        tileCache: widget.tileCache,
        api: widget.api,
        sessions: widget.sessions,
        connectivity: widget.connectivity,
        currentThemeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

/// The map, holding the store.
///
/// This is deliberately not a Riverpod provider yet. There is one screen that
/// reads the store and no state that outlives a frame, so introducing a scope
/// now would add a lifecycle to reason about before there is anything shared
/// to justify it.
class FieldLogHome extends StatefulWidget {
  const FieldLogHome({
    super.key,
    required this.database,
    required this.api,
    required this.sessions,
    required this.connectivity,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    this.tileCache,
  });

  final FieldLogDatabase database;
  final ChisimbaApi api;
  final SessionStore sessions;
  final ConnectivityWatcher connectivity;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final TileCache? tileCache;

  @override
  State<FieldLogHome> createState() => _FieldLogHomeState();
}

class _FieldLogHomeState extends State<FieldLogHome> {
  List<MapPin> _pins = const [];
  final int _queued = 0;

  FieldUser? _user;
  ConnectivityStatus _status = const ConnectivityStatus(
    hasTransport: false,
    transports: [],
  );
  StreamSubscription<ConnectivityStatus>? _transport;
  bool _restoring = true;
  bool _offerDismissed = false;

  /// The last fix, or a placeholder that reports no fix. Zero metres of
  /// accuracy and the epoch are not a position: they are a reading that never
  /// happened, and the bar says so by showing nothing useful.
  GpsReading _gps = GpsReading(
    accuracyMetres: 0,
    satellites: 0,
    fixedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  /// The live position as a map coordinate, when there is one.
  LatLng? _currentPosition;
  StreamSubscription<Position>? _position;

  /// The species most recently noted on this device, opened lazily.
  RecentSpecies? _recent;

  /// The reference snapshot (species, outings, behaviour and age/sex options)
  /// last fetched from the office. Absent until the first load settles.
  ReferenceSnapshot? _reference;

  /// The outing a capture is being filed against, chosen in the field card or
  /// the route editor. Until one is picked, captures are kept unowned.
  String? _selectedOutingId;

  /// The planned route for [_selectedOutingId], drawn over the map.
  PlannedRoute? _route;
  List<RouteWaypoint> _routeWaypoints = const [];

  /// The reserve context every local record is written into. Sync only works
  /// within the token's active context, so this adopts that context when a
  /// sign-in proves who the device belongs to.
  String _contextCode = 'field:write';

  @override
  void initState() {
    super.initState();
    _read();
    _restore();
    _watchTransport();
    _watchPosition();
    _loadReference();
    RecentSpecies.open().then((recent) => _recent = recent);
  }

  @override
  void dispose() {
    _position?.cancel();
    _transport?.cancel();
    widget.connectivity.dispose();
    super.dispose();
  }

  /// Read whatever token is on the phone and ask the service who it belongs to.
  ///
  /// A stored token proves nothing on its own: it may have expired, been
  /// revoked, or belong to an account that has since been disabled. So it is
  /// checked rather than trusted, and a failure here means "not signed in"
  /// rather than an error worth interrupting anybody for. The trainee can still
  /// record everything either way.
  Future<void> _restore() async {
    final stored = await widget.sessions.read();
    if (stored == null || !stored.isUsable || !mounted) {
      if (mounted) {
        setState(() => _restoring = false);
      }
      return;
    }
    try {
      final user = await widget.api.whoAmI(stored.accessToken);
      if (!mounted) {
        return;
      }
      _contextCode = user.activeContext ?? _contextCode;
      setState(() {
        _user = user;
        _restoring = false;
      });
    } on Object {
      // The token did not work. Clearing it stops the next launch trying it
      // again, and puts the trainee in front of the sign-in form rather than
      // silently signed in as nobody.
      await widget.sessions.clear();
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  void _watchTransport() {
    _transport = widget.connectivity.watch().listen((status) {
      if (!mounted) {
        return;
      }
      setState(() => _status = status);
    });
  }

  /// Follow the device's position and keep the map's fix and live marker
  /// current. Five metres of movement is enough to care about on a reserve
  /// track, and far fewer updates than a continuous stream.
  Future<void> _watchPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _position =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) {
            if (!mounted) {
              return;
            }
            setState(() {
              _gps = GpsReading(
                accuracyMetres: position.accuracy,
                satellites: 0,
                fixedAt: position.timestamp.toUtc(),
                latitude: position.latitude,
                longitude: position.longitude,
              );
              _currentPosition = LatLng(position.latitude, position.longitude);
            });
          });
    } on Object catch (error) {
      // No fix is not a broken screen: the bar shows the placeholder and the
      // rest of the logbook still works. The error is logged so a real fault
      // can be found once, on the device where it happened.
      debugPrint('position: $error');
    }
  }

  /// The reference data is loaded once at startup and refreshed from the menu.
  /// A cache miss is shown by the field cards as an empty species list, which
  /// is why the settings menu offers a human-triggered refresh.
  Future<void> _loadReference() async {
    try {
      final loader = ReferenceLoader(
        database: widget.database,
        api: widget.api,
        sessions: widget.sessions,
      );
      final snapshot = await loader.load();
      if (!mounted) {
        return;
      }
      setState(() => _reference = snapshot);
    } on Object catch (error) {
      debugPrint('reference: $error');
    }
  }

  Future<void> _signIn(String username, String password) async {
    final evidence = await widget.api.fetchLoginEvidence();
    final session = await widget.api.signIn(
      username: username,
      password: password,
      evidence: evidence,
    );
    await widget.sessions.write(
      StoredTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresInSeconds: session.expiresInSeconds,
      ),
    );
    _contextCode = session.user.activeContext ?? _contextCode;
    if (mounted) {
      setState(() => _user = session.user);
    }
  }

  Future<void> _signOut() async {
    final stored = await widget.sessions.read();
    await widget.sessions.clear();
    // Best effort. A sign-out that could not reach the service has still
    // removed the credential from this phone, which is the half that matters
    // when somebody has lost the device.
    if (stored != null && _status.hasTransport) {
      await widget.api.signOut(stored.refreshToken);
    }
    if (mounted) {
      setState(() => _user = null);
    }
  }

  Future<void> _read() async {
    final rows = await widget.database.select(widget.database.sightings).get();
    if (!mounted) {
      return;
    }
    setState(() {
      _pins = [
        for (final row in rows)
          MapPin(
            localId: row.localId,
            latitude: row.locationLat,
            longitude: row.locationLng,
            visual: pinVisualFor(row, commonNameFor: _nameOf),
            count: row.count ?? 1,
          ),
      ];
    });
  }

  /// A sighting the client cannot name is still a sighting, so the label falls
  /// back to the description rather than to nothing. This is deliberately
  /// crude: the species reference table arrives with the service, and until it
  /// does the map can say what was recorded but not what it was called.
  static String _nameOf(String code) => code;

  Future<void> _openLedger() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SyncLedgerScreen(entries: [], online: false),
      ),
    );
  }

  Future<void> _openTally() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TallyScreen(progress: TrailProgress.empty),
      ),
    );
  }

  /// Pushes the menu. Everything that used to be (or look like it should be)
  /// behind an account gesture lives here instead: the name chip, the server
  /// address, the reference data, the sign-out, the outing routes.
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          signedInAs: _user?.shortName,
          initialServer: widget.api.baseUrl,
          currentThemeMode: widget.currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onSignIn: () async {
            await _openSignIn();
            return _user?.shortName;
          },
          onSignOut: _signOut,
          onSaveServer: _saveServer,
          onLoadReference: ({required bool forceRefresh}) async {
            final loader = ReferenceLoader(
              database: widget.database,
              api: widget.api,
              sessions: widget.sessions,
            );
            final snapshot = await loader.load(forceRefresh: forceRefresh);
            return ReferenceLoadResult(
              speciesCount: snapshot.species.length,
              problem: snapshot.refreshError,
            );
          },
          onForceConnectivity: kDebugMode
              ? (status) async {
                  widget.connectivity.forceStatus(
                    status ??
                        const ConnectivityStatus(
                          hasTransport: false,
                          transports: [],
                        ),
                  );
                }
              : null,
          onOpenRouteEditor: (outing, existingRoute, existingWaypoints) async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RouteEditorScreen(
                  outing: outing,
                  existingRoute: existingRoute,
                  existingWaypoints: existingWaypoints,
                  onSaveRoute: (route, waypoints) async {
                    await _saveRoute(route, waypoints);
                  },
                  tileCache: widget.tileCache,
                ),
              ),
            );
            await _readRoute();
          },
          onLoadRoute: () async {
            return _loadRouteForOuting(_selectedOutingId ?? '');
          },
        ),
      ),
    );
  }

  /// Reads the planned route for the selected outing, if it has one.
  Future<void> _readRoute() async {
    final loaded = await _loadRouteForOuting(_selectedOutingId ?? '');
    if (!mounted) {
      return;
    }
    setState(() {
      _route = loaded.route;
      _routeWaypoints = loaded.waypoints;
    });
  }

  /// Loads the latest planned route and its ordered waypoints for an outing.
  Future<({PlannedRoute? route, List<RouteWaypoint> waypoints})>
  _loadRouteForOuting(String outingId) async {
    if (outingId.isEmpty) {
      return (route: null, waypoints: const <RouteWaypoint>[]);
    }
    final routeRow =
        await (widget.database.select(widget.database.plannedRoutes)
              ..where((t) => t.outingId.equals(outingId))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .getSingleOrNull();
    if (routeRow == null) {
      return (route: null, waypoints: const <RouteWaypoint>[]);
    }
    final waypoints =
        await (widget.database.select(widget.database.routeWaypoints)
              ..where((t) => t.routeId.equals(routeRow.localId))
              ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]))
            .get();
    return (route: routeRow, waypoints: waypoints);
  }

  /// Stores a route, replacing any route the outing already had.
  ///
  /// The planned route is owned by an outing, which is a Drives row on the
  /// client. The editor mints a fresh route id on every save, so the old route
  /// and its waypoints are removed rather than left to pile up as orphans the
  /// map no longer knows how to choose between.
  Future<void> _saveRoute(
    PlannedRoute route,
    List<RouteWaypoint> waypoints,
  ) async {
    await widget.database.transaction(() async {
      // The foreign key needs the outing to exist before the route can. An
      // outing that has never been started locally gets a row now, so planning
      // a route never fails because the record it belongs to is missing.
      await widget.database
          .into(widget.database.drives)
          .insert(
            DrivesCompanion.insert(
              localId: route.outingId,
              contextCode: _contextCode,
              startedAt: DateTime.now().toUtc(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      final old = await (widget.database.select(
        widget.database.plannedRoutes,
      )..where((t) => t.outingId.equals(route.outingId))).get();
      for (final row in old) {
        // Deleting the route drops its waypoints through the cascade, which is
        // why only the owner needs to be removed here.
        await (widget.database.delete(
          widget.database.plannedRoutes,
        )..where((t) => t.localId.equals(row.localId))).go();
      }
      await widget.database.into(widget.database.plannedRoutes).insert(route);
      for (final waypoint in waypoints) {
        await widget.database
            .into(widget.database.routeWaypoints)
            .insert(waypoint);
      }
    });
    if (!mounted) {
      return;
    }
    setState(() => _selectedOutingId = route.outingId);
    await _readRoute();
  }

  Future<void> _openSighting(String localId) async {
    // The row is fetched here rather than handed to the screen as an id, so the
    // screen never has to own a database and can be built and tested without
    // one. A pin that has no row cannot be opened, which is the honest outcome:
    // the map only draws pins for rows it has read.
    final row = await (widget.database.select(
      widget.database.sightings,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
    if (row == null || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PinDetailScreen(
          sighting: _summaryOf(row),
          onAddDetail: (kind, value) => _amend(row.localId, kind, value),
        ),
      ),
    );
  }

  /// Builds what the detail screen shows from a stored row.
  ///
  /// Deliberately mechanical. The screen asks for plain values so it can be
  /// built without a database, and the translation belongs in one place here
  /// rather than spread across whichever screen happens to read the row.
  /// Record an addition and queue it to go up.
  ///
  /// An unknown kind is refused rather than guessed. Writing an amendment to a
  /// record that nobody asked for is worse than writing none, because the
  /// record would then say something the reader did not say.
  Future<void> _amend(String localId, String kind, String value) async {
    final parsed = AmendmentKind.fromWire(kind);
    if (parsed == null) {
      return;
    }
    final amender = SightingAmender(
      widget.database,
      OperationQueue(widget.database),
    );
    final operationId = await amender.amend(
      localId,
      SightingAmendment(parsed, value),
    );
    if (operationId == null) {
      // The record went away between the reader opening it and the reader
      // writing on it. Nothing was changed, so nothing is claimed.
      return;
    }
    await _read();
  }

  SightingSummary _summaryOf(SightingRow row) {
    return SightingSummary(
      localId: row.localId,
      visual: pinVisualFor(row, commonNameFor: _nameOf),
      commonName: _nameOf(row.speciesCode ?? ''),
      scientificName: '',
      // The screen shows the status as the contract's word for it, so the
      // enum is converted rather than stringified: the wire names are the
      // service's, and toString on an enum would give the Dart identifier.
      status: statusWireName(row.status),
      capturedAt: row.capturedAt,
      recordedAt: row.recordedAt,
      // An absent accuracy is not zero metres. Zero would say the position is
      // exact, which is the opposite of what an unrecorded reading means.
      accuracyMetres: row.locationAccuracyM ?? double.infinity,
      distanceMetres: row.distanceM,
      bearingDegrees: row.bearingDeg,
      notes: row.notes ?? '',
      count: row.count,
      speciesCode: row.speciesCode,
      behaviour: row.behaviour,
      ageSexClass: row.ageSexClass,
      recordedSpeciesCode: row.recordedSpeciesCode,
      recordedCount: row.recordedCount,
      correctionReason: row.correctionReason,
      lateArrival: row.lateArrival,
    );
  }

  /// A coordinate as a label the way a guide reads one out loud, hemisphere
  /// first, to five decimal places. The card shows this so the reader can find
  /// the spot again the same way they read it from a map.
  String _coordinateLabel(LatLng point) {
    final hemisphere = point.latitude < 0 ? 'S' : 'N';
    final meridian = point.longitude < 0 ? 'W' : 'E';
    // ignore: lines_longer_than_80_chars
    return '${point.latitude.abs().toStringAsFixed(5)}\u00B0 $hemisphere, '
        '${point.longitude.abs().toStringAsFixed(5)}\u00B0 $meridian';
  }

  /// The Sightings Pin: one tap on the map records a sighting at that spot,
  /// with the species chosen from the recent list and the count adjusted, all
  /// without leaving the map. A long-press ghost pin funnels here too, so both
  /// gestures mean the same thing and there is not a second, slower path to
  /// learn.
  Future<void> _captureAt(LatLng point) async {
    final recent = await _recent?.list() ?? const <SpeciesChoice>[];
    if (!mounted) {
      return;
    }
    final snapshot = _reference;
    final result = await showQuickCaptureSheet(
      context,
      coordinateLabel: _coordinateLabel(point),
      recentSpecies: recent,
      allSpecies: snapshot?.species ?? const [],
    );
    if (result == null || !mounted) {
      return;
    }
    final writer = SightingWriter(
      widget.database,
      OperationQueue(widget.database),
    );
    await writer.record(
      contextCode: _contextCode,
      driveId: _selectedOutingId ?? '',
      location: GeoPoint(latitude: point.latitude, longitude: point.longitude),
      capturedAt: DateTime.now(),
      speciesCode: result.choice?.code,
      count: result.choice == null ? null : result.count,
      // Zero is the placeholder's accuracy, meaning "no fix happened yet", not
      // a measurement of nothing at one millimetre.
      locationAccuracyM: _gps.accuracyMetres == 0 ? null : _gps.accuracyMetres,
      notes: result.notes.isEmpty ? null : result.notes,
      createdBy: _user?.id,
    );
    if (result.choice != null) {
      await _recent?.note(result.choice!);
    }
    await _read();
  }

  /// The full field card, at the live position. The card collects everything
  /// the quick capture cannot ask for in one glance: behaviour, distance,
  /// direction, notes, photos, and the outing the record belongs to.
  Future<void> _recordSighting() async {
    final position = _currentPosition;
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waiting for a position fix')),
        );
      }
      return;
    }
    final recent = await _recent?.list() ?? const <SpeciesChoice>[];
    if (!mounted) {
      return;
    }
    final snapshot = _reference;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FieldCardScreen(
          initial: const FieldDraft(mode: CaptureMode.identified),
          species: snapshot?.species ?? const [],
          reference:
              snapshot?.reference ??
              const ReferenceValues(behaviours: [], ageSexClasses: []),
          coordinateLabel: _coordinateLabel(position),
          accuracyMetres: _gps.accuracyMetres == 0 ? null : _gps.accuracyMetres,
          outings: snapshot?.outings ?? const [],
          selectedOutingId: _selectedOutingId,
          onOutingChanged: (id) => setState(() => _selectedOutingId = id),
          recentSpecies: recent,
          onReloadSpecies: () {
            final loader = ReferenceLoader(
              database: widget.database,
              api: widget.api,
              sessions: widget.sessions,
            );
            return loader.load(forceRefresh: true);
          },
          onSpeciesUsed: (choice) {
            _recent?.note(choice);
          },
          onSave: (draft) async {
            final writer = SightingWriter(
              widget.database,
              OperationQueue(widget.database),
            );
            await writer.record(
              contextCode: _contextCode,
              driveId: _selectedOutingId ?? '',
              location: GeoPoint(
                latitude: position.latitude,
                longitude: position.longitude,
              ),
              capturedAt: draft.capturedAt ?? DateTime.now(),
              speciesCode: draft.speciesCode,
              count: draft.count,
              locationAccuracyM: _gps.accuracyMetres == 0
                  ? null
                  : _gps.accuracyMetres,
              distanceMetres: draft.distanceMetres,
              bearingDegrees: draft.bearingDegrees,
              behaviour: draft.behaviour,
              ageSexClass: draft.ageSexClass,
              notes: draft.notes.isEmpty ? null : draft.notes,
              createdBy: _user?.id,
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
    await _read();
  }

  @override
  Widget build(BuildContext context) {
    final map = MapScreen(
      pins: _pins,
      queuedCount: _queued,
      colours: FieldColours.dark,
      online: _status.hasTransport,
      signedInAs: _user?.shortName,
      onTapSignedInAs: _user == null ? _openSignIn : null,
      onOpenSettings: _openSettings,
      tileCache: widget.tileCache,
      gps: _gps,
      currentPosition: _currentPosition,
      route: _route,
      routeWaypoints: _routeWaypoints,
      onMapTap: _captureAt,
      onDropPin: _captureAt,
      onOpenLedger: _openLedger,
      onOpenTally: _openTally,
      onOpenSighting: _openSighting,
      onRecordSighting: _recordSighting,
    );

    // Signing in is an invitation, not a gate. The contract's rule 19 is that
    // readiness never blocks submission, and the design's own line is "you can
    // record without signing in", so an unsigned-in device gets the map with a
    // quiet offer rather than a form it cannot get past.
    if (_user != null || _offerDismissed) {
      return map;
    }
    return Stack(
      children: [
        map,
        if (!_restoring)
          Positioned(
            left: Insets.lg,
            right: Insets.lg,
            bottom: 160,
            child: _SignInOffer(
              onSignIn: _openSignIn,
              onDismiss: () => setState(() => _offerDismissed = true),
            ),
          ),
      ],
    );
  }

  /// Points the client at a different server and remembers the choice.
  ///
  /// The client instance is shared by every caller (sync, reference data,
  /// sign-in), so changing its baseUrl here is the whole configuration —
  /// there is no second place that also needs to know.
  Future<void> _saveServer(String url) async {
    widget.api.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chisimba_api_url', url);
  }

  Future<void> _openSignIn() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignInScreen(
          onSignIn: _signIn,
          initialServer: widget.api.baseUrl,
          onSaveServer: _saveServer,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

/// A quiet offer to sign in, sitting above the map's own dock.
///
/// Dismissable, and dismissal is remembered for the session. A device that has
/// chosen to work offline should not be asked again on every rebuild.
class _SignInOffer extends StatelessWidget {
  const _SignInOffer({required this.onSignIn, required this.onDismiss});

  final VoidCallback onSignIn;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: BorderRadius.circular(Corners.sheet),
        border: Border.all(color: colours.rule),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Not sending yet',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                    color: colours.bone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Records are safe on this phone.',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.stamp,
                    color: colours.ash2,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSignIn, child: const Text('Sign in')),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, size: 18, color: colours.ash3),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
