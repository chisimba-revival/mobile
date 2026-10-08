import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../models/geo_point.dart';
import '../models/sighting.dart';
import '../models/sync_operation.dart';
import 'database.dart';

/// Conversions between the stored rows and the contract's models.
///
/// The one place the storage shape and the wire shape are allowed to differ is
/// here. `location` is two columns in the database and a GeoJSON `Point`
/// everywhere else; [sightingToState] and [sightingFromState] are the only
/// functions that know it.
extension SightingRowMapping on SightingRow {
  WildlifeSighting toModel() {
    return WildlifeSighting(
      id: localId,
      contextCode: contextCode,
      driveId: driveId,
      status: status,
      location: GeoPoint(longitude: locationLng, latitude: locationLat),
      capturedAt: capturedAt,
      recordedAt: recordedAt,
      revision: revision,
      createdBy: createdBy,
      speciesCode: speciesCode,
      count: count,
      locationAccuracyM: locationAccuracyM,
      distanceM: distanceM,
      bearingDeg: bearingDeg,
      behaviour: behaviour == null ? null : behaviourByWire(behaviour!),
      ageSexClass: ageSexClass == null ? null : ageSexByWire(ageSexClass!),
      notes: notes,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      verificationNotes: verificationNotes,
      recordedSpeciesCode: recordedSpeciesCode,
      recordedCount: recordedCount,
      lateArrival: lateArrival,
    );
  }
}

/// The contract's wire form for a sighting, ready to be sent or stored as an
/// operation payload.
Map<String, dynamic> sightingToState(WildlifeSighting s) {
  return <String, dynamic>{
    'id': s.id,
    'context_code': s.contextCode,
    'drive_id': s.driveId,
    'status': _wireValue(s.status),
    'location': s.location.toGeoJson(),
    'captured_at': s.capturedAt.toUtc().toIso8601String(),
    'recorded_at': s.recordedAt.toUtc().toIso8601String(),
    'revision': s.revision,
    'created_by': s.createdBy,
    if (s.speciesCode != null) 'species_code': s.speciesCode,
    if (s.count != null) 'count': s.count,
    if (s.locationAccuracyM != null) 'location_accuracy_m': s.locationAccuracyM,
    if (s.distanceM != null) 'distance_m': s.distanceM,
    if (s.bearingDeg != null) 'bearing_deg': s.bearingDeg,
    if (s.behaviour != null) 'behaviour': _wireValue(s.behaviour!),
    if (s.ageSexClass != null) 'age_sex_class': _wireValue(s.ageSexClass!),
    if (s.notes != null) 'notes': s.notes,
    if (s.verifiedBy != null) 'verified_by': s.verifiedBy,
    if (s.verifiedAt != null)
      'verified_at': s.verifiedAt!.toUtc().toIso8601String(),
    if (s.verificationNotes != null) 'verification_notes': s.verificationNotes,
    if (s.recordedSpeciesCode != null)
      'recorded_species_code': s.recordedSpeciesCode,
    if (s.recordedCount != null) 'recorded_count': s.recordedCount,
    if (s.lateArrival) 'late_arrival': true,
  };
}

/// The contract's wire form for a drive outing.
///
/// Sparse on purpose. The service's update applies only the keys it receives,
/// so an absent field means "leave this alone" rather than "clear it", and a
/// null column is omitted for the same reason. [driveToState] is what a queued
/// create or update carries; the columns it does not name stay as they are.
Map<String, dynamic> driveToState(DriveRow d) {
  return <String, dynamic>{
    'outing_kind': 'drive',
    'status': d.status ?? 'planned',
    'start_time': d.startedAt.toUtc().toIso8601String(),
    if (d.endedAt != null) 'end_time': d.endedAt!.toUtc().toIso8601String(),
    if (d.guideId != null) 'guide_id': d.guideId,
    if (d.weather != null) 'weather': d.weather,
    if (d.notes != null) 'notes': d.notes,
    if (d.durationHours != null) 'duration_hours': d.durationHours,
    if (d.guestCount != null) 'guest_count': d.guestCount,
    if (d.vehicleId != null) 'vehicle_id': d.vehicleId,
    if (d.inspectionOilOk != null) 'inspection_oil_ok': d.inspectionOilOk,
    if (d.inspectionWaterOk != null) 'inspection_water_ok': d.inspectionWaterOk,
    if (d.inspectionTyresOk != null) 'inspection_tyres_ok': d.inspectionTyresOk,
    if (d.daylightHours != null) 'daylight_hours': d.daylightHours,
    if (d.nightHours != null) 'night_hours': d.nightHours,
    if (d.offRoadSeconds != null) 'off_road_seconds': d.offRoadSeconds,
    if (d.offTrackUsed != null) 'off_track_used': d.offTrackUsed,
  };
}

