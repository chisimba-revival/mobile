import 'dart:io';

import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/data/sighting_amendments.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/net/chisimba_api.dart';
import 'package:field_log/net/connectivity_watcher.dart';
import 'package:field_log/net/session_store.dart';
import 'package:field_log/map/tile_cache.dart';
import 'package:field_log/screens/map_screen.dart';
import 'package:field_log/screens/sign_in_screen.dart';
import 'package:field_log/screens/pin_detail.dart';
import 'package:field_log/screens/sync_ledger.dart';
import 'package:field_log/screens/tally_screen.dart';
import 'package:field_log/field/field_card_screen.dart';
import 'package:field_log/field/card_state.dart';

import 'dart:async';

import 'package:flutter/material.dart';
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
/// and a white screen at 05:40 blinds.
class FieldLogApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field log',
      debugShowCheckedModeBanner: false,
      theme: fieldTheme(FieldColours.dark),
      darkTheme: fieldTheme(FieldColours.dark),
      home: FieldLogHome(
        database: database,
        tileCache: tileCache,
        api: api,
        sessions: sessions,
        connectivity: connectivity,
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
    this.tileCache,
  });

  final FieldLogDatabase database;
  final ChisimbaApi api;
  final SessionStore sessions;
  final ConnectivityWatcher connectivity;
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

  @override
  void initState() {
    super.initState();
    _read();
    _restore();
    _watchTransport();
  }

  @override
  void dispose() {
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

  Future<void> _recordSighting() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FieldCardScreen(
          initial: const FieldDraft(mode: CaptureMode.identified),
          species: const [],
          reference: const ReferenceValues(behaviours: [], ageSexClasses: []),
          onSave: (draft) async {},
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
      tileCache: widget.tileCache,
      // Placeholder until a positioning source is wired. Reporting a fix that
      // has not happened would put a time in the record that never occurred, so
      // this is the epoch rather than now: an obviously wrong time is better
      // than a plausible wrong one.
      gps: GpsReading(
        accuracyMetres: 0,
        satellites: 0,
        fixedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
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
        builder: (_) => SignInScreen(onSignIn: _signIn, initialServer: widget.api.baseUrl, onSaveServer: _saveServer),
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
