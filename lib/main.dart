import 'package:field_log/data/database.dart';
import 'package:field_log/data/mappers.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:field_log/map/tile_cache.dart';
import 'package:field_log/screens/map_screen.dart';
import 'package:field_log/screens/pin_detail.dart';
import 'package:field_log/screens/sync_ledger.dart';
import 'package:field_log/screens/tally_screen.dart';
import 'package:field_log/field/field_card_screen.dart';
import 'package:field_log/field/card_state.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The store is opened before the first frame rather than lazily. A field log
  // that shows an empty map because the database has not opened yet would look
  // exactly like a device that has lost every record, and the design gives no
  // way to tell those apart.
  final database = FieldLogDatabase.open();
  final tileCache = await TileCache.forDevice();
  runApp(FieldLogApp(database: database, tileCache: tileCache));
}

/// The application root.
///
/// Dark first, and this is a field decision: the work happens at first light
/// and a white screen at 05:40 blinds.
class FieldLogApp extends StatelessWidget {
  const FieldLogApp({super.key, required this.database, this.tileCache});

  final FieldLogDatabase database;

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
      home: FieldLogHome(database: database, tileCache: tileCache),
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
  const FieldLogHome({super.key, required this.database, this.tileCache});

  final FieldLogDatabase database;
  final TileCache? tileCache;

  @override
  State<FieldLogHome> createState() => _FieldLogHomeState();
}

class _FieldLogHomeState extends State<FieldLogHome> {
  List<MapPin> _pins = const [];
  final int _queued = 0;

  @override
  void initState() {
    super.initState();
    _read();
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
        builder: (_) => PinDetailScreen(sighting: _summaryOf(row)),
      ),
    );
  }

  /// Builds what the detail screen shows from a stored row.
  ///
  /// Deliberately mechanical. The screen asks for plain values so it can be
  /// built without a database, and the translation belongs in one place here
  /// rather than spread across whichever screen happens to read the row.
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
    return MapScreen(
      pins: _pins,
      queuedCount: _queued,
      colours: FieldColours.dark,
      online: false,
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
  }
}