/// The contract's wire form for a hike outing.
///
/// [TrailLogRow.trailCode] and [TrailLogRow.driveId] are deliberately absent:
/// the service's outing has no such columns, and sending keys it does not
/// read would pretend an agreement the contract does not make. Trail names
/// stay on this device.
Map<String, dynamic> hikeToState(TrailLogRow t) {
  return <String, dynamic>{
    'outing_kind': 'hike',
    'status': t.status ?? 'planned',
    'start_time': t.startedAt.toUtc().toIso8601String(),
    if (t.endedAt != null) 'end_time': t.endedAt!.toUtc().toIso8601String(),
    if (t.notes != null) 'notes': t.notes,
    if (t.weather != null) 'weather': t.weather,
    if (t.rifleRole != null) 'rifle_role': t.rifleRole,
    if (t.walkLengthKm != null) 'walk_length_km': t.walkLengthKm,
    if (t.hoursWalked != null) 'hours_walked': t.hoursWalked,
    if (t.description != null) 'description': t.description,
    if (t.lessonsLearned != null) 'lessons_learned': t.lessonsLearned,
    if (t.guideRole != null) 'guide_role': t.guideRole,
    if (t.rifleDetails != null) 'rifle_details': t.rifleDetails,
  };
}

/// The contract's wire form for a dangerous-game encounter.
///
/// [DangerousGameEncounterRow.accuracyM] is absent because the service's
/// table has no accuracy column: sending it would ask for a field that does
/// not exist, and the device keeps its own accuracy without pretending the
/// service shares it.
Map<String, dynamic> encounterToState(DangerousGameEncounterRow e) {
  return <String, dynamic>{
    'outing_id': e.outingId,
    'species_code': e.speciesCode,
    'longitude': e.longitude,
    'latitude': e.latitude,
    'captured_at': e.capturedAt.toUtc().toIso8601String(),
    if (e.distanceM != null) 'distance_m': e.distanceM,
    if (e.animalBehaviour != null) 'animal_behaviour': e.animalBehaviour,
    if (e.actionTaken != null) 'action_taken': e.actionTaken,
    if (e.note != null) 'note': e.note,
  };
}

/// The wire name of an enum value.
///
/// Dispatched by type rather than by reflection over the generated codecs: the
/// codec is a private `_$XToJson` function inside a part file, so there is
/// nothing to call at runtime, and an indirection that cannot be checked is
/// worse than an explicit list. Every arm below matches the `@JsonValue` on the
/// corresponding enum, and the wire round-trip test is what holds them together.
String _wireValue(Object value) => switch (value) {
  SightingStatus v => statusWireName(v),
  SightingBehaviour v => behaviourWireName(v),
  AgeSexClass v => ageSexWireName(v),
  EntityKind v => wireEntityFor(v),
  OperationKind v => _operationWireName(v),
  PushOutcome v => _outcomeWireName(v),
  _ => value.toString(),
};

String statusWireName(SightingStatus v) => switch (v) {
  SightingStatus.pending => 'pending',
  SightingStatus.verified => 'verified',
  SightingStatus.rejected => 'rejected',
  SightingStatus.needsReview => 'needs_review',
};

String behaviourWireName(SightingBehaviour v) => switch (v) {
  SightingBehaviour.grazing => 'grazing',
  SightingBehaviour.moving => 'moving',
  SightingBehaviour.resting => 'resting',
  SightingBehaviour.feeding => 'feeding',
  SightingBehaviour.withYoung => 'with_young',
  SightingBehaviour.alert => 'alert',
  SightingBehaviour.unknown => 'unknown',
};

