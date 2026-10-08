# Field log architecture

This document describes how the `field_log` mobile app is built and why. It
complements [../README.md](../README.md): the README is the guided tour of the
codebase; this is the reasoning underneath it. The interaction design lives in
`chisimba-info/docs/mobile-design/README.md`, and the authoritative
specification for the service this client talks to is
`framework/docs/architecture/field-guiding-service-contract.md`.

## The one decision that shapes everything else

The client is **local-first**. The device holds the records; the field
guiding service is a replica that the client reconciles with, not the other
way round. A reserve with no signal is the normal case, and an app whose
primary data lives on a server has no answer for it. Every consequent
decision — Drift as the replica of record, the durable outbox, the atomic
pull page — exists to protect that property.

The corollary is that *readiness never blocks*: the map, the card and the
ledger work with no network and no session, because the trainee is standing
in a vehicle, possibly out of coverage, and the record is the point.

## Data layer (`lib/data/`)

Drift (SQLite) is the store. `lib/data/tables.dart` declares one table per
record kind, and the migrations in `database.dart` carry the reasoning for
each shape. Two tables deserve their note here:

- `operation_queue` is a durable outbox keyed by **operation id, never by
  entity id**. Contract rule 7 makes the operation id the retry identity;
  keying by entity would collapse a drive's `start` and the `create` of
  that drive into one row and silently drop one.
- `conflicts` holds refusals with the submitted and current values side by
  side, so a refusal is data a person can act on rather than a log line.

`mappers.dart` converts row ↔ wire in both directions and is the only place
that knows both shapes.

## The two engines

**`PushEngine`** sends a bounded batch through an injected `send` callback,
records every outcome from the service's partial-success response, and keeps
refusals in `conflicts`. Invariants the tests pin down:

- a refusal ⇒ a settled row *and* a conflict row;
- a deferral ⇒ still pending, payload untouched;
- a refusal is settled, never re-queued — retrying a well-formed refusal
  retries every refusal on every push forever.

**`PullEngine.applyPage`** applies a page and advances the cursor inside a
single transaction. Two separate writes leave a window where a crash keeps
the cursor and loses the page, so the client quietly stops being told about
changes it has never seen. `test/data/pull_engine_test.dart` proves this by
dropping the cursor table and asserting that no sighting survives. A
`resync_required` status from the service is handled as a normal path, not
an error: the client owns what a resync means for its local data, because
only it knows what it holds.

Both engines are currently tested against fixtures that return whatever the
test tells them to (`test/fixtures/`). That is a recorded limit: an engine
can be correct against the contract's wording and still be wrong against the
service that eventually ships.

## Trail log and amendments

A trail log is append-only by structure: `trail_log_writer.dart` records a
path and there is no update path. Corrections are another row. The same
append-only discipline applies to sighting amendments
(`sighting_amendments.dart`): the amendment and its queue entry are written
together, so a record and its evidence for syncing it never disagree.

## Net (`lib/net/`)

- `chisimba_api.dart` — sign-in evidence fetch, sign-in, who-am-I, sign-out,
  **species catalogue, competency catalogue, sync push, sync pull**.
  Loop paths are `$baseUrl/api/v1/...`, so `baseUrl` is the service origin.
- `connectivity_watcher.dart` — transport, which is not reachability; the
  difference is deliberate, because a device can be "connected" to a network
  with no path to the reserve office.
- `session_store.dart` — the two credential strings, and nothing else, in a
  `session.json` chmod 600 **outside** the Drift database, because that
  database is the logbook and credentials belong in neither its export nor
  its conflict UI.

## Map (`lib/map/`)

`flutter_map` with an OSM raster layer over the vector layer. The tile cache
is evicted by age; anything not cached falls back to the vector layer, so the
map is never blank in the field — the one situation the design cares most
about. GPS and the map centre are placeholders (recorded below).

## Design tokens

`lib/design/tokens.dart` transcribes the token table from
`chisimba-info/docs/mobile-design/README.md`, and
`test/design/tokens_test.dart` fails if the code and the design document
drift apart. Where the design gives a value by derivation, the derivation is
in the doc comment so it can be re-derived rather than trusted. Accents are
fills, not text: status is carried by a stamp and its label. `FieldColours`
never uses dust as running text: dust cannot carry body text on its own fill.

## State management

`flutter_riverpod` is declared but deliberately unused at runtime (see the
comment at `main.dart`): the wiring is manual and small, and a container
would add indirection without buying testability the constructor injection
already provides.

## Sync integration (`lib/main.dart`)

A periodic sync loop runs every 5 minutes when the device has transport:

