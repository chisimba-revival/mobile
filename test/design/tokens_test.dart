import 'package:field_log/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests exist to make the design document and the code disagree loudly.
///
/// Every value asserted here is transcribed from the token table in
/// `chisimba-info/docs/mobile-design/README.md`. If one of these fails, the
/// design changed and the code did not, or the reverse; both are worth a
/// conversation rather than a quiet edit.
void main() {
  group('dark palette is the design token table verbatim', () {
    test('surfaces and ink', () {
      expect(FieldColours.dark.canopy, const Color(0xFF111E19));
      expect(FieldColours.dark.canopyRaised, const Color(0xFF172722));
      expect(FieldColours.dark.canopyOverlay, const Color(0xFF1E312A));
      expect(FieldColours.dark.inset, const Color(0xFF0C1613));
      expect(FieldColours.dark.bone, const Color(0xFFE9E3D7));
    });

    test('accents', () {
      expect(FieldColours.dark.dust, const Color(0xFFC4612F));
      expect(FieldColours.dark.straw, const Color(0xFFC9A227));
      expect(FieldColours.dark.moss, const Color(0xFF6E9B72));
      expect(FieldColours.dark.blood, const Color(0xFFA8452F));
    });

    test('rule is bone at nine, sixteen and thirty per cent', () {
      // Recomputed rather than hardcoded, so the test states the rule and not
      // just the number it happened to produce. Colour channels are doubles in
      // the range 0..1 on this Flutter version, so the blend stays in that
      // range too.
      Color overCanopy(double alpha) {
        const bone = Color(0xFFE9E3D7);
        const canopy = Color(0xFF111E19);
        // Rounded to 8 bits per channel, because a token is a hex literal and
        // an unrounded blend is a colour no screen can display.
        double channel(double over, double under) {
          final value = over * alpha + under * (1 - alpha);
          return (value * 255).round() / 255;
        }

        return Color.from(
          alpha: 1,
          red: channel(bone.r, canopy.r),
          green: channel(bone.g, canopy.g),
          blue: channel(bone.b, canopy.b),
        );
      }

      expect(FieldColours.dark.ruleFaint, overCanopy(0.09));
      expect(FieldColours.dark.rule, overCanopy(0.16));
      expect(FieldColours.dark.ruleStrong, overCanopy(0.30));
    });

    test('an input fill is darker than the surface it sits on', () {
      // The design states inputs are darker than their surroundings because
      // they receive content. This holds in the dark palette by construction;
      // in sunlight it holds because the same relationship was inverted.
      expect(
        FieldColours.dark.inset.computeLuminance(),
        lessThan(FieldColours.dark.canopy.computeLuminance()),
      );
      expect(
        FieldColours.sunlight.inset.computeLuminance(),
        lessThan(FieldColours.sunlight.canopy.computeLuminance()),
      );
    });
  });

  group('primary ink is legible on its own surface', () {
    test('dark palette', () {
      expect(
        FieldColours.contrastWith(
          FieldColours.dark.bone,
          FieldColours.dark.canopy,
        ),
        greaterThan(7.0),
      );
      expect(
        FieldColours.contrastWith(
          FieldColours.dark.ash3,
          FieldColours.dark.canopy,
        ),
        greaterThan(3.0),
      );
    });

    test('sunlight palette', () {
      expect(
        FieldColours.contrastWith(
          FieldColours.sunlight.bone,
          FieldColours.sunlight.canopy,
        ),
        greaterThan(7.0),
      );
    });
  });

  group('sunlight inverts lightness without re-tinting a hue', () {
    test('the accents are identical in both palettes', () {
      // The design's stated reason for the inversion is that nothing re-tints,
      // so no contrast pair needs re-deriving. That is only true if the accents
      // are literally the same values.
      expect(FieldColours.sunlight.dust, FieldColours.dark.dust);
      expect(FieldColours.sunlight.straw, FieldColours.dark.straw);
      expect(FieldColours.sunlight.moss, FieldColours.dark.moss);
      expect(FieldColours.sunlight.blood, FieldColours.dark.blood);
    });

    test('inkOn picks the measurably better of the two inks', () {
      for (final colours in <FieldColours>[
        FieldColours.dark,
        FieldColours.sunlight,
      ]) {
        for (final accent in <Color>[
          colours.dust,
          colours.straw,
          colours.moss,
          colours.blood,
        ]) {
          final onBone = FieldColours.contrastWith(colours.bone, accent);
          final onCanopy = FieldColours.contrastWith(colours.canopy, accent);
          expect(
            colours.inkOn(accent),
            onBone >= onCanopy ? colours.bone : colours.canopy,
            reason: '${colours.name} chose the worse ink on $accent',
          );
        }
      }
    });

    test('every accent clears the large-text floor as ink on itself', () {
      // 3.0 is the AA threshold for large text and the floor for a non-text
      // mark such as a stamp outline. All four accents clear it in both
      // palettes, so a status colour can always carry a label.
      for (final colours in <FieldColours>[
        FieldColours.dark,
        FieldColours.sunlight,
      ]) {
        for (final accent in <Color>[
          colours.dust,
          colours.straw,
          colours.moss,
          colours.blood,
        ]) {
          expect(
            FieldColours.contrastWith(colours.inkOn(accent), accent),
            greaterThanOrEqualTo(3.0),
            reason: 'no legible ink on $accent in ${colours.name}',
          );
        }
      }
    });

    test('dust is the one accent that cannot carry body text on a fill', () {
      // Laterite earth measures 4.17:1 against its best ink, which is below the
      // 4.5:1 AA threshold for body text and above the 3.0:1 large-text floor.
      // Dust is therefore a fill, a stamp and a rule, and must not be the
      // colour of running text on itself. Pinned here because raising it later
      // is a deliberate act that should have to change this test.
      for (final colours in <FieldColours>[
        FieldColours.dark,
        FieldColours.sunlight,
      ]) {
        final onDust = FieldColours.contrastWith(colours.inkOn(colours.dust), colours.dust);
        expect(onDust, greaterThanOrEqualTo(3.0));
        expect(onDust, lessThan(4.5));
      }
    });

    test('holding an accent hue across both palettes costs it as text', () {
      // This is the sharp edge of the design's own rule: "one hue, lightness
      // shifts only, so nothing re-tints and no contrast pair needs
      // re-deriving". It holds for the surfaces and the ink, and it does not
      // hold for an accent used as running text. Straw and moss sit close to
      // the bone lightness, so in midday they fall to 1.89:1 and 2.49:1 on the
      // surface.
      //
      // The consequence is a usage rule rather than a palette change: an accent
      // is a fill, a stamp or a mark, never body ink, and status is carried by
      // the stamp and its label rather than by coloured text. The numbers are
      // pinned so that a future palette edit that quietly made an accent a text
      // colour is visible here.
      const straw = Color(0xFFC9A227);
      const moss = Color(0xFF6E9B72);
      expect(
        FieldColours.contrastWith(straw, FieldColours.sunlight.canopy),
        lessThan(3.0),
      );
      expect(
        FieldColours.contrastWith(moss, FieldColours.sunlight.canopy),
        lessThan(3.0),
      );
      // The same accents on the dark surface, where they were always legible.
      expect(
        FieldColours.contrastWith(straw, FieldColours.dark.canopy),
        greaterThan(4.5),
      );
      expect(
        FieldColours.contrastWith(moss, FieldColours.dark.canopy),
        greaterThan(4.5),
      );
    });
  });

  group('spacing and radii', () {
    test('spacing base is four', () {
      expect(Insets.base, 4);
      expect(Insets.xs % Insets.base, 0);
      for (final step in <double>[
        Insets.xs,
        Insets.sm,
        Insets.md,
        Insets.lg,
        Insets.xl,
        Insets.xxl,
        Insets.xxxl,
        Insets.huge,
        Insets.giant,
      ]) {
        expect(step % Insets.base, 0, reason: '$step is not a multiple of 4');
      }
    });

    test('radius is three, five and fourteen', () {
      expect(Corners.chip, 3);
      expect(Corners.control, 5);
      expect(Corners.sheet, 14);
    });
  });

  group('copyWith and lerp keep a palette usable', () {
    test('copyWith preserves the name and every unset colour', () {
      final copy = FieldColours.dark.copyWith(dust: const Color(0xFFFF0000));
      expect(copy.name, FieldColours.dark.name);
      expect(copy.dust, const Color(0xFFFF0000));
      expect(copy.bone, FieldColours.dark.bone);
      expect(copy.ruleStrong, FieldColours.dark.ruleStrong);
      expect(copy.brightness, FieldColours.dark.brightness);
    });

    test('lerp takes the far end name past the halfway point', () {
      final mid = FieldColours.dark.lerp(FieldColours.sunlight, 0.5);
      expect(mid.name, FieldColours.sunlight.name);
      final near = FieldColours.dark.lerp(FieldColours.sunlight, 0.25);
      expect(near.name, FieldColours.dark.name);
    });

    test(
      'lerp returns this palette when asked about an unrelated extension',
      () {
        expect(FieldColours.dark.lerp(null, 0.5), same(FieldColours.dark));
      },
    );
  });
}