String ageSexWireName(AgeSexClass v) => switch (v) {
  AgeSexClass.female => 'female',
  AgeSexClass.male => 'male',
  AgeSexClass.juvenile => 'juvenile',
  AgeSexClass.adultUnknown => 'adult_unknown',
  AgeSexClass.unknown => 'unknown',
};

/// The wire name for an entity kind, as the service names it.
///
/// The queue stores local table names (a drive, a trail log) while the service
/// speaks its own four (`outing`, `log_book_entry`, `dangerous_game_encounter`,
/// `trail_waypoint`), so this is a translation rather than a rename: a queued
/// drive and a queued trail log are both an `outing` out there, and a queued
/// sighting is a `log_book_entry`.
String wireEntityFor(EntityKind v) => switch (v) {
  EntityKind.drive || EntityKind.trailLog || EntityKind.outing => 'outing',
  EntityKind.sighting => 'log_book_entry',
  EntityKind.dangerousGame => 'dangerous_game_encounter',
  EntityKind.trailWaypoint => 'trail_waypoint',
  EntityKind.signOff => 'sign_off',
  EntityKind.media => 'media',
  EntityKind.unknown => 'unknown',
};

/// The local entity kind a wire type means, or null when the wire type is not
/// understood.
///
/// Null rather than a guess: a change the client cannot name is held as
/// [EntityKind.unknown] and shown as such, because a pull that mapped an
/// unknown type onto a sighting would write somebody else's row into the
/// trainee's own log and do it silently.
EntityKind? entityFromWire(String wireType) => switch (wireType) {
  'outing' => EntityKind.outing,
  'log_book_entry' => EntityKind.sighting,
  'dangerous_game_encounter' => EntityKind.dangerousGame,
  'trail_waypoint' => EntityKind.trailWaypoint,
  // Earlier feeds named these after the local tables, and a client that has
  // been offline since before the rename will still meet them.
  'drive' => EntityKind.drive,
  'trail_log' => EntityKind.trailLog,
  'sighting' => EntityKind.sighting,
  'sign_off' => EntityKind.signOff,
  'media' => EntityKind.media,
  _ => null,
};

String _operationWireName(OperationKind v) => switch (v) {
  OperationKind.create => 'create',
  OperationKind.update => 'update',
  OperationKind.delete => 'delete',
  OperationKind.start => 'start',
  OperationKind.end => 'end',
  OperationKind.verify => 'verify',
};

String _outcomeWireName(PushOutcome v) => switch (v) {
  PushOutcome.applied => 'applied',
  PushOutcome.noop => 'noop',
  PushOutcome.deferred => 'deferred',
  PushOutcome.refused => 'refused',
};

