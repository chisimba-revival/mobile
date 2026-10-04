import 'package:freezed_annotation/freezed_annotation.dart';

/// A WGS84 point, as the contract's `Point` fields carry it.
///
/// The contract's example model embeds `GeoJsonPoint` from the `geojson`
/// package. That type is not usable here, for reasons verified against
/// `geojson` 1.0.0:
///
///   * It has no `fromJson`, only a `serializeFeature`, so no generated codec
///     can be written for a model containing one.
///   * Its `geoPoint` and `name` fields are mutable, so it cannot take part in
///     the value equality that `freezed` models rely on for correct rebuilds.
///   * It does not re-export the `GeoPoint` it wraps; that class lives in the
///     `geopoint` package, a transitive dependency. Naming it in a public model
///     signature would leak that dependency to every consumer.
///
/// So the client owns an immutable point. It is deliberately a plain class
/// rather than a `freezed` one: a two-field value type does not need generated
/// copyWith, equality and unions, and hand-writing it keeps the JSON codec on
/// the type itself, which is what stops a containing model from serialising the
/// point as an opaque nested object.
///
/// GeoJSON encodes longitude before latitude, which is the reverse of the order
/// a person reads, and that inversion is handled in exactly one place here
/// rather than at every call site.
@immutable
class GeoPoint {
  const GeoPoint({required this.longitude, required this.latitude});

  /// Degrees east, negative west.
  final double longitude;

  /// Degrees north, negative south.
  final double latitude;

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }

  /// The flat generated form, used by models that embed this one.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'longitude': longitude,
    'latitude': latitude,
  };

  /// The GeoJSON `coordinates` member: `[longitude, latitude]`.
  List<double> toCoordinates() => <double>[longitude, latitude];

  /// A GeoJSON `Point` geometry object.
  Map<String, dynamic> toGeoJson() => <String, dynamic>{
    'type': 'Point',
    'coordinates': toCoordinates(),
  };

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.longitude == longitude &&
      other.latitude == latitude;

  @override
  int get hashCode => Object.hash(longitude, latitude);

  @override
  String toString() => 'GeoPoint($longitude, $latitude)';
}

/// Reads a GeoJSON `Point` geometry.
///
/// A silently transposed point puts a sighting in the wrong hemisphere, which
/// is a plausible-looking wrong answer rather than an obvious error, so a
/// geometry of the wrong shape throws instead of being coerced.
GeoPoint geoPointFromGeometry(Map<String, dynamic> geometry) {
  if (geometry['type'] != 'Point') {
    throw FormatException('Expected a GeoJSON Point, got ${geometry['type']}.');
  }
  final coordinates = geometry['coordinates'];
  if (coordinates is! List || coordinates.length < 2) {
    throw FormatException('A GeoJSON Point needs two coordinates.');
  }
  return GeoPoint(
    longitude: (coordinates[0] as num).toDouble(),
    latitude: (coordinates[1] as num).toDouble(),
  );
}

/// Writes a point as a GeoJSON `Point` geometry, for the transport edge.
///
/// Models carry the flat generated form; the wire carries GeoJSON. Keeping the
/// conversion here means no model has to know which of the two it is in, and a
/// contract change to the geometry shape is a one-line change.
class GeoPointConverter extends JsonConverter<GeoPoint, Map<String, dynamic>> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Map<String, dynamic> json) => geoPointFromGeometry(json);

  @override
  Map<String, dynamic> toJson(GeoPoint object) => object.toGeoJson();
}
