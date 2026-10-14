import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// South Africa — the country this build is for.
///
/// The bounds cover the mainland: the Orange River and the Zimbabwe, Botswana
/// and Mozambique borders in the north, Cape Agulhas in the south, the Atlantic
/// in the west and the Indian Ocean in the east. The Prince Edward Islands are
/// deliberately excluded: they sit 1,700 km into the Southern Ocean and would
/// stretch the country view until the mainland was unusable.
final southAfricaBounds = LatLngBounds(
  const LatLng(-35.2, 16.0),
  const LatLng(-21.8, 33.2),
);

/// A centre that shows the whole country: the middle of the mainland, biased
/// slightly south so the coastal band is not pushed off the foot of the screen.
final southAfricaCentre = const LatLng(-28.5, 24.6);

/// How far the map may be zoomed, in one place so the initial camera, the
/// controls and the route editor cannot disagree.
///
/// The floor is low enough to hold the whole country: at zoom 4 South Africa
/// fills a phone screen with room to spare, which is the most zoomed-out view
/// the app needs. Pinning it at field scale (as it once was, at 8) hid the
/// country entirely and made the zoom-out control pull the map *in*.
const double minZoom = 4;
const double maxZoom = 18;

/// The zoom the map opens at before the device has a fix: the country seen
/// whole. Six is what the scale bar reads as 100 km over South Africa.
const double countryZoom = 6;
