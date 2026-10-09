/// MapTiler raster tiles — the "proper map" look.
///
/// The basemap is a compile-time choice so the binary is self-contained:
///
/// ```sh
/// flutter run --dart-define=MAPTILER_KEY=<your key>
/// ```
///
/// Free keys come from https://cloud.maptiler.com (see their pricing;
/// the free tier covers dev and small deployments). Without a key the map
/// keeps using OpenStreetMap's tiles, so the app never depends on the key
/// being present. Caching, offline behaviour and the vector fallback are
/// unchanged: this only replaces the remote source.
///
/// The provider renders street-style tiles at 256px, which is the familiar
/// Google-Maps-like look. Styles can be swapped at build time with
/// `MAPTILER_STYLE` (streets-v2, basic-v2, satellite, topo-v2, ...).
library;

import 'package:field_log/config/maptiler_key.dart';

/// The MapTiler key for this build, resolved in this order:
///   1. `--dart-define=MAPTILER_KEY=...` when the build provides one
///      (the CI or release-pipeline path),
///   2. `maptilerKeyOverride` from lib/config/maptiler_key.dart otherwise —
///      the developer-editable default for production releases,
///   3. '' → the app keeps using OpenStreetMap tiles.
const String maptilerKey = _definedKey != ''
    ? _definedKey
    : maptilerKeyOverride;

/// The key handed in at build time; empty when none was given.
const String _definedKey = String.fromEnvironment(
  'MAPTILER_KEY',
  defaultValue: '',
);

/// The style of MapTiler tiles to request; see MAPTILER_STYLE above.
const String maptilerStyle = String.fromEnvironment(
  'MAPTILER_STYLE',
  defaultValue: 'streets-v2',
);

/// True when this build carries a MapTiler key, so screens can choose which
/// template to feed the tile provider.
bool get maptilerEnabled => maptilerKey.isNotEmpty;

/// The {z}/{x}/{y} template for the configured style, key baked in.
String maptilerUrlTemplate() =>
    'https://api.maptiler.com/maps/$maptilerStyle/256/{z}/{x}/{y}.png?key=$maptilerKey';

/// Attribution is a condition of using MapTiler tiles (they are OSM-derived),
/// displayed on the map exactly like OpenStreetMap's own condition.
const String maptilerAttribution = '© MapTiler © OpenStreetMap contributors';
