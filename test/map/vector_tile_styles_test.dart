import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/vector_tile_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The kinds the reserve archive actually tags its features with. The style
/// map is keyed by these, so a missing key means a kind that will never draw.
const kinds = [
  'boundary',
  'roads',
  'waterholes',
  'acacia',
  'contours',
  'contours_index',
];

void main() {
  group('reserveVectorStyles', () {
    test('covers every kind the archive emits', () {
      final styles = reserveVectorStyles(colours: FieldColours.dark);
      expect(styles.keys, containsAll(kinds));
    });

    test('takes its colours from the palette it is given', () {
      final dark = reserveVectorStyles(colours: FieldColours.dark);
      final sunlight = reserveVectorStyles(colours: FieldColours.sunlight);

      expect(dark['waterholes']!.fillColor, FieldColours.dark.water);
      expect(sunlight['waterholes']!.fillColor, FieldColours.sunlight.water);
      expect(dark['boundary']!.strokeColor, FieldColours.dark.ash1);
      expect(sunlight['boundary']!.strokeColor, FieldColours.sunlight.ash1);
    });

    test('scales stroke weight with density', () {
      double roadWidth(Density density) => reserveVectorStyles(
        colours: FieldColours.dark,
        density: density,
      )['roads']!.strokeWidth;

      expect(
        roadWidth(Density.compact),
        lessThan(roadWidth(Density.comfortable)),
      );
      expect(
        roadWidth(Density.comfortable),
        lessThan(roadWidth(Density.spacious)),
      );
    });

    test('survey leans on the boundary, navigation on the roads', () {
      final field = reserveVectorStyles(
        colours: FieldColours.dark,
        preset: MapStylePreset.field,
      );
      final survey = reserveVectorStyles(
        colours: FieldColours.dark,
        preset: MapStylePreset.survey,
      );
      final navigation = reserveVectorStyles(
        colours: FieldColours.dark,
        preset: MapStylePreset.navigation,
      );

      expect(
        survey['boundary']!.strokeWidth,
        greaterThan(field['boundary']!.strokeWidth),
      );
      expect(survey['boundary']!.strokeColor, FieldColours.dark.bone);
      expect(navigation['roads']!.strokeColor, FieldColours.dark.bone);
      expect(
        navigation['roads']!.strokeWidth,
        greaterThan(field['roads']!.strokeWidth),
      );
      expect(
        field['acacia']!.fillOpacity,
        greaterThan(navigation['acacia']!.fillOpacity),
      );
    });

    test('names and elevations are labelled', () {
      final styles = reserveVectorStyles(colours: FieldColours.dark);
      expect(styles['waterholes']!.labelProperty, 'name');
      expect(styles['contours_index']!.labelProperty, 'elevation');
    });

    test('the default getter is the dark palette', () {
      expect(
        defaultVectorLayerStyles['boundary']!.strokeColor,
        FieldColours.dark.ash1,
      );
    });
  });

  group('pmTilesStyleSignature', () {
    // The tile image cache keys on this fingerprint, so it must not change
    // when nothing visible changed, and must change whenever the drawing does.
    test('is independent of map iteration order', () {
      final forward = reserveVectorStyles(colours: FieldColours.dark);
      final reversed = Map.fromEntries(
        reserveVectorStyles(colours: FieldColours.dark).entries
            .toList()
            .reversed,
      );
      expect(pmTilesStyleSignature(forward), pmTilesStyleSignature(reversed));
    });

    test('changes when the palette changes', () {
      expect(
        pmTilesStyleSignature(reserveVectorStyles(colours: FieldColours.dark)),
        isNot(
          pmTilesStyleSignature(
            reserveVectorStyles(colours: FieldColours.sunlight),
          ),
        ),
      );
    });

    test('changes when density changes', () {
      expect(
        pmTilesStyleSignature(
          reserveVectorStyles(
            colours: FieldColours.dark,
            density: Density.compact,
          ),
        ),
        isNot(
          pmTilesStyleSignature(
            reserveVectorStyles(
              colours: FieldColours.dark,
              density: Density.spacious,
            ),
          ),
        ),
      );
    });

    test('changes when the preset changes', () {
      expect(
        pmTilesStyleSignature(
          reserveVectorStyles(
            colours: FieldColours.dark,
            preset: MapStylePreset.field,
          ),
        ),
        isNot(
          pmTilesStyleSignature(
            reserveVectorStyles(
              colours: FieldColours.dark,
              preset: MapStylePreset.survey,
            ),
          ),
        ),
      );
    });

    test('changes when a layer is hidden', () {
      final all = reserveVectorStyles(colours: FieldColours.dark);
      final withoutRoads = Map.of(all)..remove('roads');
      expect(
        pmTilesStyleSignature(all),
        isNot(pmTilesStyleSignature(withoutRoads)),
      );
    });

    test('changes when only a label font field changes', () {
      // The renderer paints the label with the whole TextStyle, so a change
      // that leaves the colour and size alone must still invalidate the tile.
      VectorLayerStyle withWeight(FontWeight weight) => VectorLayerStyle(
        labelProperty: 'name',
        labelStyle: TextStyle(fontWeight: weight),
      );

      expect(
        pmTilesStyleSignature({'waterholes': withWeight(FontWeight.w400)}),
        isNot(
          pmTilesStyleSignature({'waterholes': withWeight(FontWeight.w900)}),
        ),
      );
    });
  });
}
