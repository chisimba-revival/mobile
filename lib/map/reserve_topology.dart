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
/// copied once into the app's support directory. The copy is rewritten when the
/// bundled archive's bytes differ from the copy on disk, so shipping a new
/// build refreshes the archive; a copy left in place only because a file of
/// that name exists would otherwise survive every later build.
///
/// Returns the archive path, or null when this build carries no archive (a
/// build made without `assets/pmtiles/` present). null leaves the caller on
/// the painted vector map, which is the intended fallback: the painted map
/// needs no data to be correct, only this archive needs data to be surveyed.
Future<String?> prepareReserveTopology() async {
  try {
    final data = await rootBundle.load(_archiveAssetKey);
    // [ByteData.buffer] can be larger than the asset it backs, so the view is
    // taken at the data's own offset and length rather than over the whole
    // buffer.
    final assetBytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final file = File(
      '${(await getApplicationSupportDirectory()).path}/$_archiveFileName',
    );
    final current = await file.exists() ? await file.readAsBytes() : null;
    if (current == null || !_sameBytes(current, assetBytes)) {
      // Write to a temp name first, then rename: a crash mid-copy would
      // otherwise leave a truncated archive in place, and the comparison would
      // then rewrite the bad file on the next launch.
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(assetBytes, flush: true);
      await partial.rename(file.path);
    }
    return file.path;
  } catch (_) {
    // Missing asset, unwritable directory, corrupted bytes: all the same to
    // the caller. Fall back to the painted map.
    return null;
  }
}

/// Whether two byte lists are identical in length and content.
bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
