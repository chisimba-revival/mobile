import 'package:field_log/design/tokens.dart';
import 'package:field_log/map/pin_visual.dart';
import 'package:flutter/material.dart';

/// The path of a field-card tab: a rectangle with one corner notched off.
///
/// This is the design's signature shape. The notch is not decoration, it is the
/// point: a pin looks like a card corner pulled out of the logbook, which is
/// what makes a record feel like a page rather than a dot on a map.
///
/// The tab's baseline is its bottom edge, so the point sits on the position
/// rather than floating above it.
Path tabPath(double x, double y, double w, double h, double notch) {
  return Path()
    ..moveTo(x, y)
    ..lineTo(x + w, y)
    ..lineTo(x + w, y + h)
    ..lineTo(x + notch, y + h)
    ..lineTo(x, y + h - notch)
    ..close();
}

/// Draws one observation as its tab.
class PinPainter extends CustomPainter {
  PinPainter({
    required this.visual,
    required this.colours,
    required this.selected,
  });

  final PinVisual visual;
  final FieldColours colours;
  final bool selected;

  static const double tabWidth = 22;
  static const double tabHeight = 27;
  static const double notch = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2 - tabWidth / 2;
    final y = size.height - tabHeight;
    final tab = tabPath(x, y, tabWidth, tabHeight, notch);

    // The selection ring is a larger tab behind the one being drawn, which is
    // how the design marks a selection: not a circle around a shape, but the
    // same shape at a larger size.
    if (selected) {
      canvas.drawPath(
        tabPath(x - 3, y - 3, tabWidth + 6, tabHeight + 6, notch + 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = colours.bone,
      );
    }

    final fill = _fillFor(visual.state, colours);
    final stroke = _strokeFor(visual.state, colours);
    final deleted = visual.state == PinState.deleted;

    canvas.drawPath(
      tab,
      Paint()
        ..style = deleted ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 1
        ..color = deleted ? stroke : fill,
    );

    // The glyph sits in the body of the tab, above the notch, so the notch
    // corner stays clear.
    final glyphPainter = TextPainter(
      text: TextSpan(
        text: visual.glyph,
        style: TextStyle(
          fontFamily: Faces.book.first,
          fontSize: visual.glyph.length > 1 ? 11 : 14,
          height: 1,
          color: _glyphColour(visual.state, colours, deleted),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyphPainter.paint(
      canvas,
      Offset(
        size.width / 2 - glyphPainter.width / 2,
        y + (tabHeight - notch) / 2 - glyphPainter.height / 2 + 1,
      ),
    );
  }

  Color _fillFor(PinState state, FieldColours c) => switch (state) {
    PinState.unverified || PinState.needsReview => c.canopyRaised,
    PinState.queued => c.canopyRaised,
    PinState.verified => c.moss.withValues(alpha: 0.18),
    PinState.corrected => c.dust.withValues(alpha: 0.18),
    PinState.deleted => Colors.transparent,
  };

  Color _strokeFor(PinState state, FieldColours c) => switch (state) {
    PinState.unverified => c.straw,
    PinState.needsReview => c.straw,
    PinState.queued => c.straw,
    PinState.verified => c.moss,
    PinState.corrected => c.dust,
    PinState.deleted => c.ash3,
  };

  @override
  bool shouldRepaint(PinPainter old) =>
      old.visual != visual ||
      old.colours != colours ||
      old.selected != selected;

  Color _glyphColour(PinState state, FieldColours c, bool deleted) =>
      switch (state) {
        PinState.unverified => c.inkOn(c.straw),
        PinState.needsReview => c.inkOn(c.straw),
        PinState.queued => c.inkOn(c.straw),
        PinState.verified => c.inkOn(c.moss),
        PinState.corrected => c.inkOn(c.dust),
        PinState.deleted => c.ash2,
      };
}

/// A pin that carries a count gets a small badge on its shoulder, because the
/// glyph and the badge are read at different distances on a phone held at
/// arm's length in a vehicle.
class CountBadgePainter extends CustomPainter {
  CountBadgePainter({required this.count, required this.colours});

  final int count;
  final FieldColours colours;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(centre, radius, Paint()..color = colours.dust);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colours.canopy,
    );

    final text = TextPainter(
      text: TextSpan(
        text: '$count',
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
          color: colours.inkOn(colours.dust),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      Offset(centre.dx - text.width / 2, centre.dy - text.height / 2),
    );
  }

  @override
  bool shouldRepaint(CountBadgePainter old) =>
      old.count != count || old.colours != colours;
}

/// Draws the reserve's own contours, water and track.
///
/// These are not a decorative background. They are what remains when a tile
/// cannot be fetched, which is the situation the app is designed around, so
/// they have to carry the shape of the ground on their own. The tile layer
/// above them paints a transparent square wherever it has nothing, and the
/// vector layer shows through exactly there.
class ReserveVectorPainter extends CustomPainter {
  ReserveVectorPainter({required this.colours});

  final FieldColours colours;

  /// Contour bands, drawn as nested offsets from the centre. Deliberately
  /// regular: this is a placeholder for surveyed contours, and its job is to
  /// make the ground legible without a tile, not to pretend to be the ground.
  static const int _contours = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);

    for (var i = _contours; i >= 1; i--) {
      final radius = size.shortestSide * 0.07 * i;
      final major = i.isEven;
      canvas.drawPath(
        _contour(centre, radius, i),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = major ? 1.2 : 0.8
          ..color = major ? colours.ruleStrong : colours.rule,
      );
    }

    // The waterhole. A map without water is not a map of a reserve.
    canvas.drawCircle(
      Offset(centre.dx - size.width * 0.12, centre.dy + size.height * 0.08),
      size.shortestSide * 0.055,
      Paint()..color = colours.canopyOverlay,
    );
    canvas.drawCircle(
      Offset(centre.dx - size.width * 0.12, centre.dy + size.height * 0.08),
      size.shortestSide * 0.055,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colours.ruleStrong,
    );
  }

  /// A closed loop with a deterministic wobble, so the same contour looks the
  /// same on every frame and does not shimmer as the map pans.
  Path _contour(Offset centre, double radius, int seed) {
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * 3.141592653589793;
      final wobble =
          1 + 0.06 * _wave(angle * 2, seed) + 0.04 * _wave(angle * 3, seed + 2);
      final point = Offset(
        centre.dx + radius * wobble * _cos(angle),
        centre.dy + radius * wobble * 0.78 * _sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  double _wave(double angle, int seed) => _sin(angle + seed) * 0.5 + 0.5;

  double _sin(double a) => _mathSin(a);
  double _cos(double a) => _mathCos(a);

  @override
  bool shouldRepaint(ReserveVectorPainter old) => old.colours != colours;
}

double _mathSin(double a) {
  final x = a % (2 * 3.141592653589793);
  // A small polynomial is enough here and avoids importing dart:math into a
  // file that otherwise only draws.
  var term = x;
  var sum = x;
  for (var i = 1; i < 6; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    sum += term;
  }
  return sum;
}

double _mathCos(double a) => _mathSin(a + 3.141592653589793 / 2);