```dart
void _startSyncLoop() {
  _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
    if (!mounted || !_status.hasTransport || _user == null) return;
    await _syncOnce();
  });
}

Future<void> _syncOnce() async {
  // Pull changes since last cursor for the user's active scope
  final scope = _user!.grants?.first ?? 'field:write';
  final cursor = await widget.pullEngine.cursorFor(scope);
  final pullRequest = chisimba.PullRequest(cursor: cursor ?? '');
  final pullResponse = await widget.api.pull(stored.accessToken, pullRequest);

  final outcome = await widget.pullEngine.applyPage(
    scope: scope,
    page: pullResponse.toPage(),
  );

  if (outcome.resyncRequired) {
    await widget.pullEngine.forgetCursors();
    return;
  }

  // Push queued operations
  if (_status.hasTransport) {
    await widget.pushEngine.push(
      send: (batch) async {
        final request = chisimba.PushRequest(
          operations: batch.map(_toWireOp).toList(),
        );
        final response = await widget.api.push(stored.accessToken, request);
        return response.results.map(_fromWireResult).toList();
      },
    );
  }
}
```

The cursor is stored per-scope (grant) so a user with multiple grants tracks each separately. `resync_required` from the service triggers a full re-pull by clearing cursors.

## Tally integration (`lib/screens/tally_screen.dart`)

The tally screen now reads from the local database and computes real trail progress:

```dart
Future<void> _loadProgress() async {
  final trailLogs = await widget.database!.select(widget.database!.trailLogs).get();
  final hoursByRole = <String, double>{};
  
  for (final log in trailLogs) {
    final points = await widget.database!.select(widget.database!.trailWaypoints)
      ..where((t) => t.trailLogId.equals(log.localId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordinal)])
      .get();
    
    if (points.length >= 2) {
      double hours = 0.0;
      for (int i = 1; i < points.length; i++) {
        hours += points[i].recordedAt.difference(points[i - 1].recordedAt).inSeconds / 3600.0;
      }
      hoursByRole['none'] = (hoursByRole['none'] ?? 0.0) + hours;
    }
  }
}
```

Hours are kept apart by rifle role (`first`, `second`, `none`) as the contract requires. Requirements are still empty — the mentor decides readiness.

## Outing selection (`lib/field/field_card_screen.dart`)

The field card now fetches outings from `/api/v1/outings` and presents a dropdown selector:

```dart
// In _recordSighting:
final outingList = await widget.api.getOutings(stored.accessToken);
outings = outingList.outings;

// Passed to FieldCardScreen:
FieldCardScreen(
  outings: outings,
  selectedOutingId: _selectedOutingId,
  onOutingChanged: (id) => setState(() => _selectedOutingId = id),
  // ...
)

// In _saveSighting:
final driveId = _selectedOutingId ?? const Uuid().v4();
```

The field-service exposes `GET /api/v1/outings` returning outings scoped to the caller's context grants. The mobile app fetches them when online and caches them for the session.

## GPS integration (`lib/main.dart`)

Real GPS positioning via `geolocator` replaces the epoch placeholder:

```dart
void _startGpsStream() {
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );
  _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) {
    setState(() {
      _gps = GpsReading(
        accuracyMetres: position.accuracy,
        satellites: 0,
        fixedAt: position.timestamp.toUtc(),
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  });
}
```

The stream updates every 5 metres with high accuracy. The `GpsReading` now includes latitude/longitude and real timestamps. The map screen and field card receive live GPS data for accuracy display and sighting capture.

## Known gaps (verified against the code)

- **Auth base-URL mismatch.** `main.dart` defaults `CHISIMBA_API` to
  `http://10.0.2.2:8080` (fixed from `.../api/v1`) while `ChisimbaApi` builds
  paths as `$baseUrl/api/v1/auth/...`. Fixed: the default now omits the version
  segment so the default works without override.
- **Field card save is a no-op.** `main.dart` wires
  `onSave: (draft) async {}` and passes `species: const []`; captured
  sightings persist nothing and no queue entry is made.
- **Ledger and tally are hardwired empty.** `SyncLedgerScreen` is pushed with
  `entries: [], online: false`, `TallyScreen` with `TrailProgress.empty`;
  neither reads the queue or the trail log.
- **Reference data never fetched.** The field card gets `species: const []`
  and empty behaviour/age-sex-class lists; `_nameOf` returns the raw code.
- **Positions are placeholders.** Fixed reserve centre, an epoch-timestamped
  GPS bar (an obviously wrong time is better than a plausible one), pin tap
  opens rather than dropping.
- **Model values provisional.** `behaviour` and `age_sex_class` are stored as
  free text until the contract enumerates them; otherwise a wrong enum guess
  would need a migration to correct.
- **No token refresh.** Sign-out clears the token, but there is no refresh
  flow; a device offline longer than the access-token lifetime must sign in
  again.
- **Dependency cycles/dangling `dependsOn`** stay pending forever with no
  explanation in the ledger. Detecting them needs a queue distinction that
  does not exist yet: whether a dependency is an error or merely not written
  *yet*.