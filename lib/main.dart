import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm;
import 'package:flutter_map/flutter_map.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/drive_writer.dart';
import 'package:field_log/data/encounter_writer.dart';
import 'package:field_log/data/route_writer.dart';
import 'package:field_log/data/trail_log_writer.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/pull_engine.dart';
import 'package:field_log/data/push_engine.dart';
import 'package:field_log/data/recent_species.dart';
import 'package:field_log/data/reference_loader.dart';
import 'package:field_log/data/sighting_amendments.dart';
import 'package:field_log/data/sighting_writer.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/card_state.dart';
import 'package:field_log/field/field_card_screen.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/map/progress_overlay.dart';
import 'package:field_log/progress/progress_loader.dart';
import 'package:field_log/map/maptiler_tiles.dart';
import 'package:field_log/models/sync_operation.dart' as model;
import 'package:field_log/map/tile_cache.dart';
import 'package:field_log/models/geo_point.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:field_log/net/connectivity_watcher.dart';
import 'package:field_log/net/session_store.dart';
import 'package:field_log/screens/map_screen.dart';
import 'package:field_log/screens/observations_screen.dart';
import 'package:field_log/screens/trail_logbook_screen.dart';
import 'package:field_log/screens/drive_logbook_screen.dart';
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
import 'package:uuid/uuid.dart';

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
  // developer's hands. The base is the host only: ChisimbaApi puts the
  // version and path on every request itself, so a default that already
  // carried /api/v1 would double it and 404 every call.
  const serviceUrl = String.fromEnvironment(
    'CHISIMBA_API',
    defaultValue: 'http://localhost:8080',
  );
  // A server the operator corrected on the sign-in screen outlives the run
  // that typed it: the remembered address wins over the build-time default,
  // or the correction would have to be retyped after every restart.
  final prefs = await SharedPreferences.getInstance();
  final rememberedServer = prefs.getString('chisimba_api_url');
  runApp(
    FieldLogApp(
      database: database,
      tileCache: tileCache,
      api: ChisimbaApi(baseUrl: rememberedServer ?? serviceUrl),
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
  ThemeVariant _themeVariant = ThemeVariant.standard;
  Density _density = Density.comfortable;
  MapStylePreset _mapStylePreset = MapStylePreset.field;

  @override
  void initState() {
    super.initState();
    _restoreThemeSettings();
  }

  Future<void> _restoreThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode');
    final savedVariant = prefs.getString('theme_variant');
    final savedDensity = prefs.getString('theme_density');
    final savedMapStyle = prefs.getString('map_style_preset');
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = switch (savedMode) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
      _themeVariant = switch (savedVariant) {
        'high-contrast' => ThemeVariant.highContrast,
        'sepia' => ThemeVariant.sepia,
        _ => ThemeVariant.standard,
      };
      _density = switch (savedDensity) {
        'compact' => Density.compact,
        'spacious' => Density.spacious,
        _ => Density.comfortable,
      };
      _mapStylePreset = switch (savedMapStyle) {
        'navigation' => MapStylePreset.navigation,
        'survey' => MapStylePreset.survey,
        _ => MapStylePreset.field,
      };
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> _setThemeVariant(ThemeVariant variant) async {
    setState(() => _themeVariant = variant);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_variant', variant.name);
  }

  Future<void> _setDensity(Density density) async {
    setState(() => _density = density);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_density', density.name);
  }

  Future<void> _setMapStylePreset(MapStylePreset preset) async {
    setState(() => _mapStylePreset = preset);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_style_preset', preset.name);
  }

  FieldColours _currentColours() {
    switch (_themeVariant) {
      case ThemeVariant.highContrast:
        return FieldColours.highContrast;
      case ThemeVariant.sepia:
        return FieldColours.sepia;
      case ThemeVariant.standard:
        return _themeMode == ThemeMode.light
            ? FieldColours.sunlight
            : FieldColours.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Disable animations when user prefers reduced motion
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final colours = _currentColours();

    return MaterialApp(
      title: 'Field log',
      debugShowCheckedModeBanner: false,
      theme: fieldTheme(_currentColours()),
      darkTheme: fieldTheme(_currentColours()),
      themeMode: _themeMode,
      builder: (context, child) {
        // Disable animations globally when user prefers reduced motion
        if (disableAnimations) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              boldText: MediaQuery.of(context).boldText,
            ),
            child: child!,
          );
        }
        return child!;
      },
      home: FieldLogHome(
        database: widget.database,
        tileCache: widget.tileCache,
        api: widget.api,
        sessions: widget.sessions,
        connectivity: widget.connectivity,
        currentThemeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        currentThemeVariant: _themeVariant,
        onThemeVariantChanged: _setThemeVariant,
        currentDensity: _density,
        onDensityChanged: _setDensity,
        currentMapStylePreset: _mapStylePreset,
        onMapStylePresetChanged: _setMapStylePreset,
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
    required this.currentThemeVariant,
    required this.onThemeVariantChanged,
    required this.currentDensity,
    required this.onDensityChanged,
    required this.currentMapStylePreset,
    required this.onMapStylePresetChanged,
    this.tileCache,
  });

  final FieldLogDatabase database;
  final ChisimbaApi api;
  final SessionStore sessions;
  final ConnectivityWatcher connectivity;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeVariant currentThemeVariant;
  final ValueChanged<ThemeVariant> onThemeVariantChanged;
  final Density currentDensity;
  final ValueChanged<Density> onDensityChanged;
  final MapStylePreset currentMapStylePreset;
  final ValueChanged<MapStylePreset> onMapStylePresetChanged;
  final TileCache? tileCache;

  @override
  State<FieldLogHome> createState() => _FieldLogHomeState();
}

