import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_painter.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests exist because the first version of the painter gave
/// [PinState.unverified], [PinState.needsReview] and [PinState.queued] the same
/// fill and the same stroke. Three of six states then rendered as the same shape
/// in the same colour, and nothing failed.
///
/// A palette comparison would not have caught it, because the palettes were the
/// same on purpose. The states are told apart by shape and by edge, which is the
/// point: an accent is a fill, and a hue cannot be the only cue when the design
/// has already established that an accent is not legible as text.
///
/// Note this reads [pinAppearanceFor], a pure value, rather than rasterising the
/// painter. An earlier attempt painted to a `ui.PictureRecorder` and read the
/// pixels back inside `testWidgets`; `toImage` never completed under the fake
/// async zone, so the test hung for five minutes and then failed on a stream
/// error that said nothing about the pin. The decision is the thing worth
/// testing, and it is reachable without a rasteriser.
void main() {
  final colours = FieldColours.dark;

  PinAppearance of(PinState state) => pinAppearanceFor(state, colours);

  group('no two pin states are drawn identically', () {
    test('every state has its own appearance', () {
      final seen = <String, PinState>{};
      for (final state in PinState.values) {
        final signature = of(state).signature;
        expect(
          seen.containsKey(signature),
          isFalse,
          reason:
              '${state.name} is drawn exactly as ${seen[signature]} was, so '
              'nothing on the map would tell them apart',
        );
        seen[signature] = state;
      }
      expect(seen.length, PinState.values.length);
    });

    test('the three that used to collide are now distinct', () {
      final unverified = of(PinState.unverified);
      final queued = of(PinState.queued);
      final needsReview = of(PinState.needsReview);

      expect(
        {unverified.signature, queued.signature, needsReview.signature}.length,
        3,
      );
    });
  });

  group('state is carried by shape as well as colour', () {
    test('unverified is a filled, solid tab', () {
      final appearance = of(PinState.unverified);
      expect(appearance.hollow, isFalse);
      expect(appearance.dashed, isFalse);
    });

    test('queued is dashed, because the record has not been sent', () {
      final appearance = of(PinState.queued);
      expect(
        appearance.dashed,
        isTrue,
        reason:
            'a dashed edge is the only cue that separates still-queued '
            'from refused, and both are straw',
      );
      expect(appearance.hollow, isFalse);
    });

    test('needs review is open, because somebody has looked', () {
      final appearance = of(PinState.needsReview);
      expect(
        appearance.hollow,
        isTrue,
        reason: 'filled says nobody looked, which is pending, not needs review',
      );
      expect(appearance.dashed, isFalse);
    });

    test('deleted is open', () {
      expect(of(PinState.deleted).hollow, isTrue);
    });

    test('verified and corrected are both filled and solid', () {
      for (final state in [PinState.verified, PinState.corrected]) {
        expect(of(state).hollow, isFalse, reason: '$state');
        expect(of(state).dashed, isFalse, reason: '$state');
      }
    });
  });

  group('the appearance follows the palette, not a baked colour', () {
    test('verified is moss and corrected is dust in both palettes', () {
      for (final palette in [FieldColours.dark, FieldColours.sunlight]) {
        expect(
          pinAppearanceFor(PinState.verified, palette).stroke,
          palette.moss,
          reason: 'verified is moss whichever way the light is',
        );
        expect(
          pinAppearanceFor(PinState.corrected, palette).stroke,
          palette.dust,
        );
      }
    });

    test('the shape cues do not depend on the palette at all', () {
      for (final palette in [FieldColours.dark, FieldColours.sunlight]) {
        for (final state in PinState.values) {
          final dark = pinAppearanceFor(state, FieldColours.dark);
          final sun = pinAppearanceFor(state, palette);
          expect(sun.hollow, dark.hollow, reason: '$state hollow in sunlight');
          expect(sun.dashed, dark.dashed, reason: '$state dashed in sunlight');
        }
      }
    });
  });

  group('the tab', () {
    test('is a rectangle with one corner notched off', () {
      final path = tabPath(0, 0, 22, 27, 7);

      // Three corners survive. Note contains() is true for a point on the
      // boundary, so these are vertices, not interior probes.
      expect(path.contains(const Offset(0, 0)), isTrue, reason: 'top left');
      expect(path.contains(const Offset(22, 0)), isTrue, reason: 'top right');
      expect(
        path.contains(const Offset(22, 27)),
        isTrue,
        reason: 'bottom right',
      );
      expect(
        path.contains(const Offset(7, 27)),
        isTrue,
        reason: 'the bottom edge stops short of the corner by the notch',
      );
      expect(
        path.contains(const Offset(0, 20)),
        isTrue,
        reason: 'the notch begins 7 above the bottom on the left edge',
      );
      // The fourth corner is cut away, which is the whole point of the shape: a
      // pin looks like a card corner pulled out of the logbook.
      expect(path.contains(const Offset(0, 27)), isFalse);
    });

    test('is the size the painter draws it at', () {
      expect(
        tabPath(
          0,
          0,
          PinPainter.tabWidth,
          PinPainter.tabHeight,
          PinPainter.notch,
        ).getBounds(),
        const Rect.fromLTRB(0, 0, 22, 27),
      );
    });
  });

  group('the reserve vector layer', () {
    testWidgets('paints with no tile behind it', (tester) async {
      // This layer is what remains when no tile can be fetched, which is the
      // situation the app is designed around. It has to paint on its own terms.
      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            painter: ReserveVectorPainter(colours: colours),
            size: const Size(400, 400),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
