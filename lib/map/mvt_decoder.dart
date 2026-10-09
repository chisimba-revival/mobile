import 'dart:typed_data';
import 'dart:ui' as ui;

/// A decoder for Mapbox Vector Tiles (MVT), spec 2.1.
///
/// The vector tile layer in [vector_tile_layer.dart] fetches tiles from a
/// PMTiles archive; this file turns the raw protobuf bytes into geometry that
/// [mvt_renderer.dart] can rasterize. It is deliberately small and dependency
/// free: the MVT wire format has three field kinds we care about, and a
/// compact reader beats a protobuf dependency.
///
/// Only tippecanoe-default archives are supported: layer extent is assumed
/// to be 4096 (tippecanoe's default), and packed geometry/tags are expected.

/// One entry in a layer's values table. Exactly one member is set.
class MvtValue {
  const MvtValue.string(this._string)
    : _double = null,
      _int = null,
      _bool = null;
  const MvtValue.double(this._double)
    : _string = null,
      _int = null,
      _bool = null;
  const MvtValue.int(this._int) : _string = null, _double = null, _bool = null;
  const MvtValue.bool(this._bool) : _string = null, _double = null, _int = null;

  final String? _string;
  final double? _double;
  final int? _int;
  final bool? _bool;

  Object? get value => _string ?? _double ?? _int ?? _bool;

  @override
  String toString() => 'MvtValue($value)';
}

/// Geometry types per the MVT spec.
enum MvtGeometryType { unknown, point, lineString, polygon }

/// A decoded feature: its type, tag pairs (into the layer key/value tables)
/// and its geometry as delta-decoded paths in extent coordinates.
class MvtFeature {
  const MvtFeature({
    required this.type,
    required this.tags,
    required this.paths,
  });

  final MvtGeometryType type;

  /// Flat list of (keyIndex, valueIndex) pairs into the layer tables.
  final List<int> tags;

  /// Decoded geometry. Each inner list is one MoveTo...segment: for
  /// lineString features a single polyline, for polygon features one ring
  /// (rings are implicit by MoveTo, the renderer closes them itself; holes
  /// are separate rings in the same feature).
  final List<List<ui.Offset>> paths;
}

/// A decoded MVT layer (a named group of features with shared tables).
class MvtLayer {
  const MvtLayer({
    required this.name,
    required this.extent,
    required this.features,
    required this.keys,
    required this.values,
  });

  final String name;
  final int extent;
  final List<MvtFeature> features;
  final List<String> keys;
  final List<MvtValue> values;
}

/// Decodes a full MVT tile. Returns the layers in file order.
List<MvtLayer> decodeMvtTile(Uint8List bytes) {
  final reader = _ProtobufReader(bytes);
  final layers = <MvtLayer>[];
  reader.forEachField((field, sub, value) {
    if (field == 3) {
      // Tile.layers = repeated Layer.
      layers.add(_decodeLayer(sub));
    }
  });
  return layers;
}

MvtLayer _decodeLayer(Uint8List bytes) {
  final reader = _ProtobufReader(bytes);
  var name = '';
  var extent = 4096;
  var keys = <String>[];
  var values = <MvtValue>[];
  var features = <MvtFeature>[];
  reader.forEachField((field, sub, value) {
    switch (field) {
      case 1:
        name = String.fromCharCodes(sub);
      case 2:
        features.add(_decodeFeature(sub));
      case 3:
        keys.add(String.fromCharCodes(sub));
      case 4:
        values.add(_decodeValue(sub));
      case 5:
        extent = value ?? 4096;
      case 15: // version (varint); not needed for decoding.
    }
  });
  return MvtLayer(
    name: name,
    extent: extent,
    features: features,
    keys: keys,
    values: values,
  );
}

MvtValue _decodeValue(Uint8List bytes) {
  final reader = _ProtobufReader(bytes);
  String? s;
  double? d;
  int? i;
  bool? b;
  reader.forEachField((field, sub, value) {
    switch (field) {
      case 1:
        s = String.fromCharCodes(sub);
      case 2:
        d = _fixed32(sub);
      case 3:
        if (sub.length >= 8) {
          d = ByteData.sublistView(sub, 0, 8).getFloat64(0, Endian.little);
        }
      case 5: // int64
      case 6: // uint64
        i = value;
      case 7: // sint64 (zigzag)
        i = _zigzag(value ?? 0);
      case 8:
        b = value != 0;
    }
  });
  if (s != null) return MvtValue.string(s);
  if (d != null) return MvtValue.double(d);
  if (i != null) return MvtValue.int(i);
  if (b != null) return MvtValue.bool(b);
  return const MvtValue.string('');
}