class _FieldLogHomeState extends State<FieldLogHome> {
  List<MapPin> _pins = const [];

  /// How many queued operations have not settled.
  ///
  /// Read from the queue rather than counted by hand: the badge and the
  /// ledger must agree, and they can only agree if there is one source.
  int _queued = 0;

  /// The sync machinery, built once.
  ///
  /// One queue shared by every writer is what makes the badge honest — an
  /// [OperationQueue] per capture would still work against the same table,
  /// but the engines and the writers must agree on which queue is the queue
  /// when they name dependencies on each other's operations.
  late final OperationQueue _queue;
  late final PushEngine _push;
  late final PullEngine _pull;
  late final SightingWriter _sightings;
  late final SightingAmender _amender;
  late final DriveWriter _drives;
  late final TrailLogWriter _trails;
  late final EncounterWriter _encounters;
  late final RouteWriter _routes;

  /// Whether a sync is in flight, so a transport flap or a capture mid-sync
  /// does not start a second push against the same batch.
  bool _syncing = false;

  /// When the last sync finished cleanly, for the "last synced" stamp.
  ///
  /// Null until the first successful sync, which is the honest beginning: a
  /// device that has never sent anything has no "last synced" to claim.
  DateTime? _lastSyncedAt;

  /// Why the last sync failed, shown where the queue is read.
  ///
  /// Cleared by a later successful sync. Kept separate from [_syncing] because
  /// the two tell different stories: a spinner says "trying now", an error
  /// says "the last try did not land".
  String? _syncError;

  /// Drives the 2-minute sync while the phone is online and signed in, so a
  /// long queue does not wait for the next transport event to drain.
  Timer? _syncTimer;

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

  /// The chip that remembers [_selectedOutingId] across restarts, so a planned
  /// route is drawn on the map again when the app opens rather than waiting for
  /// somebody to walk back through the route editor.
  static const _selectedOutingKey = 'chisimba_selected_outing';

  /// The outing currently running, so the map's progress card can show a live
  /// elapsed readout — and a Stop action — while a drive or walk is on.
  ///
  /// Deliberately separate from [_selectedOutingId]: the selection survives
  /// the end of a drive (sightings filed after the vehicle stops still belong
  /// to it), while the active indicator exists only while something is being
  /// driven or walked and is cleared the moment it ends.
  String? _activeOutingId;

  /// Which logbook opened [_activeOutingId]: 'drive' or 'trail'.
  String _activeOutingKind = 'drive';

  /// The word the card leads with, derived from [_activeOutingKind].
  String _activeOutingLabel = '';

  /// When [_activeOutingId] started, for the card's ticking readout.
  DateTime? _activeOutingStartedAt;

  /// The kind of [_selectedOutingId] as reported by the logbook that started
  /// it. Kept after the active indicator clears, so a trail that has ended is
  /// still known to be a trail while it remains the selected outing.
  String? _selectedOutingKind;

  static const _activeOutingKey = 'chisimba_active_outing';
  static const _activeOutingKindKey = 'chisimba_active_outing_kind';
  static const _activeOutingStartedAtKey = 'chisimba_active_outing_started_at';

  /// A stable id for this phone, minted once and kept for the life of the
  /// install. The service binds a refresh token to the device id given at
  /// sign-in and refuses to rotate it for any other, so the same value has to
  /// be presented on every launch. It is not a secret.
  static const _deviceIdKey = 'chisimba_device_id';

  /// The planned route for [_selectedOutingId], drawn over the map.
  PlannedRoute? _route;
  List<RouteWaypoint> _routeWaypoints = const [];

  /// Trail and drive hours for the card that sits on the map. Refolded from the
  /// database whenever a walk or a drive changes, and empty until the first
  /// read, so the card never claims a total it has not actually loaded.
  OutingProgress _progress = OutingProgress.empty;

  /// The reserve context every local record is written into. Sync only works
  /// within the token's active context, so this adopts that context when a
  /// sign-in proves who the device belongs to.
  String _contextCode = 'field:write';

