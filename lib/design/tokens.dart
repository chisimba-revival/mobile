import 'package:flutter/material.dart';

/// The reserve vocabulary, from `chisimba-info/docs/mobile-design/README.md`.
///
/// Tokens are named from the reserve rather than from a UI library, so that
/// reading the stylesheet tells you what the product is. The values below are
/// transcribed from the design's token table and are locked by
/// `test/design/tokens_test.dart`, which fails if a value is changed without
/// the design document being changed with it.
///
/// Where the design specifies a value by derivation rather than as a literal,
/// the derivation is recorded in the doc comment for that token so the number
/// can be re-derived rather than trusted.
abstract final class Insets {
  /// Spacing base is 4px.
  static const double base = 4;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;
}

/// Radius is 3, 5 and 14px. Clipped, not pills.
abstract final class Corners {
  /// Chips and inline marks.
  static const double chip = 3;

  /// Controls and fields.
  static const double control = 5;

  /// Sheets and cards.
  static const double sheet = 14;
}

/// Ink and surface colours for one brightness.
@immutable
class FieldColours extends ThemeExtension<FieldColours> {
  const FieldColours({
    required this.canopy,
    required this.canopyRaised,
    required this.canopyOverlay,
    required this.inset,
    required this.bone,
    required this.ash1,
    required this.ash2,
    required this.ash3,
    required this.ash4,
    required this.dust,
    required this.straw,
    required this.moss,
    required this.blood,
    required this.ruleFaint,
    required this.rule,
    required this.ruleStrong,
    required this.name,
    required this.brightness,
  });

  /// Identifies this set in a [ThemeExtension] list and in a test failure.
  final String name;

  /// Base surface.
  final Color canopy;

  /// Raised surface.
  final Color canopyRaised;

  /// Overlay surface.
  final Color canopyOverlay;

  /// Input fill. Darker than its surroundings, because inputs receive content.
  final Color inset;

  /// Primary text.
  final Color bone;

  /// Secondary text, strongest of four levels.
  final Color ash1;

  /// Secondary text.
  final Color ash2;

  /// Muted text.
  final Color ash3;

  /// Muted text, most distant.
  final Color ash4;

  /// Single accent, laterite earth.
  final Color dust;

  /// Pending.
  final Color straw;

  /// Verified.
  final Color moss;

  /// Rejected.
  final Color blood;

  /// Border progression, three steps: faint, default, strong.
  final Color ruleFaint;
  final Color rule;
  final Color ruleStrong;

  /// Which brightness this set describes. Carried so that a widget can choose
  /// an appropriate ink on an accent without a second lookup table.
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  /// Ink to place on top of an accent fill.
  ///
  /// The design's stated reason for the sunlight inversion is that one hue is
  /// held and only lightness shifts, so nothing re-tints and no contrast pair
  /// needs re-deriving. That holds for the surfaces and the ink, but it does
  /// not extend to the accents used as text: moss on the light bone surface
  /// measures 2.49:1, and the same token is 4.6:1 on the dark one. Keeping the
  /// accent hues identical and still being legible therefore requires choosing
  /// the ink on the accent per palette, which is what this does.
  ///
  /// Measured rather than switched on [isDark], so a future accent is not
  /// silently given the wrong ink.
  Color inkOn(Color accent) {
    return contrastWith(bone, accent) >= contrastWith(canopy, accent)
        ? bone
        : canopy;
  }

