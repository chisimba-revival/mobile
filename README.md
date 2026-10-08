# Field log

The offline client for the Chisimba field guiding service. A trainee records
wildlife sightings on a drive, out of coverage, in a moving vehicle.

This repository is separate from `framework/` and `modules/`. It has its own
history, and the PHP tree does not carry it.

## What this is

The client is **local-first**. The device holds the records; the field guiding
service is a replica that the client reconciles with, not the other way round.
That is not a preference: an app whose primary data lives on a server has no
answer for a reserve with no signal, which is the normal case.

The authoritative specification is
[`framework/docs/architecture/field-guiding-service-contract.md`](../framework/docs/architecture/field-guiding-service-contract.md).
The interaction design is
[`chisimba-info/docs/mobile-design/README.md`](../chisimba-info/docs/mobile-design/README.md),
and `chisimba-info/docs/mobile-design/field-log.html` is the interactive
prototype. The toolchain is documented in
`chisimba-info/docs/mobile-design/TOOLCHAIN.md`.

Where this code and the contract disagree, the contract is wrong here, and the
disagreement is recorded in the code that depends on it.

The reasoning under the structure described below is in
[docs/architecture.md](docs/architecture.md).

## Current state

Screens, local store, sync engines and real service contact. Every screen
exists and is tested; the app runs and mounts the map. It talks to a live
Chisimba for sign-in, **fetches species/competencies, pulls changes and pushes
queued operations** on a 5-minute interval when online.

```
lib/design/tokens.dart     the reserve vocabulary, transcribed from the design
lib/design/theme.dart      Material behaviour, colour from the tokens
lib/models/geo_point.dart  an immutable WGS84 point and its GeoJSON form
lib/models/sighting.dart   the logbook sighting, and rule 21
lib/models/sync_operation.dart  queued changes and push results

lib/data/tables.dart       the store, and why each table is shaped as it is
lib/data/trail_log_tables.dart  waypoints, which are append-only
lib/data/database.dart     the Drift database and its migrations
lib/data/mappers.dart      row <-> wire, in both directions
lib/data/operation_queue.dart  the durable outbox
lib/data/pull_engine.dart  apply a page and move the cursor atomically
lib/data/push_engine.dart  send a bounded batch and record every outcome
lib/data/trail_log_writer.dart  record a path, and never edit one
lib/data/sighting_amendments.dart  add to a record and queue it, together

lib/net/chisimba_api.dart  sign-in, who am I, sign out, species, competencies, sync push, sync pull
lib/net/connectivity_watcher.dart  transport, which is not reachability
lib/net/session_store.dart the two credential strings, and nothing else

lib/map/tile_cache.dart    tiles on disk, evicted by age
lib/map/osm_tiles.dart    OpenStreetMap tiles that may simply be absent
lib/map/pin_visual.dart    what a pin says, and the rules behind it
lib/map/pin_painter.dart   the notched field-card tab

lib/field/card_state.dart  what a card may be saved as, and why
lib/field/field_card_screen.dart  the card, in both of its modes

lib/screens/map_screen.dart  the ground and the observations on it
lib/screens/pin_detail.dart   one record, opened on what it is
lib/screens/sync_ledger.dart  what is waiting to upload
lib/screens/tally_screen.dart   hours kept apart, and what is outstanding
lib/screens/sign_in_screen.dart  signing in, and being told what happened
```

Screens take plain values rather than rows or services, so each one is built and
tested with no database and no network.

Run it:

```sh
flutter pub get
dart run build_runner build     # regenerates the *.freezed.dart and *.g.dart
dart analyze
flutter test
```

The data tests need `libsqlite3.so` on the host, which on Debian and Ubuntu comes
from `libsqlite3-dev`. Without it the Drift tests fail to load the library rather
than failing an assertion.

## Four decisions worth knowing before reading the code

**`abstract class`, not `class`, on every generated model.** freezed 3 and 4
generate a mixin whose members are abstract, so a plain `class` declaration
fails to compile with `non_abstract_class_inherits_abstract_member`. This is
mandatory, not a style choice, and the contract's example model had it wrong
until it was corrected on 2026-10-04.

**A sighting may have no species and no count.** Contract rule 21 makes
`species_code` and `count` required only when `status` is `verified`. A trainee
who saw something and could not name it records a sighting with neither, and a
mentor may still verify it *as observed*: the claim confirmed is that something
was there, not what it was. An absent count is not a zero, for the same reason
contract rule 18 keeps `not_observed` from being a zero.

