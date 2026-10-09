/// The app's default MapTiler key for production releases.
///
/// This file is git-ignored on purpose: it holds a secret. To set the key,
/// start from `maptiler_key.example.dart` in the same directory:
///
/// ```sh
/// cp lib/config/maptiler_key.example.dart lib/config/maptiler_key.dart
/// ```
///
/// then paste your key into the string below, e.g.
///
/// ```dart
/// const String maptilerKeyOverride = 'c0ffee5ecret...';
/// ```
///
/// How the key is chosen (see lib/map/maptiler_tiles.dart):
///   1. `flutter build ... --dart-define=MAPTILER_KEY=<key>` wins when the
///      build pipeline provides one (CI, release scripts).
///   2. Otherwise this override is the app's default — edit it before
///      creating a production release.
///   3. No key anywhere → the app keeps using OpenStreetMap tiles.
///
/// Free keys: https://cloud.maptiler.com (unused for hosted MapTiler)
const String maptilerKeyOverride = '';