  /// Key to access the MapScreenState and its map controller.
  final _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _queue = OperationQueue(widget.database);
    _push = PushEngine(widget.database, _queue);
    _pull = PullEngine(widget.database);
    _sightings = SightingWriter(widget.database, _queue);
    _amender = SightingAmender(widget.database, _queue);
    _drives = DriveWriter(widget.database, _queue);
    _trails = TrailLogWriter(widget.database, queue: _queue);
    _encounters = EncounterWriter(widget.database, _queue);
    _routes = RouteWriter(widget.database, _queue, _contextCode);
    _read();
    _readProgress();
    _restore();
    _watchTransport();
    _watchPosition();
    _loadReference();
    RecentSpecies.open().then((recent) => _recent = recent);
    // Operations interrupted by a crash are recoverable states, not lost
    // ones; running this at startup is what turns an inflight row left by a
    // mid-push kill into something the next sync will offer again.
    unawaited(_recoverAndCount());
    // A long queue drains over transport events, but a quiet phone with a
    // radio up has no events. The periodic sync offers the queue again so a
    // backhaul that limped mid-batch is not a queue that stops being asked.
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_user != null && _status.hasTransport && !_syncing) {
        unawaited(_sync());
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
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
    // The selected outing is remembered apart from the session: a planned route
    // belongs to the phone rather than the account, and has to be drawn whether
    // or not anyone is signed in.
    final prefs = await SharedPreferences.getInstance();
    final rememberedOuting = prefs.getString(_selectedOutingKey);
    if (rememberedOuting != null && rememberedOuting.isNotEmpty && mounted) {
      _selectedOutingId = rememberedOuting;
      await _readRoute();
    }
    // The active indicator is restored for the same reason: a drive or walk
    // interrupted by a restart is still running, and the card should come
    // back with it. The logbook screen owns the record itself; this only
    // restores the indicator, and ending the outing from its own screen clears
    // it again.
    final activeId = prefs.getString(_activeOutingKey);
    if (activeId != null && activeId.isNotEmpty && mounted) {
      final kind = prefs.getString(_activeOutingKindKey) ?? 'drive';
      final startedAt =
          DateTime.tryParse(prefs.getString(_activeOutingStartedAtKey) ?? '') ??
          DateTime.now().toUtc();
      setState(() {
        _activeOutingId = activeId;
        _activeOutingKind = kind;
        _activeOutingStartedAt = startedAt;
        _activeOutingLabel = kind == 'trail' ? 'Trail' : 'Drive';
      });
    }
    if (!mounted) {
      return;
    }
    final stored = await widget.sessions.read();
    if (stored == null || !stored.isUsable || !mounted) {
      if (mounted) {
        setState(() => _restoring = false);
      }
      return;
    }
    try {
      // A token past its hour is renewed rather than thrown away: the refresh
      // token lives far longer, and signing a trainee out mid-season because
      // they opened the app the next morning is the bug this avoids.
      var session = await _freshSession();
      if (session == null) {
        if (mounted) {
          setState(() => _restoring = false);
        }
        return;
      }
      FieldUser user;
      try {
        user = await widget.api.whoAmI(session.accessToken);
      } on AuthFailure catch (error) {
        if (!error.isUnauthorized) {
          rethrow;
        }
        // A 401 with a token that read as still valid means it was revoked or
        // the clock is off. One renewal, then believe the service.
        final renewed = await _refreshTokens(session);
        if (renewed == null) {
          if (mounted) {
            setState(() => _restoring = false);
          }
          return;
        }
        session = renewed;
        user = await widget.api.whoAmI(session.accessToken);
      }
      if (!mounted) {
        return;
      }
      _contextCode = user.activeContext ?? _contextCode;
      setState(() {
        _user = user;
        _restoring = false;
      });
      // The token proved itself; if the radio is up, offer the queue now
      // rather than waiting for a transport event that may never re-fire.
      if (_status.hasTransport) unawaited(_sync());
    } on Object {
      // The session is genuinely gone. Clearing it stops the next launch
      // trying it again, and puts the trainee in front of the sign-in form
      // rather than silently signed in as nobody.
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
      // Coming back into coverage is the moment the queue has been waiting
      // for. The sync guards itself against already being in flight.
      if (status.hasTransport && _user != null) unawaited(_sync());
    });
  }

  /// Settle operations an interrupted push left behind, then read the badge.
  Future<void> _recoverAndCount() async {
    await _queue.recoverInterrupted();
    await _refreshQueued();
  }

  /// Re-read the queued count from the queue itself.
  Future<void> _refreshQueued() async {
    final rows = await _queue.pending();
    if (!mounted) return;
    setState(() => _queued = rows.length);
  }

  /// Send what is queued, then take in what has changed.
  ///
  /// Push goes first, deliberately: this device's own operations settle and
  /// stamp their accepted revisions before the pull's echo of the same
  /// records arrives, so the echo lands on a revision the store already
  /// holds and is absorbed as the no-op it is instead of being read as a
  /// disagreement. A single guard makes a transport flap or a capture
  /// landing mid-sync harmless.
  /// A stable id for this phone, minted once and kept.
  ///
  /// The service binds a refresh token to the device id given at sign-in and
  /// refuses to rotate it for any other, so this has to be the same value on
  /// every launch. It is not a secret and carries nothing about the user; it
  /// only tells the service that the token belongs to this install.
  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final minted = const Uuid().v4();
    await prefs.setString(_deviceIdKey, minted);
    return minted;
  }

  /// Exchange the stored refresh token for a new token pair.
  ///
  /// Returns the fresh tokens and persists them, or null when the service
  /// refuses — which means the session is genuinely over, so the stored one is
  /// cleared and nothing keeps presenting a dead token.
  Future<StoredTokens?> _refreshTokens(StoredTokens stored) async {
    try {
      final refreshed = await widget.api.refreshSession(
        refreshToken: stored.refreshToken,
        deviceId: await _deviceId(),
      );
      final renewed = StoredTokens(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
        expiresInSeconds: refreshed.expiresInSeconds,
        issuedAt: DateTime.now(),
      );
      await widget.sessions.write(renewed);
      return renewed;
    } on AuthFailure {
      await widget.sessions.clear();
      return null;
    }
  }

  /// The session to use now, renewing a stale access token first.
  ///
  /// Returns null when there is no usable session, or when it could not be
  /// renewed; the caller then treats the phone as signed out.
  Future<StoredTokens?> _freshSession() async {
    final stored = await widget.sessions.read();
    if (stored == null || !stored.isUsable) {
      return null;
    }
    if (!stored.isAccessTokenExpired) {
      return stored;
    }
    return _refreshTokens(stored);
  }

  /// Stand the trainee down because their session ended, once and plainly.
  ///
  /// This is deliberately not the sign-in-failure sentence: the name and
  /// password were never the problem, the token simply aged out, and saying
  /// otherwise sends somebody hunting for a typo they do not have.
  Future<void> _sessionExpired() async {
    await widget.sessions.clear();
    if (!mounted) {
      return;
    }
    setState(() => _user = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session expired — please sign in again.'),
      ),
    );
  }

  Future<void> _sync() async {
    if (_syncing || _user == null || !_status.hasTransport) {
      return;
    }
    _syncing = true;
    try {
      final stored = await _freshSession();
      if (stored == null) {
        if (mounted) {
          setState(() => _user = null);
        }
        return;
      }

      PushOutcomeReport report;
      try {
        report = await _runSyncWith(stored.accessToken);
      } on AuthFailure catch (error) {
        // A 401 means the token went stale between the check above and the
        // service's answer. Renew once and try again; anything else is a real
        // failure and is reported as one.
        if (!error.isUnauthorized) {
          rethrow;
        }
        final renewed = await _refreshTokens(stored);
        if (renewed == null) {
          await _sessionExpired();
          return;
        }
        report = await _runSyncWith(renewed.accessToken);
      }

      // A clean sync is the one thing the phone can report without the
      // service's help. It resets the failure line and stamps the clock; the
      // map shows the stamp, and a failure that came before it is gone.
      final pushed = report.sentOperationIds.length;
      _lastSyncedAt = DateTime.now();
      final wasFailing = _syncError != null;
      _syncError = null;
      if (mounted) {
        // Only a sync that actually sent something is worth a toast. A quiet
        // two-minute check-in that moved nothing would nag twice a minute.
        if (pushed > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pushed == 1
                    ? 'Synced — 1 change uploaded'
                    : 'Synced — $pushed changes uploaded',
              ),
            ),
          );
        } else if (wasFailing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Back online — sync is clean.')),
          );
        }
      }
    } on Object catch (error) {
      // Being offline in the middle of a sync is a normal field condition,
      // not a fault worth interrupting anybody for. The queue keeps what was
      // not accepted, and the next transport event tries again.
      debugPrint('sync: $error');
      final freshFailure = _syncError == null;
      _syncError = error.toString();
      if (freshFailure && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed — clearing up for another try.')),
        );
      }
    } finally {
      _syncing = false;
      await _refreshQueued();
      if (mounted) {
        await _read();
      }
    }
  }

  /// Push the queue and pull the feed with [token], returning the push report.
  ///
  /// Split out of [_sync] so a stale-token retry can run the whole exchange
  /// again with a renewed token without duplicating the translation between
  /// the transport's result words and the engine's outcome enum.
  Future<PushOutcomeReport> _runSyncWith(String token) async {
    final report = await _push.push(
      send: (batch) async {
        final request = PushRequest(
          operations: [
            for (final operation in batch)
              PushOperation.fromJson(operationToWire(operation)),
          ],
        );
        final response = await widget.api.push(token, request);
        // The transport's result names its outcome in the service's words;
        // the engine's contract names it in the enum. The two are different
        // types on purpose, and this is the one place they are translated.
        return [
          for (final result in response.results)
            model.PushResult(
              operationId: result.operationId,
              outcome: switch (result.outcome) {
                'applied' => model.PushOutcome.applied,
                'noop' => model.PushOutcome.noop,
                'deferred' => model.PushOutcome.deferred,
                'refused' => model.PushOutcome.refused,
                // An outcome this client has never heard of is treated as
                // deferred: offered again, with its unknown string still
                // readable in the ledger, rather than being marked settled
                // and dropped because a newer service grew a word.
                _ => model.PushOutcome.deferred,
              },
              newRevision: result.newRevision,
              errorCode: result.errorCode,
              serverState: result.serverState,
              serverRevision: result.serverRevision,
            ),
        ];
      },
    );
    debugPrint(
      'sync: pushed ${report.sentOperationIds.length}, '
      '${report.applied} applied, ${report.refused} refused, '
      '${report.deferred} waiting',
    );

    await _pullPages(token);
    return report;
  }

  /// Pull pages until the feed runs dry or the service asks for a re-pull.
  ///
  /// Each page is applied in its own transaction with its cursor advanced in
  /// that same transaction, so a crash between pages resumes exactly where
  /// the store actually got to. A `resync_required` discards the cursor and
  /// starts once from the beginning: re-delivery is harmless because every
  /// change is applied by revision, but a second resync inside one sync is a
  /// service that cannot settle, and looping on it would never return.
  Future<void> _pullPages(String token) async {
    var cursor = await _pull.cursorFor(_contextCode);
    var restarted = false;
    while (true) {
      final response = await widget.api.pull(
        token,
        // The service reads an empty cursor as "from the beginning", which
        // is exactly what a device pulling for the first time means.
        PullRequest(cursor: cursor ?? ''),
      );
      final page = response.toPage();
      final outcome = await _pull.applyPage(scope: _contextCode, page: page);
      if (outcome.resyncRequired) {
        if (restarted) {
          return;
        }
        restarted = true;
        await _pull.forgetCursors();
        cursor = null;
        continue;
      }
      if (!page.hasMore || outcome.nextCursor == null) {
        return;
      }
      cursor = outcome.nextCursor;
    }
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
        renewSession: _refreshTokens,
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
    debugPrint('SIGNIN: server=${widget.api.baseUrl}');
    final evidence = await widget.api.fetchLoginEvidence();
    final session = await widget.api.signIn(
      username: username,
      password: password,
      evidence: evidence,
      deviceId: await _deviceId(),
    );
    await widget.sessions.write(
      StoredTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresInSeconds: session.expiresInSeconds,
        // Stamped so the token's hour can be measured later and renewed
        // before it lapses rather than after a 401.
        issuedAt: DateTime.now(),
      ),
    );
    _contextCode = session.user.activeContext ?? _contextCode;
    if (mounted) {
      setState(() => _user = session.user);
      unawaited(_sync());
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

  /// Refolds the trail and drive hours for the map's progress card. Reads the
  /// database directly, so it is cheap enough to run after any record changes.
  Future<void> _readProgress() async {
    final progress = await ProgressLoader(widget.database).load();
    if (!mounted) {
      return;
    }
    setState(() => _progress = progress);
  }

  /// A sighting the client cannot name is still a sighting, so the label falls
  /// back to the description rather than to nothing. This is deliberately
  /// crude: the species reference table arrives with the service, and until it
  /// does the map can say what was recorded but not what it was called.
  static String _nameOf(String code) => code;

  Future<void> _openLedger() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SyncLedgerScreen(
          // The screen reads the queue itself, so what it shows after a sync
          // is the queue's current truth rather than a list snapshotted when
          // the button was pressed.
          database: widget.database,
          online: _status.hasTransport,
          onSyncNow: () => unawaited(_sync()),
          lastSyncedAt: _lastSyncedAt,
        ),
      ),
    );
  }

  /// The competency catalogue the tally measures requirements against, or an
  /// empty list when there is no session or the service cannot be reached. The
  /// tally is still worth opening without it: it shows the hours either way.
  Future<List<Competency>> _loadCompetencies() async {
    final session = await _freshSession();
    if (session == null) {
      return const [];
    }
    try {
      final catalogue = await widget.api.getCompetencies(session.accessToken);
      return catalogue.competencies;
    } on Object {
      return const [];
    }
  }

  Future<void> _openTally() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TallyScreen(
          // Load from the database so the screen tells the truth about what
          // has actually been walked. An empty progress object would paint
          // the tab as if nothing had ever been recorded, even when trail
          // logs exist.
          database: widget.database,
          // The requirements come from the competency catalogue. Without it the
          // hours still show; the sign-off list is simply not drawn.
          onLoadCompetencies: _loadCompetencies,
          // A total nobody can correct is a total nobody trusts. Both of these
          // write through the same writers the logbooks use, so the record and
          // the queue move together and the next sync offers the correction.
          onEditTrail: (localId) async {
            final row = await (widget.database.select(
              widget.database.trailLogs,
            )..where((t) => t.localId.equals(localId))).getSingleOrNull();
            if (row == null || !mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TrailLogbookScreen(
                  database: widget.database,
                  writer: _trails,
                  encounters: _encounters,
                  contextCode: _contextCode,
                  driveId: row.driveId ?? '',
                  guideId: row.guideRole,
                  species: const [],
                  recentSpecies: const [],
                  editTrail: row,
                ),
              ),
            );
            if (!mounted) return;
            await _readProgress();
          },
          onEditDrive: (localId) async {
            final row = await (widget.database.select(
              widget.database.drives,
            )..where((t) => t.localId.equals(localId))).getSingleOrNull();
            if (row == null || !mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DriveLogbookScreen(
                  database: widget.database,
                  writer: _drives,
                  contextCode: _contextCode,
                  guideId: _user?.id,
                  editDrive: row,
                ),
              ),
            );
            if (!mounted) return;
            await _readProgress();
          },
        ),
      ),
    );
  }

  /// The drive logbook: start, watch, and close a drive.
  ///
  /// The screen owns the live arithmetic; this wiring owns what the rest of
  /// the app needs to know afterwards — that the drive now exists (so map
  /// taps file against it) and that the queue may have grown (so the badge
  /// and the sync both hear about it).
  Future<void> _openDrive() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DriveLogbookScreen(
          database: widget.database,
          writer: _drives,
          contextCode: _contextCode,
          guideId: _user?.id,
          onDriveStarted: (localId) {
            // Sightings tapped from now on belong to this drive, and the map
            // draws this drive's planned route. Ending a drive does not clear
            // it: observations made at the sighting point after the vehicle
            // stops are still on that drive.
            _setSelectedOuting(localId);
            _setActiveOuting(localId, 'drive');
          },
          onDriveEnded: () {
            // The drive row is closed by the logbook; the card comes off the
            // map here so the map never claims a drive that is over. The
            // selection above is deliberately left alone.
            _stopActiveOuting();
            _refreshQueued();
            if (_status.hasTransport) unawaited(_sync());
          },
        ),
      ),
    );
    await _readProgress();
  }

  /// The trail logbook: start a walk, drop waypoints, record encounters,
  /// close it — mirroring the drive logbook for the second capture mode.
  Future<void> _openTrail() async {
    final recent = _recent != null
        ? await _recent!.list()
        : const <SpeciesChoice>[];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrailLogbookScreen(
          database: widget.database,
          writer: _trails,
          encounters: _encounters,
          contextCode: _contextCode,
          driveId: _selectedOutingId ?? '',
          guideId: _user?.id,
          species: _reference?.species ?? const <SpeciesChoice>[],
          recentSpecies: recent,
          onSpeciesUsed: (choice) => _recent?.note(choice),
          onTrailStarted: (localId) {
            _setSelectedOuting(localId);
            _setActiveOuting(localId, 'trail');
          },
          onTrailEnded: () {
            // Same split as the drive: the logbook closes the walk, the card
            // comes off the map, and the selection survives for the record.
            _stopActiveOuting();
            _refreshQueued();
            if (_status.hasTransport) unawaited(_sync());
          },
        ),
      ),
    );
    await _readProgress();
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
          currentThemeVariant: widget.currentThemeVariant,
          onThemeVariantChanged: widget.onThemeVariantChanged,
          currentDensity: widget.currentDensity,
          onDensityChanged: widget.onDensityChanged,
          currentMapStylePreset: widget.currentMapStylePreset,
          onMapStylePresetChanged: widget.onMapStylePresetChanged,
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
              renewSession: _refreshTokens,
            );
            final snapshot = await loader.load(forceRefresh: forceRefresh);
            return ReferenceLoadResult(
              speciesCount: snapshot.species.length,
              problem: snapshot.refreshError,
            );
          },
          onForceConnectivity: kDebugMode
              ? (status) async {
                  // Null clears the override: the real probe answers again
                  // rather than being pinned to no-signal.
                  widget.connectivity.forceStatus(status);
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
          onLoadRoute: _loadRouteForOuting,
          routeOuting: _routeOuting(),
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
    final waypoints = loaded.waypoints;
    if (waypoints.length >= 2) {
      /// Fit the camera to show all route waypoints, framed with padding.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapKey.currentState?.fitCamera(
            CameraFit.coordinates(
              coordinates: waypoints
                  .map((w) => LatLng(w.latitude, w.longitude))
                  .toList(),
              padding: const EdgeInsets.all(40),
            ),
          );
        }
      });
    }
  }

  /// Chooses the outing captures and routes are filed against, remembering it
  /// across restarts and redrawing the map's planned route for the new outing.
  ///
  /// The same id selects the capture owner and the route to draw, so the two
  /// can never disagree about which outing is "current".
  void _setSelectedOuting(String? id) {
    if (id == _selectedOutingId) {
      return;
    }
    setState(() => _selectedOutingId = id);
    unawaited(_rememberOuting(id));
    unawaited(_readRoute());
  }

  Future<void> _rememberOuting(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_selectedOutingKey);
    } else {
      await prefs.setString(_selectedOutingKey, id);
    }
  }

  /// Marks an outing as running: the map's card shows a live elapsed readout
  /// and a Stop action from this moment until the logbook ends it.
  void _setActiveOuting(String localId, String kind) {
    if (_activeOutingId == localId && _activeOutingKind == kind) {
      return;
    }
    setState(() {
      _activeOutingId = localId;
      _activeOutingKind = kind;
      _activeOutingStartedAt = DateTime.now().toUtc();
      _activeOutingLabel = kind == 'trail' ? 'Trail' : 'Drive';
      _selectedOutingKind = kind;
    });
    unawaited(_rememberActiveOuting());
  }

  /// Takes the active-offing card off the map.
  ///
  /// Deliberately does not end the record: the drive or trail row is closed by
  /// its own logbook screen, which owns the facts of the end (hours, head
  /// count). This only clears the indicator — so [_selectedOutingId], the
  /// outing captures are filed against, survives untouched.
  void _stopActiveOuting() {
    if (_activeOutingId == null) {
      return;
    }
    setState(() {
      _activeOutingId = null;
      _activeOutingKind = 'drive';
      _activeOutingLabel = '';
      _activeOutingStartedAt = null;
    });
    unawaited(_forgetActiveOuting());
  }

  Future<void> _rememberActiveOuting() async {
    final prefs = await SharedPreferences.getInstance();
    final id = _activeOutingId;
    if (id == null) {
      return;
    }
    await prefs.setString(_activeOutingKey, id);
    await prefs.setString(_activeOutingKindKey, _activeOutingKind);
    final startedAt = _activeOutingStartedAt;
    if (startedAt != null) {
      await prefs.setString(
        _activeOutingStartedAtKey,
        startedAt.toIso8601String(),
      );
    }
  }

  Future<void> _forgetActiveOuting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOutingKey);
    await prefs.remove(_activeOutingKindKey);
    await prefs.remove(_activeOutingStartedAtKey);
  }

  /// Whether the selected outing is a walk rather than a drive, so the field
  /// card keeps trail-only fields (lessons learned, hours on this walk, rifle
  /// role) off a capture made during a drive.
  ///
  /// A log this phone started has no row in the service's outings list, so its
  /// kind is the one its logbook reported when it started; a planned outing
  /// picked from the reference list carries its own kind.
  bool get _isTrailWalk {
    final id = _selectedOutingId;
    if (id == null) {
      return false;
    }
    for (final o in _reference?.outings ?? const <Outing>[]) {
      if (o.id == id) {
        final k = o.kind.toLowerCase();
        return k.contains('trail') || k.contains('walk') || k.contains('hike');
      }
    }
    return _selectedOutingKind == 'trail';
  }

  /// The outing the route editor plans for: the selected one when there is
  /// one, else the first the reference data knows about, else null so the
  /// editor can say a walk or drive has to come first.
  ///
  /// A selected outing the service has not listed yet (an offline log) is
  /// described just well enough to hang a route on, because the route only
  /// needs an owner id; nothing about the route depends on the other fields.
  Outing? _routeOuting() {
    final id = _selectedOutingId;
    final known = _reference?.outings ?? const <Outing>[];
    if (id == null || id.isEmpty) {
      return known.isEmpty ? null : known.first;
    }
    for (final outing in known) {
      if (outing.id == id) {
        return outing;
      }
    }
    return Outing(
      id: id,
      kind: 'Field outing',
      contextCode: _contextCode,
      guideId: _user?.id ?? '',
      traineeIds: const [],
      status: 'planned',
      plannedStart: DateTime.now().toUtc().toIso8601String(),
      revision: 0,
    );
  }

  /// Loads the latest planned route and its ordered waypoints for an outing.
  Future<({PlannedRoute? route, List<RouteWaypoint> waypoints})>
  _loadRouteForOuting(String outingId) async {
    if (outingId.isEmpty) {
      return (route: null, waypoints: const <RouteWaypoint>[]);
    }
    // A tombstoned route is a route the user replaced: the latest live one is
    // the only one worth drawing, so the dead ones never shadow it.
    final routeRow =
        await (widget.database.select(widget.database.plannedRoutes)
              ..where(
                (t) =>
                    t.outingId.equals(outingId) & t.isTombstone.equals(false),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .getSingleOrNull();
    if (routeRow == null) {
      return (route: null, waypoints: const <RouteWaypoint>[]);
    }
    final waypoints =
        await (widget.database.select(widget.database.routeWaypoints)
              ..where(
                (t) =>
                    t.routeId.equals(routeRow.localId) &
                    t.isTombstone.equals(false),
              )
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
    await _routes.saveRoute(
      outingId: route.outingId,
      waypoints: waypoints,
      routeLocalId: route.localId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _selectedOutingId = route.outingId);
    unawaited(_rememberOuting(route.outingId));
    await _readRoute();
  }

  /// Deletes a pin's record: tombstones it and queues the deletion, then
  /// re-reads so the map draws it hollow rather than removing it. The record is
  /// not erased — rule 9 — because a deleted observation is still part of the
  /// trail of the day.
  Future<void> _deleteSighting(String localId) async {
    await _sightings.delete(localId);
    if (!mounted) {
      return;
    }
    await _read();
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

  /// Opens the observations logbook: every record on this phone, newest first.
  ///
  /// The map draws what is on the ground now; the logbook is the record of what
  /// has been seen and what happened to each row since — filed, corrected,
  /// verified, refused. Reopening a record takes the same screen the pin opens,
  /// with the same amendment and correction actions, so a trainee can revisit
  /// and edit anything from the list. When they come back, the list is re-read
  /// so it never shows a record the way it was before the reader changed it.
  Future<void> _openObservations() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ObservationsScreen(database: widget.database),
      ),
    );
  }

  /// Reads every record that still exists into the summaries the logbook lists.
  ///
  /// Deleted rows are dropped here so the logbook only ever speaks of records
  /// that are still real, which is the map's own rule for pins.
  Future<List<SightingSummary>> _observationSummaries() async {
    final rows = await (widget.database.select(
      widget.database.sightings,
    )..where((t) => t.isTombstone.equals(false))).get();
    return [for (final row in rows) _summaryOf(row)]
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  /// Files a sighting that was captured without an outing against an open
  /// drive.
  ///
  /// The service refuses a sighting without an outing, so the record has been
  /// safe on this phone but never queued. Filing it writes the outing id and
  /// queues the create in one transaction, and then the queue is offered the
  /// same chance to leave that any recorded sighting gets.
  Future<void> _fileSighting(String localId) async {
    final drives =
        await (widget.database.select(widget.database.drives)
              ..where((t) => t.endedAt.isNull())
              ..where((t) => t.isTombstone.equals(false)))
            .get();

    if (!mounted) {
      return;
    }

    // No open drive means nothing to file against. Saying so beats showing a
    // picker that can only come back empty: the record stays where it is, and
    // the booking is still offered from the pin.
    if (drives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a drive first, then file the record to it.'),
        ),
      );
      return;
    }

    final driveId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) =>
          _DrivePicker(drives: drives, colours: context.reserve),
    );
    if (driveId == null || !mounted) {
      return;
    }

    final filed = await _sightings.fileOne(localId, driveId);
    await _read();
    await _refreshQueued();
    if (_status.hasTransport) unawaited(_sync());
    if (filed == 0 || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Filed to the outing.')));
  }

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
    final amender = _amender;
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
    await _refreshQueued();
    // The amendment is a queued change like any other; when the radio is up
    // it should not wait for the next transport event to be offered.
    if (_status.hasTransport) unawaited(_sync());
  }

  SightingSummary _summaryOf(SightingRow row) {
    return SightingSummary(
      localId: row.localId,
      visual: pinVisualFor(row, commonNameFor: _nameOf),
      commonName: _nameOf(row.speciesCode ?? ''),
      scientificName: '',
      driveId: row.driveId,
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
    final writer = _sightings;
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
          isTrailWalk: _isTrailWalk,
          onOutingChanged: _setSelectedOuting,
          recentSpecies: recent,
          onReloadSpecies: () {
            final loader = ReferenceLoader(
              database: widget.database,
              api: widget.api,
              sessions: widget.sessions,
              renewSession: _refreshTokens,
            );
            return loader.load(forceRefresh: true);
          },
          onSpeciesUsed: (choice) {
            _recent?.note(choice);
          },
          onNavigate: () {
            // Pop the field card and center the map on the coordinate
            Navigator.of(context).pop();
            if (_currentPosition != null) {
              _mapKey.currentState?.fitCamera(
                CameraFit.coordinates(
                  coordinates: [_currentPosition!],
                  padding: const EdgeInsets.all(20),
                ),
              );
            }
          },
          onSave: (draft) async {
            final writer = _sightings;
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
      key: _mapKey,
      pins: _pins,
      queuedCount: _queued,
      // The basemap decides the palette, not the other way round. A loaded
      // MapTiler basemap is a light, real-world map, so the chrome and the
      // reserve's symbols take the sunlight palette to stay readable on it.
      // Offline — or on the OSM fallback — the ground is the dark reserve
      // painting, so the chrome goes dark again.
      colours: maptilerEnabled && _status.hasTransport
          ? FieldColours.sunlight
          : FieldColours.dark,
      online: _status.hasTransport,
      signedInAs: _user?.shortName,
      onTapSignedInAs: _user == null ? _openSignIn : null,
      onOpenSettings: _openSettings,
      tileCache: widget.tileCache,
      gps: _gps,
      currentPosition: _currentPosition,
      route: _route,
      routeWaypoints: _routeWaypoints,
      progress: _progress,
      // The live indicator: present only while a drive or walk is running,
      // and the thing its Stop action clears. Null hides the card outright.
      activeOuting: _activeOutingId == null
          ? null
          : ActiveOuting(
              label: _activeOutingLabel,
              kind: _activeOutingKind,
              startedAt: _activeOutingStartedAt!,
              onStop: _stopActiveOuting,
            ),
      // The bar's context line, derived from real state: what is running, else
      // the reserve context the records are written into.
      subtitle: _activeOutingLabel.isNotEmpty
          ? _activeOutingLabel
          : _contextCode,
      onMapTap: _captureAt,
      onDropPin: _captureAt,
      onOpenLedger: _openLedger,
      onOpenTally: _openTally,
      onOpenDrive: _openDrive,
      onOpenTrail: _openTrail,
      onOpenSighting: _openSighting,
      onDeleteSighting: _deleteSighting,
      onOpenObservations: _openObservations,
      onRecordSighting: _recordSighting,
      syncing: _syncing,
      lastSyncedAt: _lastSyncedAt,
      syncError: _syncError,
      mapStylePreset: widget.currentMapStylePreset,
      onMapStylePresetChanged: widget.onMapStylePresetChanged,
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

/// The open drives a recorded-but-unfiled sighting can be filed against.
///
/// A bottom sheet, because the record's reader was already looking at the
/// record; the drive is a choice made in passing, not a journey of its own.
/// Each row names the drive by when it started, which is the only label an
/// outings log keeps that a reader can count on.
class _DrivePicker extends StatelessWidget {
  const _DrivePicker({required this.drives, required this.colours});

  final List<DriveRow> drives;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.md,
          Insets.lg,
          Insets.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File to an outing',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.cardTitle,
                fontWeight: FontWeight.w600,
                color: colours.bone,
              ),
            ),
            const SizedBox(height: Insets.sm),
            Text(
              'The record only leaves this phone once it is filed.',
              style: TextStyle(
                fontFamily: Faces.book.first,
                fontSize: Faces.supporting,
                height: 1.4,
                color: colours.ash2,
              ),
            ),
            const SizedBox(height: Insets.md),
            ...drives.map(
              (drive) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(drive.localId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colours.bone,
                    side: BorderSide(color: colours.ruleStrong),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.md,
                      vertical: Insets.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Corners.control),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 18,
                          color: colours.bone,
                        ),
                        const SizedBox(width: Insets.sm),
                        Text(
                          _driveLabel(drive),
                          style: TextStyle(
                            fontFamily: Faces.ui.first,
                            fontSize: Faces.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A drive by the local clock, the way the logbooks name them.
  static String _driveLabel(DriveRow drive) {
    final local = drive.startedAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return 'Drive — $day/$month at $hour:$minute';
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