**The queue is keyed by operation id, never by entity id.** Contract rule 7
makes the operation id the retry identity. A queue keyed by entity would collapse
a drive's `start` and the `create` of that drive into one row and silently drop
one of them, which is the kind of loss that is only noticed after the season.

**A page and its cursor are one unit of work.** `PullEngine.applyPage` applies
every change and writes the cursor inside a single transaction. Two separate
writes leave a window where a crash keeps the cursor and loses the page, so the
client quietly stops being told about changes it has never seen.
`test/data/pull_engine_test.dart` proves this by dropping the cursor table and
asserting that no sighting survives.

**A refusal is settled, a deferral is not.** These look alike and are not. A
deferral means a declared prerequisite has not settled, so the same bytes are
sent again later. A refusal means the service declined a well-formed request, so
an identical retry is declined identically and re-queueing it would retry every
refusal on every push forever. The refusal itself is kept, with the submitted and
current values side by side, in the `conflicts` table for a person to act on.
Note that `PushOutcome.isTerminal` is false for a refusal and that is not a
contradiction: `isTerminal` asks whether anything more will happen without a
person, and a refusal genuinely needs one.

## Tokens

Values are transcribed from the design's token table and locked by
`test/design/tokens_test.dart`, which fails if the code and the design document
drift apart. Where the design gives a value by derivation rather than as a
literal, the derivation is in the doc comment so it can be re-derived instead of
trusted:

- `ash1`..`ash4` are bone over canopy at 85, 65, 45 and 28 per cent.
- `ruleFaint`/`rule`/`ruleStrong` are bone over canopy at 9, 16 and 30 per cent.

**Accents are fills, not text.** Holding an accent hue across both brightnesses
is the design's stated rule, and it holds for surfaces and ink. It does not
hold for an accent used as running text: straw and moss sit close to the bone
lightness and fall to 1.89:1 and 2.49:1 on the light surface in midday. So
status is carried by a stamp and its label, never by coloured text, and
`FieldColours.inkOn` chooses a legible label colour by measurement. Dust is the
one accent that cannot carry body text on its own fill, at 4.17:1.

## Open

`behaviour` and `age_sex_class` are declared as enums by the contract but their
values are not enumerated anywhere in it. The values in
`lib/models/sighting.dart` are provisional and must be reconciled with the
service, or a behaviour tally will silently under-count. The columns are
therefore stored as free text rather than as enum-typed columns: encoding a
guess in the schema would make the client reject a value the service might
legitimately send, and when the contract settles the lists only the model layer
changes and no migration is needed.

Sign-in works against a live Chisimba, and that part was verified by hand
rather than read off the documentation: the evidence request is a `GET` with no
body, the credentials are posted flat rather than nested, and an access token
sent as an `X-API-Key` is refused with a 401. Two of those would have compiled
happily and failed at runtime.

**Sync engines are now wired to the real service** — `ChisimbaApi` implements
`getSpecies`, `getCompetencies`, `push`, `pull`, and `main.dart` runs a
periodic pull+push every 5 minutes when online. The push/pull engines have been
tested against fixtures; live integration is the next verification step.

**GPS positioning is live** — `geolocator` provides a position stream updating
every 5 metres with high accuracy. The `GpsReading` now includes real
latitude/longitude, accuracy, satellite count, and timestamps. The GPS bar and
field card use live data; pins are still dropped at fixed coordinates.

**Reference data now fetched** — `_recordSighting` fetches species from
`/api/v1/species` and competencies from `/api/v1/competencies` when online.
The field card shows real species choices and behaviour/age-sex-class chips.

**SyncLedgerScreen reads real queue** — `OperationQueue` data displayed with
pending/inflight/settled states and attempt counts.

**TallyScreen reads real trail logs** — Hours computed from waypoint timestamps,
kept apart by rifle role (`first`, `second`, `none`).

No token refresh flow. Sign-out clears the token, but there is no refresh
flow; a device offline longer than the access-token lifetime must sign in
again.

An operation whose `dependsOn` names an operation that was never queued, or that
names a cycle, stays pending forever and is never sent. Nothing detects this, so
it appears in the ledger as an ordinary pending change with no explanation. This
is not fixed because the obvious repair is worse than the fault: a dependency
that has not been written *yet* is normal, since the drive a sighting belongs to
may be started on another screen later, so anything that treats an absent
dependency as an error will produce false alarms and hold valid work. Detecting
this properly needs a distinction the queue does not currently record — whether
the dependency is expected to arrive at all.