/// Encode an operation payload for storage.
/// The storage patch for one sighting as it arrived from the change feed.
///
/// A patch rather than a whole row, deliberately. Rule 21 says `species_code` and
/// `count` may legitimately be absent, and a change feed entry is not obliged to
/// repeat fields that did not change. Building a complete row would force this
/// function to invent a value for anything the feed omitted, and an invented
/// `species_code` is a species nobody observed.
///
/// Three states are distinguished, which is the reason for the map below:
///
///   * key absent from the feed -> the column is not written at all, so a sparse
///     page cannot blank something the client already holds;
///   * key present and non-null -> written;
///   * key present and null -> written as NULL, because a correction that clears
///     a field is a real event and rule 15 requires it to be recorded rather than
///     silently ignored.
///
/// `location` is the one field that is not a plain column. The wire form is a
/// GeoJSON `Point` whose coordinates are [longitude, latitude], in that order,
/// which is the reverse of how anyone reads a pair of coordinates and the sort of
/// thing that quietly puts a sighting in the ocean.
SightingsCompanion sightingPatchFromState(
  Map<String, dynamic> state, {
  required String fallbackLocalId,
}) {
  final writes = <String, Value<Object?>>{};

  // Only records a column when the feed carried the key at all. See the three
  // states above; the middle and third are deliberately not merged.
  void put(String column, String key, Object? Function(Object? raw) parse) {
    if (state.containsKey(key)) {
      writes[column] = Value<Object?>(parse(state[key]));
    }
  }

  Value<T> take<T>(String column) {
    final value = writes[column];
    if (value == null) {
      return const Value.absent();
    }
    return Value<T>(value.value as T);
  }

  String? asString(Object? raw) => raw is String ? raw : null;

  int? asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  double? asDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  DateTime? asMoment(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    return null;
  }

  put('server_id', 'server_id', asString);
  put('context_code', 'context_code', asString);
  put('drive_id', 'drive_id', asString);
  // The service renamed the table's column from drive_id to outing_id and
  // feed bodies use the new name; a body may carry either, and the second
  // write lets the newer name win when a transitional body carries both.
  put('drive_id', 'outing_id', asString);
  put('species_code', 'species_code', asString);
  put('count', 'count', asInt);
  put('behaviour', 'behaviour', asString);
  put('age_sex_class', 'age_sex_class', asString);
  put('notes', 'notes', asString);
  put('verified_by', 'verified_by', asString);
  put('verification_notes', 'verification_notes', asString);
  put('recorded_species_code', 'recorded_species_code', asString);
  put('recorded_count', 'recorded_count', asInt);
  put('correction_reason', 'correction_reason', asString);
  put('created_by', 'created_by', asString);
  put('revision', 'revision', asInt);
  put('distance_m', 'distance_m', asInt);
  put('bearing_deg', 'bearing_deg', asInt);
  put('location_accuracy_m', 'location_accuracy_m', asDouble);
  put('captured_at', 'captured_at', asMoment);
  put('recorded_at', 'recorded_at', asMoment);
  put('verified_at', 'verified_at', asMoment);
  put('location_lat', 'location', (raw) => _latitudeOf(raw));
  put('location_lng', 'location', (raw) => _longitudeOf(raw));

  put('status', 'status', (raw) {
    final wire = asString(raw);
    return wire == null ? null : statusByWire(wire);
  });
  put('late_arrival', 'late_arrival', (raw) => raw is bool ? raw : null);
  put('is_tombstone', 'is_tombstone', (raw) => raw is bool ? raw : null);
  put('deleted_at', 'deleted_at', asMoment);

  return SightingsCompanion(
    localId: Value(fallbackLocalId),
    serverId: take<String?>('server_id'),
    contextCode: take<String>('context_code'),
    driveId: take<String>('drive_id'),
    speciesCode: take<String?>('species_code'),
    count: take<int?>('count'),
    locationLat: take<double>('location_lat'),
    locationLng: take<double>('location_lng'),
    locationAccuracyM: take<double?>('location_accuracy_m'),
    distanceM: take<int?>('distance_m'),
    bearingDeg: take<int?>('bearing_deg'),
    behaviour: take<String?>('behaviour'),
    ageSexClass: take<String?>('age_sex_class'),
    notes: take<String?>('notes'),
    status: take<SightingStatus>('status'),
    verifiedBy: take<String?>('verified_by'),
    verifiedAt: take<DateTime?>('verified_at'),
    verificationNotes: take<String?>('verification_notes'),
    recordedSpeciesCode: take<String?>('recorded_species_code'),
    recordedCount: take<int?>('recorded_count'),
    correctionReason: take<String?>('correction_reason'),
    lateArrival: take<bool>('late_arrival'),
    capturedAt: take<DateTime>('captured_at'),
    recordedAt: take<DateTime>('recorded_at'),
    revision: take<int>('revision'),
    createdBy: take<String>('created_by'),
    isTombstone: take<bool>('is_tombstone'),
    deletedAt: take<DateTime?>('deleted_at'),
  );
}

/// Latitude of a GeoJSON `Point`, which stores `[longitude, latitude]`.
///
/// A malformed point yields null and the column is left alone rather than being
/// written as zero, which would place a sighting at Null Island.
double? _latitudeOf(Object? location) {
  final coordinate = _coordinatesOf(location);
  if (coordinate == null || coordinate.length < 2) return null;
  return coordinate[1].toDouble();
}

