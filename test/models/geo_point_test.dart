import 'package:field_log/models/geo_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoJSON writes longitude before latitude', () {
    test('the coordinate order is the one GeoJSON specifies', () {
      const point = GeoPoint(longitude: 22.6875, latitude: -19.9833);
      expect(point.toCoordinates(), <double>[22.6875, -19.9833]);
      expect(point.toGeoJson(), <String, dynamic>{
        'type': 'Point',
        'coordinates': <double>[22.6875, -19.9833],
      });
    });

    test('a geometry round-trips', () {
      const point = GeoPoint(longitude: 22.6875, latitude: -19.9833);
      expect(geoPointFromGeometry(point.toGeoJson()), point);
    });

    test('a swapped coordinate order is a different place', () {
      // Guarding against the inversion that costs the most: a transposed point
      // is a plausible-looking answer rather than an obvious error.
      const correct = GeoPoint(longitude: 22.6875, latitude: -19.9833);
      const swapped = GeoPoint(longitude: -19.9833, latitude: 22.6875);
      expect(geoPointFromGeometry(swapped.toGeoJson()), isNot(correct));
    });
  });

  group('a malformed geometry fails loudly', () {
    test('a non-Point type is rejected', () {
      expect(
        () => geoPointFromGeometry(<String, dynamic>{
          'type': 'LineString',
          'coordinates': <List<double>>[
            <double>[0, 0],
            <double>[1, 1],
          ],
        }),
        throwsFormatException,
      );
    });

    test('too few coordinates is rejected', () {
      expect(
        () => geoPointFromGeometry(<String, dynamic>{
          'type': 'Point',
          'coordinates': <double>[1],
        }),
        throwsFormatException,
      );
      expect(
        () => geoPointFromGeometry(<String, dynamic>{'type': 'Point'}),
        throwsFormatException,
      );
    });
  });

  group('generated codec', () {
    test('serialises to flat longitude and latitude', () {
      const point = GeoPoint(longitude: 1.5, latitude: -2.5);
      expect(point.toJson(), <String, dynamic>{
        'longitude': 1.5,
        'latitude': -2.5,
      });
    });

    test('reads a generated payload back', () {
      expect(
        GeoPoint.fromJson(<String, dynamic>{
          'longitude': 1.5,
          'latitude': -2.5,
        }),
        const GeoPoint(longitude: 1.5, latitude: -2.5),
      );
    });
  });
}