MvtFeature _decodeFeature(Uint8List bytes) {
  final reader = _ProtobufReader(bytes);
  var type = 0;
  var tags = <int>[];
  var geometry = <int>[];
  reader.forEachField((field, sub, value) {
    switch (field) {
      case 2:
        final r = _ProtobufReader(sub);
        while (r.bytesRemaining > 0) {
          tags.add(r.varint());
        }
      case 3:
        type = value ?? 0;
      case 4:
        final r = _ProtobufReader(sub);
        while (r.bytesRemaining > 0) {
          geometry.add(r.varint());
        }
    }
  });

  return MvtFeature(
    type: MvtGeometryType.values[type.clamp(0, 3)],
    tags: tags,
    paths: _decodeGeometry(geometry),
  );
}

/// Decodes MVT geometry command integers into a list of paths. Every MoveTo
/// starts a new path, LineTo appends to the current one, and ClosePath (7)
/// carries no parameters — rings are closed by the renderer.
List<List<ui.Offset>> _decodeGeometry(List<int> commands) {
  final paths = <List<ui.Offset>>[];
  List<ui.Offset>? current;
  var x = 0;
  var y = 0;
  var i = 0;
  while (i < commands.length) {
    final cmdInt = commands[i++];
    final id = cmdInt & 0x7;
    final count = cmdInt >> 3;
    if (id == 1 || id == 2) {
      for (var c = 0; c < count && i + 1 < commands.length; c++) {
        x += _zigzag(commands[i]);
        y += _zigzag(commands[i + 1]);
        i += 2;
        final point = ui.Offset(x.toDouble(), y.toDouble());
        if (id == 1) {
          current = [point];
          paths.add(current);
        } else {
          current!.add(point);
        }
      }
    }
    // id == 7 (ClosePath) carries no parameters; id == 0 is skipped along
    // with any unrecognised command codes.
  }
  return paths;
}

int _zigzag(int n) => (n >> 1) ^ -(n & 1);

double _fixed32(Uint8List sub) {
  if (sub.length < 4) return 0;
  return ByteData.sublistView(sub, 0, 4).getFloat32(0, Endian.little);
}

/// A small forward-only protobuf reader.
///
/// Parsing is done through [forEachField] which walks fields in order. Every
/// length-delimited payload is handed over as a fresh [Uint8List] slice so
/// nested messages can be parsed with their own reader; varint (wire 0) and
/// 32-bit (wire 5) fields pass their raw value / bytes respectively.
class _ProtobufReader {
  _ProtobufReader(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  int get bytesRemaining => _bytes.length - _offset;

  int varint() {
    var result = 0;
    var shift = 0;
    while (_offset < _bytes.length) {
      final byte = _bytes[_offset++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) break;
      shift += 7;
      if (shift > 63) break;
    }
    return result;
  }

  /// Walks every field, calling [handler] with (fieldNumber, payload, value).
  /// For wire 2 (length-delimited) and wire 5 (32-bit), payload carries the
  /// bytes and value is null. For wire 0 (varint), payload is empty and value
  /// carries the number. Wire 1 (64-bit) is skipped unparsed.
  void forEachField(
    void Function(int field, Uint8List sub, int? value) handler,
  ) {
    while (bytesRemaining > 0) {
      final tag = varint();
      final field = tag >> 3;
      final wire = tag & 0x7;
      switch (wire) {
        case 0:
          handler(field, Uint8List(0), varint());
        case 1:
          _offset += 8;
        case 2:
          final len = varint();
          final start = _offset;
          _offset += len;
          handler(field, _bytes.sublist(start, start + len), null);
        case 5:
          handler(field, _bytes.sublist(_offset, _offset + 4), null);
          _offset += 4;
        default:
          return;
      }
    }
  }
}