double? _longitudeOf(Object? location) {
  final coordinate = _coordinatesOf(location);
  if (coordinate == null || coordinate.isEmpty) return null;
  return coordinate[0].toDouble();
}

List<num>? _coordinatesOf(Object? location) {
  // The two forms the location can arrive in: GeoJSON from this client's own
  // push payloads, and PostGIS's own hex EWKB from a feed body, because
  // `to_jsonb(geometry)` renders the binary form rather than GeoJSON.
  if (location is String) return _ewkbPoint(location);
  if (location is! Map) return null;
  final coordinates = location['coordinates'];
  if (coordinates is! List) return null;
  return coordinates.whereType<num>().toList();
}

/// Decode a hex-encoded EWKB point into `[longitude, latitude]`.
///
/// Byte order is the first word (1 little, 0 big), then a 32-bit type with
/// optional flag words: SRID is marked by 0x20000000 and follows the type.
/// The low byte of the type names the geometry — 1 is a point — and X/Y are
/// the first two doubles after the header, so a point carrying a third
/// dimension still yields its planar coordinates. Anything unrecognised
/// yields null and the column is left alone rather than written as zero,
/// which would place a record at Null Island.
List<num>? _ewkbPoint(String hex) {
  final text = hex.trim();
  // A point without SRID is 21 bytes (42 hex characters); with SRID, 25.
  if (text.length < 42 || text.length.isOdd) return null;

  final bytes = Uint8List(text.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    final octet = int.tryParse(text.substring(i * 2, i * 2 + 2), radix: 16);
    if (octet == null) return null;
    bytes[i] = octet;
  }

  final byteOrder = bytes[0];
  if (byteOrder != 0 && byteOrder != 1) return null;
  final little = byteOrder == 1;
  final endian = little ? Endian.little : Endian.big;
  final view = ByteData.sublistView(bytes);

  var offset = 1;
  final type = view.getUint32(offset, endian);
  offset += 4;
  if (type & 0x20000000 != 0) offset += 4; // SRID word follows the type.
  if (type & 0xFF != 1) return null; // Not a point.
  if (offset + 16 > bytes.length) return null;

  final longitude = view.getFloat64(offset, endian);
  final latitude = view.getFloat64(offset + 8, endian);
  return [longitude, latitude];
}

/// What a feed body says about a nullable column.
///
/// Three states, exactly as [sightingPatchFromState] documents them: an
/// absent key means the feed did not mention the column and nothing is
/// written; a present key with a value writes it; a present null clears it.
Value<T?> _feedValue<T extends Object>(
  Map<String, dynamic> state,
  String key,
  T? Function(Object? raw) parse,
) {
  if (!state.containsKey(key)) return const Value.absent();
  return Value<T?>(parse(state[key]));
}

/// The same three states, for a column whose schema will not accept null.
///
/// A null from the feed is dropped rather than written: for these columns
/// "cleared" is not a state the table has, so a null is the feed being
/// incomplete rather than a fact being asserted. The insert gate in the
/// pull engine holds the change when the value turns out to be needed.
Value<T> _feedRequired<T extends Object>(
  Map<String, dynamic> state,
  String key,
  T? Function(Object? raw) parse,
) {
  if (!state.containsKey(key)) return const Value.absent();
  final parsed = parse(state[key]);
  if (parsed == null) return const Value.absent();
  return Value<T>(parsed);
}

String? wireString(Object? raw) => raw is String ? raw : null;

int? wireInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

double? wireDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