  /// WCAG relative-luminance contrast ratio between two opaque colours.
  static double contrastWith(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    final lighter = first > second ? first : second;
    final darker = first > second ? second : first;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Dark first, and this is a field decision.
  ///
  /// The work happens at first light when the big cats are active, and a white
  /// screen at 05:40 blinds. So the base theme is dark, and the sunlight set
  /// exists for midday.
  static const FieldColours dark = FieldColours(
    name: 'canopy',
    canopy: Color(0xFF111E19),
    canopyRaised: Color(0xFF172722),
    canopyOverlay: Color(0xFF1E312A),
    inset: Color(0xFF0C1613),
    bone: Color(0xFFE9E3D7),
    // The design gives ash as "secondary and muted text, four levels" without
    // four literals, so the levels are bone over canopy at 85, 65, 45 and 28
    // per cent. One hue, lightness only.
    ash1: Color(0xFFC9C5BA),
    ash2: Color(0xFF9D9E94),
    ash3: Color(0xFF72776E),
    ash4: Color(0xFF4D554E),
    dust: Color(0xFFC4612F),
    straw: Color(0xFFC9A227),
    moss: Color(0xFF6E9B72),
    blood: Color(0xFFA8452F),
    // rule is bone at 9, 16 and 30 per cent over the base surface.
    ruleFaint: Color(0xFF24302A),
    rule: Color(0xFF343E37),
    ruleStrong: Color(0xFF525952),
    brightness: Brightness.dark,
  );

  /// Midday. The same hues inverted: one hue, lightness shifts only, so
  /// nothing re-tints and no contrast pair needs re-deriving.
  static const FieldColours sunlight = FieldColours(
    name: 'sunlight',
    canopy: Color(0xFFE9E3D7),
    canopyRaised: Color(0xFFE0DBCF),
    canopyOverlay: Color(0xFFD1CDC2),
    // An input still receives content, so it stays the darker end of the
    // surface range even when that is no longer the dark end.
    inset: Color(0xFFC6C3B9),
    bone: Color(0xFF111E19),
    // canopy over bone at 84, 64, 42 and 20 per cent, strongest first.
    ash1: Color(0xFF343E37),
    ash2: Color(0xFF5F655D),
    ash3: Color(0xFF8E9087),
    ash4: Color(0xFFBEBCB1),
    dust: Color(0xFFC4612F),
    straw: Color(0xFFC9A227),
    moss: Color(0xFF6E9B72),
    blood: Color(0xFFA8452F),
    // canopy over bone at 12, 20 and 30 per cent.
    ruleFaint: Color(0xFFCFCBC0),
    rule: Color(0xFFBEBCB1),
    ruleStrong: Color(0xFFA8A89E),
    brightness: Brightness.light,
  );

  @override
  FieldColours copyWith({
    Color? canopy,
    Color? canopyRaised,
    Color? canopyOverlay,
    Color? inset,
    Color? bone,
    Color? ash1,
    Color? ash2,
    Color? ash3,
    Color? ash4,
    Color? dust,
    Color? straw,
    Color? moss,
    Color? blood,
    Color? ruleFaint,
    Color? rule,
    Color? ruleStrong,
    Brightness? brightness,
  }) {
    return FieldColours(
      name: name,
      canopy: canopy ?? this.canopy,
      canopyRaised: canopyRaised ?? this.canopyRaised,
      canopyOverlay: canopyOverlay ?? this.canopyOverlay,
      inset: inset ?? this.inset,
      bone: bone ?? this.bone,
      ash1: ash1 ?? this.ash1,
      ash2: ash2 ?? this.ash2,
      ash3: ash3 ?? this.ash3,
      ash4: ash4 ?? this.ash4,
      dust: dust ?? this.dust,
      straw: straw ?? this.straw,
      moss: moss ?? this.moss,
      blood: blood ?? this.blood,
      ruleFaint: ruleFaint ?? this.ruleFaint,
      rule: rule ?? this.rule,
      ruleStrong: ruleStrong ?? this.ruleStrong,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  FieldColours lerp(ThemeExtension<FieldColours>? other, double t) {
    if (other is! FieldColours) {
      return this;
    }
    return FieldColours(
      name: t < 0.5 ? name : other.name,
      canopy: Color.lerp(canopy, other.canopy, t)!,
      canopyRaised: Color.lerp(canopyRaised, other.canopyRaised, t)!,
      canopyOverlay: Color.lerp(canopyOverlay, other.canopyOverlay, t)!,
      inset: Color.lerp(inset, other.inset, t)!,
      bone: Color.lerp(bone, other.bone, t)!,
      ash1: Color.lerp(ash1, other.ash1, t)!,
      ash2: Color.lerp(ash2, other.ash2, t)!,
      ash3: Color.lerp(ash3, other.ash3, t)!,
      ash4: Color.lerp(ash4, other.ash4, t)!,
      dust: Color.lerp(dust, other.dust, t)!,
      straw: Color.lerp(straw, other.straw, t)!,
      moss: Color.lerp(moss, other.moss, t)!,
      blood: Color.lerp(blood, other.blood, t)!,
      ruleFaint: Color.lerp(ruleFaint, other.ruleFaint, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ruleStrong: Color.lerp(ruleStrong, other.ruleStrong, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// Type pairs a logbook serif for recorded values with the system grotesque
/// for chrome, because a handwritten log and a printed form should not look
/// like they came from the same template.
///
/// Neither family is bundled in this slice. The stacks are declared so that a
/// screen can express the intent from its first commit, and so that bundling
/// the serif later is a one-line change rather than a sweep. On a device
/// without Iowan Old Style the stack degrades to the platform serif, which is
/// the intended behaviour rather than a fallback to the chrome face.
abstract final class Faces {
  /// Recorded values: what the trainee wrote, and what a mentor corrected.
  static const List<String> book = <String>[
    'Iowan Old Style',
    'Palatino',
    'Georgia',
    'serif',
  ];

  /// Chrome: labels, counters, controls.
  static const List<String> ui = <String>['Roboto', 'Noto Sans', 'sans-serif'];

  /// Size of a recorded sentence. The design requires that a note be set "at
  /// the size a sentence deserves", so this is the largest type in the app and
  /// is deliberately not a body size.
  static const double noteBody = 20;

  /// Body text.
  static const double body = 16;

  /// Control labels.
  static const double label = 14;

  /// Supporting and muted text.
  static const double supporting = 13;

  /// Field card headers.
  static const double cardTitle = 18;

  /// Stamps and status marks.
  static const double stamp = 12;
}
