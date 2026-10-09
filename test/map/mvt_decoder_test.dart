import 'dart:convert';
import 'dart:typed_data';

import 'package:field_log/map/mvt_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal protobuf writer for hand-building MVT test tiles.
class _W {
  final BytesBuilder _b = BytesBuilder();

  List<int> build() => _b.toBytes();

  void _varint(int v) {
    var value = v;
    while (true) {
      if ((value & ~0x7f) == 0) {
        _b.addByte(value);
        return;
      }
      _b.addByte((value & 0x7f) | 0x80);
      value >>= 7;
    }
  }

  void tag(int field, int wire) => _varint((field << 3) | wire);

  void lenField(int field, List<int> payload) {
    tag(field, 2);
    _varint(payload.length);
    _b.add(payload);
  }

  void varintField(int field, int value) {
    tag(field, 0);
    _varint(value);
  }
}

int _zig(int v) => v < 0 ? (-v) * 2 - 1 : v * 2;

/// A MoveTo+LineTo run encoded as MVT command integers.
List<int> _geom(int command, List<(int, int)> deltas) {
  final out = <int>[((command & 0x7) | (deltas.length << 3))];
  for (final (dx, dy) in deltas) {
    out.add(_zig(dx));
    out.add(_zig(dy));
  }
  return out;
}

Uint8List _tileWithOneLineFeature({
  required String layerName,
  required String key,
  required int value,
  required List<int> geometryCommands,
}) {
  // Value{int=5}
  final valueBytes = _W()..varintField(5, value);
  // Feature{type=2 lineString, tags=[0,0] packed, geometry=... packed}
  final feature = _W();
  feature.lenField(2, [0, 0]);
  feature.varintField(3, 2);
  feature.lenField(4, geometryCommands);
  // Layer{name=1, features=2, keys=3, values=4, extent=5, version=15}
  final layer = _W();
  layer.lenField(1, utf8.encode(layerName));
  layer.lenField(2, feature.build());
  layer.lenField(3, utf8.encode(key));
  layer.lenField(4, valueBytes.build());
  layer.varintField(5, 4096);
  layer.varintField(15, 2);
  // Tile{layers=3}
  final tile = _W()..lenField(3, layer.build());
  return Uint8List.fromList(tile.build());
}

void main() {
  group('decodeMvtTile', () {
    test('decodes a single lineString layer with tags and extent', () {
      // MoveTo(5,7), LineTo(3,5), LineTo(10,-2): four points total.
      final commands = [
        ..._geom(1, [(5, 7)]),
        ..._geom(2, [(3, 5), (10, -2)]),
      ];
      final bytes = _tileWithOneLineFeature(
        layerName: 'contours',
        key: 'elevation',
        value: 1234,
        geometryCommands: commands,
      );

      final layers = decodeMvtTile(bytes);
      expect(layers, hasLength(1));
      final layer = layers.single;
      expect(layer.name, 'contours');
      expect(layer.extent, 4096);
      expect(layer.keys, ['elevation']);
      expect(layer.values.single.value, 1234);

      final feature = layer.features.single;
      expect(feature.type, MvtGeometryType.lineString);
      expect(feature.tags, [0, 0]);
      expect(feature.paths, hasLength(1));
      expect(feature.paths.single, [
        const Offset(5, 7),
        const Offset(8, 12),
        const Offset(18, 10),
      ]);
    });

    test('separates rings and polylines at each MoveTo', () {
      // Two MoveTo runs: a triangle-ish polyline and a separate point.
      // Deltas accumulate across commands: cursor is (10,10) after the first
      // run, so a MoveTo(20,20) lands on (30,30).
      final commands = [
        ..._geom(1, [(0, 0)]),
        ..._geom(2, [(10, 0), (0, 10)]),
        ..._geom(1, [(20, 20)]),
      ];
      final bytes = _tileWithOneLineFeature(
        layerName: 'roads',
        key: 'name',
        value: 0,
        geometryCommands: commands,
      );

      final paths = decodeMvtTile(bytes).single.features.single.paths;
      expect(paths, hasLength(2));
      expect(paths[0], [
        const Offset(0, 0),
        const Offset(10, 0),
        const Offset(10, 10),
      ]);
      expect(paths[1], [const Offset(30, 30)]);
    });

    test('ClosePath adds no points', () {
      final commands = [
        ..._geom(1, [(0, 0)]),
        ..._geom(2, [(10, 0), (0, 10)]),
        // ClosePath: id 7, count 1 → command 57, no parameters.
        57,
      ];
      final bytes = _tileWithOneLineFeature(
        layerName: 'boundary',
        key: 'id',
        value: 1,
        geometryCommands: commands,
      );

      final paths = decodeMvtTile(bytes).single.features.single.paths;
      expect(paths.single, hasLength(3));
    });

    test('string values decode', () {
      // Value{string=1}
      final valueBytes = _W()..lenField(1, utf8.encode('Mzinga Pan'));
      final feature = _W();
      feature.lenField(2, [0, 0]);
      feature.varintField(3, 1); // point
      // MoveTo(40, 40)
      feature.lenField(4, _geom(1, [(40, 40)]));
      final layer = _W();
      layer.lenField(1, utf8.encode('waterholes'));
      layer.lenField(2, feature.build());
      layer.lenField(3, utf8.encode('name'));
      layer.lenField(4, valueBytes.build());
      layer.varintField(15, 2);
      final tile = _W()..lenField(3, layer.build());

      final feature0 = decodeMvtTile(Uint8List.fromList(tile.build()))
          .single
          .features
          .single;
      expect(feature0.type, MvtGeometryType.point);
      expect(feature0.paths.single, [const Offset(40, 40)]);
    });
  });
}