DateTime? wireMoment(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

/// The storage patch for a drive outing as the change feed presents it.
///
/// The feed body is the outing table alone — duration, guests and the
/// inspection live in the drive's detail table and never appear here — so
/// this patch never touches them. Columns absent from the body keep what the
/// device holds, which is the same rule as every other sparse patch.
DrivesCompanion drivePatchFromState(
  Map<String, dynamic> state, {
  required String fallbackLocalId,
}) {
  return DrivesCompanion(
    localId: Value(fallbackLocalId),
    serverId: _feedValue(state, 'id', wireString),
    contextCode: _feedRequired(state, 'context_code', wireString),
    startedAt: _feedRequired(state, 'start_time', wireMoment),
    endedAt: _feedValue(state, 'end_time', wireMoment),
    sealedAt: _feedValue(state, 'sealed_at', wireMoment),
    guideId: _feedValue(state, 'guide_id', wireString),
    status: _feedValue(state, 'status', wireString),
    weather: _feedValue(state, 'weather', wireString),
    notes: _feedValue(state, 'notes', wireString),
    revision: _feedRequired(state, 'revision', wireInt),
    deletedAt: _feedValue(state, 'deleted_at', wireMoment),
  );
}

/// The storage patch for a trail log as the change feed presents it.
///
/// [driveId] and [trailCode] are parameters rather than feed fields because
/// the service's outing has no such columns and a pulled hike arrives
/// without them: the caller passes the existing row's values on an update,
/// and empty placeholders on an insert — a local label nobody on this device
/// has chosen yet, not a fabricated trail name.
TrailLogsCompanion hikePatchFromState(
  Map<String, dynamic> state, {
  required String fallbackLocalId,
  required String driveId,
  required String trailCode,
}) {
  return TrailLogsCompanion(
    localId: Value(fallbackLocalId),
    serverId: _feedValue(state, 'id', wireString),
    contextCode: _feedRequired(state, 'context_code', wireString),
    startedAt: _feedRequired(state, 'start_time', wireMoment),
    endedAt: _feedValue(state, 'end_time', wireMoment),
    notes: _feedValue(state, 'notes', wireString),
    weather: _feedValue(state, 'weather', wireString),
    status: _feedValue(state, 'status', wireString),
    revision: _feedRequired(state, 'revision', wireInt),
    deletedAt: _feedValue(state, 'deleted_at', wireMoment),
    driveId: Value(driveId),
    trailCode: Value(trailCode),
  );
}

/// The storage patch for a dangerous-game encounter from the change feed.
///
/// Latitude and longitude arrive as the service stores them — one geometry
/// column — and are split into the two columns this schema keeps, in
/// longitude-latitude order on the wire and latitude-longitude here.
DangerousGameEncountersCompanion encounterPatchFromState(
  Map<String, dynamic> state, {
  required String fallbackLocalId,
}) {
  return DangerousGameEncountersCompanion(
    localId: Value(fallbackLocalId),
    serverId: _feedValue(state, 'id', wireString),
    contextCode: _feedRequired(state, 'context_code', wireString),
    outingId: _feedRequired(state, 'outing_id', wireString),
    speciesCode: _feedRequired(state, 'species_code', wireString),
    latitude: _feedRequired(state, 'location', _latitudeOf),
    longitude: _feedRequired(state, 'location', _longitudeOf),
    capturedAt: _feedRequired(state, 'captured_at', wireMoment),
    recordedAt: _feedRequired(state, 'recorded_at', wireMoment),
    createdBy: _feedValue(state, 'created_by', wireString),
    distanceM: _feedValue(state, 'distance_m', wireDouble),
    animalBehaviour: _feedValue(state, 'animal_behaviour', wireString),
    actionTaken: _feedValue(state, 'action_taken', wireString),
    note: _feedValue(state, 'note', wireString),
    revision: _feedRequired(state, 'revision', wireInt),
    deletedAt: _feedValue(state, 'deleted_at', wireMoment),
  );
}

/// The storage patch for a trail waypoint from the change feed.
///
/// The service's geometry column is named `point`, not `location`, and the
/// waypoint keeps no revision of its own: its identity is the uuid both
/// sides minted, which is why there is no revision field here to fill.
TrailWaypointsCompanion waypointPatchFromState(Map<String, dynamic> state) {
  return TrailWaypointsCompanion(
    serverId: _feedValue(state, 'id', wireString),
    trailLogId: _feedRequired(state, 'outing_id', wireString),
    ordinal: _feedRequired(state, 'ordinal', wireInt),
    latitude: _feedRequired(state, 'point', _latitudeOf),
    longitude: _feedRequired(state, 'point', _longitudeOf),
    recordedAt: _feedRequired(state, 'captured_at', wireMoment),
    accuracyMetres: _feedValue(state, 'accuracy_m', wireDouble),
    elevationM: _feedValue(state, 'elevation_m', wireDouble),
    note: _feedValue(state, 'note', wireString),
  );
}

/// The stored status for a wire name, defaulting to [SightingStatus.pending].
///
/// Unlike `behaviour` and `age_sex_class` the contract does enumerate status, so
/// an unrecognised value is a contract violation rather than a known gap.
/// Defaulting to pending is the safe reading: nothing is treated as verified on
/// the strength of a status this client does not recognise.
SightingStatus statusByWireForTest(String wire) => statusByWire(wire);
SightingBehaviour? behaviourByWireForTest(String wire) => behaviourByWire(wire);
AgeSexClass? ageSexByWireForTest(String wire) => ageSexByWire(wire);
String statusWireNameForTest(SightingStatus v) => statusWireName(v);
String behaviourWireNameForTest(SightingBehaviour v) => behaviourWireName(v);
String ageSexWireNameForTest(AgeSexClass v) => ageSexWireName(v);

SightingStatus statusByWire(String wire) {
  // An explicit switch, not a comparison against `value.name`. The two differ
  // for exactly the values that matter: Dart spells needsReview and the wire
  // spells needs_review, so a name comparison silently turned every
  // needs_review sighting into a pending one. That is contract rule 16's
  // distinction destroyed on the way in, and it looked like working code.
  return switch (wire) {
    'pending' => SightingStatus.pending,
    'verified' => SightingStatus.verified,
    'rejected' => SightingStatus.rejected,
    'needs_review' => SightingStatus.needsReview,
    // The contract does enumerate status, so an unrecognised value is a
    // protocol violation rather than a state to model. Falling back to pending
    // is the safe direction: nothing becomes verified on a value we did not
    // understand, and rule 21 lets a pending record be incomplete anyway.
    _ => SightingStatus.pending,
  };
}

/// Decode a behaviour, or null when the wire names one we do not know.
///
/// Null rather than a throw, because the contract does not enumerate
/// `behaviour` at all. Losing an unknown behaviour to an exception would lose
/// the whole sighting; losing it to a null column loses one field and leaves
/// the record intact and visible to whoever reads it.
SightingBehaviour? behaviourByWire(String wire) => switch (wire) {
  'grazing' => SightingBehaviour.grazing,
  'moving' => SightingBehaviour.moving,
  'resting' => SightingBehaviour.resting,
  'feeding' => SightingBehaviour.feeding,
  'with_young' => SightingBehaviour.withYoung,
  'alert' => SightingBehaviour.alert,
  'unknown' => SightingBehaviour.unknown,
  _ => null,
};

/// Decode an age and sex class, or null when the wire names one we do not know.
///
/// Null for the same reason as [ behaviourByWire ]: the contract does not
/// enumerate this list either.
AgeSexClass? ageSexByWire(String wire) => switch (wire) {
  'female' => AgeSexClass.female,
  'male' => AgeSexClass.male,
  'juvenile' => AgeSexClass.juvenile,
  'adult_unknown' => AgeSexClass.adultUnknown,
  'unknown' => AgeSexClass.unknown,
  _ => null,
};

String encodePayload(Map<String, dynamic> payload) => jsonEncode(payload);

/// Decode a stored payload.
///
/// A payload that will not parse is a corrupt row rather than a reason to throw
/// during startup, so this returns null and lets the caller decide. The queue
/// treats an unparseable payload as a refusal it cannot retry, because sending
/// something unparseable would only produce the same refusal again.
Map<String, dynamic>? decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Round-trip one enum value through its wire name, for tests only.
///
/// The encoder and the decoder are separate hand-written switches, and they
/// drifted apart once already: the decoder compared against `value.name`, so
/// every value whose Dart spelling differs from its wire spelling was silently
/// destroyed on the way in. `needs_review` became `pending`, which is not a
/// lost field but a wrong state, and therefore worse.
///
/// This exists so a test can assert that for every value, and for every one of
/// the three lists, the decoder returns what the encoder produced. It is public
/// only because it is the seam that makes that assertion possible; nothing in
/// the app should call it.
T? enumRoundTrip<T extends Enum>(
  T value,
  String Function(T) encode,
  T? Function(String) decode,
) => decode(encode(value));
