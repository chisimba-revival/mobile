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

    final appearance = _appearance();
    final fill = appearance.fill;
    final stroke = appearance.stroke;
    final hollow = appearance.hollow;
    final dashed = appearance.dashed;

    // Subtle shadow for presence — lifts the tab off the map.
    // Only for non-hollow states so deleted/ghost don't cast a shadow.
    if (!hollow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawPath(tab.shift(Offset(0, 1)), shadowPaint);
    }

    if (dashed) {
      // Flutter's Paint has no dash support, so the dashes have to be cut out
      // of the path itself. A dashed edge is the only cue that distinguishes a
      // change still on this phone from one the service has already refused,
      // and hue cannot carry it: both are straw.
      canvas.drawPath(
        _dashed(tab, dash: 2, gap: 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = stroke,
      );
    } else {
      if (!hollow) {
        canvas.drawPath(tab, Paint()..color = fill);
      }
      canvas.drawPath(
        tab,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hollow ? 1.5 : 1
          ..color = stroke,
      );
    }

    // The glyph sits in the body of the tab, above the notch, so the notch
    // corner stays clear.
    // A note is set in the book serif, as the design sets it: the words are the
    // record and the glyph stands in for them. An identified record is set in
    // the UI grotesque, because its glyph is a label rather than a placeholder.
    final note = visual.isNote;
    final glyphPainter = TextPainter(
      text: TextSpan(
        text: visual.glyph,
        style: TextStyle(
          fontFamily: note ? Faces.book.first : Faces.ui.first,
          fontSize: note ? 13 : (visual.glyph.length > 1 ? 10 : 12),
          fontWeight: note ? FontWeight.w400 : FontWeight.w600,
          height: 1,
          color: _glyphColour(visual.state, colours, isNote: note),
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

  PinAppearance _appearance() =>
      pinAppearanceFor(visual.state, colours, isNote: visual.isNote);

  @override
  bool shouldRepaint(PinPainter old) =>
      old.visual != visual ||
      old.colours != colours ||
      old.selected != selected;

  /// The glyph carries the state's accent, as the design draws it, rather than
  /// an ink chosen for contrast against the tab. The earlier colour was the
  /// palette's own near-black canopy, which is all but invisible on the dark
  /// tab and is exactly what made the pins read as black.
  Color _glyphColour(PinState state, FieldColours c, {required bool isNote}) {
    if (isNote) {
      return switch (state) {
        PinState.verified => c.moss,
        PinState.corrected => c.dust,
        _ => c.ash2,
      };
    }
    return switch (state) {
      PinState.unverified => c.straw,
      PinState.needsReview => c.straw,
      PinState.queued => c.straw,
      PinState.verified => c.moss,
      PinState.corrected => c.dust,
      PinState.deleted => c.ash2,
      PinState.ghost => c.bone,
    };
  }
}

/// How one state is drawn: which paint, and which shape cue carries the state
/// when hue cannot.
///
/// This is a value rather than a switch buried in the painter so that it can be
/// tested. The first version of this painter had [PinState.unverified],
/// [PinState.needsReview] and [PinState.queued] sharing a fill and a stroke, so
/// three of six states were drawn identically and nothing failed. Comparing
/// colours alone would not catch that, because the colours were equal on
/// purpose. What has to be checked is that no two states share a whole
/// appearance.
class PinAppearance {
  const PinAppearance({
    required this.fill,
    required this.stroke,
    required this.hollow,
    required this.dashed,
  });

  final Color fill;
  final Color stroke;

  /// Drawn as an outline with no interior. Deleted has to be: the record is
  /// gone and only where it was should remain. Needs review has to be for a
  /// different reason. Nobody having looked is a filled tab; somebody competent
  /// having looked and declined to decide is an open one. Contract rule 16 keeps
  /// those apart and no hue can, because both are straw.
  final bool hollow;

  /// Drawn with a broken edge. Only for queued: a change still on this phone is
  /// not yet a fact anywhere else, and the service may already have refused it.
  final bool dashed;

  /// The observable shape of this appearance, for comparing two states.
  String get signature => 'hollow=$hollow dashed=$dashed stroke=$stroke';
}

PinAppearance pinAppearanceFor(
  PinState state,
  FieldColours c, {
  bool isNote = false,
}) {
  // Deleted and ghost are structural: a tombstone is a tombstone whether or
  // not it ever had a name, and the ghost pin is a place, not a record. Both
  // override identification, so they are answered before the note rule.
  if (state == PinState.deleted) {
    return PinAppearance(
      fill: Colors.transparent,
      stroke: c.ash3,
      hollow: true,
      dashed: false,
    );
  }
  if (state == PinState.ghost) {
    // The design's ghost is the hollowest thing on the map: no fill, a bone
    // outline broken into dashes, so it reads as a place held open rather than
    // a record. The pulse animation in the widget carries the rest.
    return PinAppearance(
      fill: Colors.transparent,
      stroke: c.bone,
      hollow: true,
      dashed: true,
    );
  }

  // An unidentified record — a note — is drawn the way the design draws one:
  // a hollow tab with a broken edge in ash while it has no name, so it reads as
  // a question still open rather than a record of an animal. Once a mentor has
  // put a name to it, it fills with the moss wash like any verified record.
  if (isNote) {
    if (state == PinState.verified) {
      return PinAppearance(
        fill: c.moss.withValues(alpha: 0.28),
        stroke: c.moss,
        hollow: false,
        dashed: false,
      );
    }
    if (state == PinState.corrected) {
      return PinAppearance(
        fill: c.dust.withValues(alpha: 0.28),
        stroke: c.dust,
        hollow: false,
        dashed: false,
      );
    }
    return PinAppearance(
      fill: Colors.transparent,
      stroke: c.ash2,
      hollow: true,
      dashed: true,
    );
  }

  return switch (state) {
    // Filled and solid: nobody has looked at this yet. The fill is the raised
    // overlay surface the design uses, not the darker raised surface: on the
    // dark map the darker one reads as black, which buries the tab in the
    // ground instead of lifting it off.
    PinState.unverified => PinAppearance(
      fill: c.canopyOverlay,
      stroke: c.straw,
      hollow: false,
      dashed: false,
    ),
    // Filled but broken-edged. Same colour as unverified deliberately: what
    // differs is not the animal but whether the record has left the phone, and
    // a dashed edge says that where a second hue could not.
    PinState.queued => PinAppearance(
      fill: c.canopyOverlay,
      stroke: c.straw,
      hollow: false,
      dashed: true,
    ),
    // Open and solid: looked at, undecided.
    PinState.needsReview => PinAppearance(
      fill: c.canopyOverlay,
      stroke: c.straw,
      hollow: true,
      dashed: false,
    ),
    PinState.verified => PinAppearance(
      fill: c.moss.withValues(alpha: 0.28),
      stroke: c.moss,
      hollow: false,
      dashed: false,
    ),
    PinState.corrected => PinAppearance(
      fill: c.dust.withValues(alpha: 0.28),
      stroke: c.dust,
      hollow: false,
      dashed: false,
    ),
    // Unreachable: deleted and ghost are answered above, before this switch.
    // They are listed so the switch stays exhaustive without a default.
    PinState.deleted => PinAppearance(
      fill: Colors.transparent,
      stroke: c.ash3,
      hollow: true,
      dashed: false,
    ),
    PinState.ghost => PinAppearance(
      fill: Colors.transparent,
      stroke: c.bone,
      hollow: true,
      dashed: true,
    ),
  };
}

/// Cuts a path into dashes of [dash] followed by gaps of [gap].
Path _dashed(Path source, {required double dash, required double gap}) {
  final out = Path();
  for (final metric in source.computeMetrics(forceClosed: true)) {
    var distance = 0.0;
    var draw = true;
    while (distance < metric.length) {
      final length = draw ? dash : gap;
      final end = (distance + length).clamp(0.0, metric.length);
      if (draw) {
        out.addPath(metric.extractPath(distance, end), Offset.zero);
      }
      distance = end;
      draw = !draw;
    }
  }
  return out;
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
