import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// Where the bundled archive ends up: a stable name in the support directory,
/// so a later launch reuses the copy it already made.
const _archiveAssetKey = 'assets/pmtiles/reserve.pmtiles';
const _archiveFileName = 'reserve.pmtiles';

/// Prepares the reserve's surveyed topology for the map.
///
/// The PMTiles reader opens archives by file path only, so a bundled asset is
/// copied once into the app's support directory. The copy is skipped when the
/// file is already there, which means refreshing the archive happens by
/// shipping a new build, not by asking the user to clear data.
///
/// Returns the archive path, or null when this build carries no archive (a
/// build made without `assets/pmtiles/` present). null leaves the caller on
/// the painted vector map, which is the intended fallback: the painted map
/// needs no data to be correct, only this archive needs data to be surveyed.
Future<String?> prepareReserveTopology() async {
  try {
    final bytes = await rootBundle.load(_archiveAssetKey);
    final file = File(
      '${(await getApplicationSupportDirectory()).path}/$_archiveFileName',
    );
    if (!await file.exists()) {
      // Write to a temp name first, then rename: a crash mid-copy would
      // otherwise leave a truncated archive in place, and the "already
      // exists" check would then never rewrite the bad file.
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await partial.rename(file.path);
    }
    return file.path;
  } catch (_) {
    // Missing asset, unwritable directory, corrupted bytes: all the same to
    // the caller. Fall back to the painted map.
    return null;
  }
}
