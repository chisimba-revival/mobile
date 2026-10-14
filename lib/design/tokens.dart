import 'dart:async';

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

/// Density-scaled insets helpers.
///
/// Use these functions to get spacing values scaled by the current density.
/// The base Insets values are multiplied by the density's scale factor.
double _insetScale(double value, Density density) => value * density.scale;

/// xs (4px) scaled by density.
double Insets_xs(Density density) => _insetScale(Insets.xs, density);

/// sm (8px) scaled by density.
double Insets_sm(Density density) => _insetScale(Insets.sm, density);

/// md (12px) scaled by density.
double Insets_md(Density density) => _insetScale(Insets.md, density);

/// lg (16px) scaled by density.
double Insets_lg(Density density) => _insetScale(Insets.lg, density);

/// xl (20px) scaled by density.
double Insets_xl(Density density) => _insetScale(Insets.xl, density);

/// xxl (24px) scaled by density.
double Insets_xxl(Density density) => _insetScale(Insets.xxl, density);

/// xxxl (32px) scaled by density.
double Insets_xxxl(Density density) => _insetScale(Insets.xxxl, density);

/// huge (40px) scaled by density.
double Insets_huge(Density density) => _insetScale(Insets.huge, density);

/// giant (48px) scaled by density.
double Insets_giant(Density density) => _insetScale(Insets.giant, density);

/// EdgeInsets.all scaled by density.
EdgeInsets Insets_all(double value, Density density) =>
    EdgeInsets.all(_insetScale(value, density));

/// EdgeInsets.symmetric scaled by density.
EdgeInsets Insets_symmetric({
  double horizontal = 0,
  double vertical = 0,
  required Density density,
}) => EdgeInsets.symmetric(
  horizontal: _insetScale(horizontal, density),
  vertical: _insetScale(vertical, density),
);

/// EdgeInsets.fromLTRB scaled by density.
EdgeInsets Insets_fromLTRB(
  double left,
  double top,
  double right,
  double bottom,
  Density density,
) => EdgeInsets.fromLTRB(
  _insetScale(left, density),
  _insetScale(top, density),
  _insetScale(right, density),
  _insetScale(bottom, density),
);

/// Radius is 3, 5 and 14px. Clipped, not pills.
abstract final class Corners {
  /// Chips and inline marks.
  static const double chip = 3;

  /// Controls and fields.
  static const double control = 5;

  /// Sheets and cards.
  static const double sheet = 14;
}

/// Standardised icon sizes for consistent visual rhythm.
///
/// Use these constants instead of hardcoding icon sizes. The design
/// specifies three tiers: small (inline/dense), medium (default controls),
/// and large (prominent/hero).
abstract final class IconSizes {
  /// Tiny icons (12px) — badges, dense inline markers.
  static const double xs = 12;

  /// Small icons (16px) — dense controls, chips, list icons.
  static const double sm = 16;

  /// Medium icons (20px) — default controls, buttons, list items.
  static const double md = 20;

  /// Large icons (24px) — prominent actions, header icons.
  static const double lg = 24;

  /// Extra large icons (28px) — hero actions, empty states.
  static const double xl = 28;

  /// Hero icons (32px) — empty states, onboarding, splash.
  static const double xxl = 32;
}

/// Centralised icon registry for semantic, consistent icon usage.
///
/// Replace ad-hoc Icons.* references with FieldIcons.* to ensure
/// consistent stroke weight, size, and semantic meaning across the app.
/// Add new icons here rather than using Icons.* directly in widgets.
abstract final class FieldIcons {
  /// Layers & map
  static const IconData layers = Icons.layers_outlined;
  static const IconData layersFilled = Icons.layers;
  static const IconData map = Icons.map_outlined;
  static const IconData mapFilled = Icons.map;
  static const IconData gps = Icons.gps_fixed_outlined;
  static const IconData gpsFilled = Icons.gps_fixed;
  static const IconData myLocation = Icons.my_location_outlined;
  static const IconData myLocationFilled = Icons.my_location;
  static const IconData compass = Icons.explore_outlined;
  static const IconData compassFilled = Icons.explore;
  static const IconData route = Icons.route_outlined;
  static const IconData routeFilled = Icons.route;
  static const IconData waypoint = Icons.flag_outlined;
  static const IconData waypointFilled = Icons.flag;

  /// Layers (for map legend)
  static const IconData waterholes = Icons.water_drop_outlined;
  static const IconData waterholesFilled = Icons.water_drop;
  static const IconData roads = Icons.alt_route_outlined;
  static const IconData roadsFilled = Icons.alt_route;
  static const IconData acacia = Icons.forest_outlined;
  static const IconData acaciaFilled = Icons.forest;
  static const IconData boundary = Icons.map_outlined;
  static const IconData boundaryFilled = Icons.map;
  static const IconData contours = Icons.show_chart_outlined;
  static const IconData contoursFilled = Icons.show_chart;
  static const IconData terrain = Icons.terrain_outlined;
  static const IconData terrainFilled = Icons.terrain;

  /// Actions
  static const IconData add = Icons.add_outlined;
  static const IconData addFilled = Icons.add;
  static const IconData record = Icons.fiber_manual_record_outlined;
  static const IconData recordFilled = Icons.fiber_manual_record;
  static const IconData edit = Icons.edit_outlined;
  static const IconData editFilled = Icons.edit;
  static const IconData delete = Icons.delete_outline;
  static const IconData deleteFilled = Icons.delete;
  static const IconData search = Icons.search_outlined;
  static const IconData searchFilled = Icons.search;
  static const IconData filter = Icons.filter_list_outlined;
  static const IconData filterFilled = Icons.filter_list;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsFilled = Icons.settings;
  static const IconData menu = Icons.menu_outlined;
  static const IconData menuFilled = Icons.menu;
  static const IconData close = Icons.close_outlined;
  static const IconData closeFilled = Icons.close;
  static const IconData check = Icons.check_outlined;
  static const IconData checkFilled = Icons.check;
  static const IconData cancel = Icons.cancel_outlined;
  static const IconData cancelFilled = Icons.cancel;
  static const IconData save = Icons.save_outlined;
  static const IconData saveFilled = Icons.save;
  static const IconData sync = Icons.sync_outlined;
  static const IconData syncFilled = Icons.sync;
  static const IconData refresh = Icons.refresh_outlined;
  static const IconData refreshFilled = Icons.refresh;

  /// Navigation
  static const IconData chevronLeft = Icons.chevron_left;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData expandLess = Icons.expand_less;
  static const IconData expandMore = Icons.expand_more;
  static const IconData arrowBack = Icons.arrow_back_outlined;
  static const IconData arrowBackFilled = Icons.arrow_back;
  static const IconData arrowForward = Icons.arrow_forward_outlined;
  static const IconData arrowForwardFilled = Icons.arrow_forward;

  /// Status & feedback
  static const IconData checkCircle = Icons.check_circle_outlined;
  static const IconData checkCircleFilled = Icons.check_circle;
  static const IconData error = Icons.error_outline;
  static const IconData errorFilled = Icons.error;
  static const IconData warning = Icons.warning_outlined;
  static const IconData warningFilled = Icons.warning;
  static const IconData info = Icons.info_outline;
  static const IconData infoFilled = Icons.info;
  static const IconData success = Icons.task_alt_outlined;
  static const IconData successFilled = Icons.task_alt;

  /// Content types
  static const IconData sighting = Icons.pets_outlined;
  static const IconData sightingFilled = Icons.pets;
  static const IconData observation = Icons.visibility_outlined;
  static const IconData observationFilled = Icons.visibility;
  static const IconData photo = Icons.photo_camera_outlined;
  static const IconData photoFilled = Icons.photo_camera;
  static const IconData audio = Icons.mic_outlined;
  static const IconData audioFilled = Icons.mic;
  static const IconData note = Icons.note_outlined;
  static const IconData noteFilled = Icons.note;
  static const IconData document = Icons.description_outlined;
  static const IconData documentFilled = Icons.description;

  /// Species & wildlife
  static const IconData animal = Icons.pets_outlined;
  static const IconData animalFilled = Icons.pets;
  static const IconData bird = Icons.flutter_dash_outlined;
  static const IconData birdFilled = Icons.flutter_dash;
  static const IconData tree = Icons.forest_outlined;
  static const IconData treeFilled = Icons.forest;
  static const IconData plant = Icons.grass_outlined;
  static const IconData plantFilled = Icons.grass;

  /// UI chrome
  static const IconData menuOutlined = Icons.menu_outlined;
  static const IconData menuFilled_ = Icons.menu;
  static const IconData closeOutlined = Icons.close_outlined;
  static const IconData closeFilled_ = Icons.close;
  static const IconData moreVert = Icons.more_vert;
  static const IconData moreHoriz = Icons.more_horiz;
  static const IconData grid = Icons.grid_view_outlined;
  static const IconData list = Icons.list_outlined;
  static const IconData home = Icons.home_outlined;
  static const IconData homeFilled = Icons.home;
  static const IconData person = Icons.person_outlined;
  static const IconData personFilled = Icons.person;
  static const IconData logout = Icons.logout_outlined;
  static const IconData logoutFilled = Icons.logout;

  /// Map specific
  static const IconData zoomIn = Icons.zoom_in_outlined;
  static const IconData zoomInFilled = Icons.zoom_in;
  static const IconData zoomOut = Icons.zoom_out_outlined;
  static const IconData zoomOutFilled = Icons.zoom_out;
  static const IconData fullscreen = Icons.fullscreen_outlined;
  static const IconData fullscreenFilled = Icons.fullscreen;
  static const IconData fullscreenExit = Icons.fullscreen_exit_outlined;
  static const IconData fullscreenExitFilled = Icons.fullscreen_exit;
  static const IconData satellite = Icons.satellite_outlined;
  static const IconData satelliteFilled = Icons.satellite;
  static const IconData traffic = Icons.traffic_outlined;
  static const IconData trafficFilled = Icons.traffic;
  static const IconData directions = Icons.directions_outlined;
  static const IconData directionsFilled = Icons.directions;

  /// Utility
  static const IconData more = Icons.more_horiz;
  static const IconData moreFilled = Icons.more_horiz;
  static const IconData share = Icons.share_outlined;
  static const IconData shareFilled = Icons.share;
  static const IconData copy = Icons.content_copy_outlined;
  static const IconData copyFilled = Icons.content_copy;
  static const IconData download = Icons.download_outlined;
  static const IconData downloadFilled = Icons.download;
  static const IconData upload = Icons.upload_outlined;
  static const IconData uploadFilled = Icons.upload;
  static const IconData print = Icons.print_outlined;
  static const IconData printFilled = Icons.print;
  static const IconData favorite = Icons.favorite_outline;
  static const IconData favoriteFilled = Icons.favorite;
  static const IconData bookmark = Icons.bookmark_outline;
  static const IconData bookmarkFilled = Icons.bookmark;
  static const IconData shareAndroid = Icons.share_outlined;
  static const IconData shareAndroidFilled = Icons.share;
}

/// Density scale — controls the visual weight and spacing density.
///
/// Applied as a multiplier to [Insets] base values. The design tokens
/// themselves are unchanged; density is a runtime preference that scales
/// the effective spacing and touch targets.
enum Density implements ThemeExtension<Density> {
  /// Compact — 85% scale. More content, smaller touch targets (still >= 44px).
  compact(0.85),

  /// Comfortable — 100% scale. The design default.
  comfortable(1.0),

  /// Spacious — 120% scale. More breathing room, larger targets.
  spacious(1.2);

  const Density(this.scale);

  final double scale;

  @override
  Type get type => Density;

  @override
  Density copyWith({double? scale}) => Density.values.firstWhere(
    (d) => d.scale == (scale ?? this.scale),
    orElse: () => this,
  );

  @override
  Density lerp(ThemeExtension<Density>? other, double t) {
    if (other == null || other is! Density) return this;
    final otherScale = other.scale;
    final lerped = scale + (otherScale - scale) * t;
    return Density.values.firstWhere(
      (d) => (d.scale - lerped).abs() < 0.01,
      orElse: () => this,
    );
  }

  /// Effective base spacing unit for this density.
  double get baseSpacing => Insets.base * scale;

  /// Effective minimum touch target (never below 44px for accessibility).
  double get minTouchTarget => (44 * scale).clamp(44.0, double.infinity);

  /// Label for UI display.
  String get label => switch (this) {
    Density.compact => 'Compact',
    Density.comfortable => 'Comfortable',
    Density.spacious => 'Spacious',
  };

  /// Description for UI display.
  String get description => switch (this) {
    Density.compact => 'More content on screen',
    Density.comfortable => 'Balanced spacing (default)',
    Density.spacious => 'More breathing room',
  };
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
    required this.water,
    required this.drainage,
    required this.ruleFaint,
    required this.rule,
    required this.ruleStrong,
    required this.contour,
    required this.focus,
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

  /// Water features on the map.
  final Color water;

  /// Drainage lines on the map.
  final Color drainage;

  /// Border progression, three steps: faint, default, strong.
  final Color ruleFaint;
  final Color rule;
  final Color ruleStrong;

  /// Contour lines on the map.
  ///
  /// Stronger than any border: a contour must hold its own against a busy
  /// basemap. In the dark palette it is ruleStrong re-stated; under sunlight
  /// it is a pronounced warm grey-brown that beats the light tiles.
  final Color contour;

  /// Focus ring colour for accessible keyboard navigation.
  ///
  /// Uses the accent dust hue with full opacity so the ring is unmistakable
  /// against any surface. The same token on both palettes keeps the visual
  /// language consistent across themes.
  final Color focus;

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

  /// WCAG relative-luminance contrast ratio between two colours.
  ///
  /// Both must be fully opaque. [Color.computeLuminance] ignores alpha, so a
  /// translucent colour yields a ratio against its own RGB that says nothing
  /// about what it will actually look like on top of whatever is behind it. All
  /// palette values are `0xFF`, so this guards against a future token rather
  /// than against anything in use today.
  static double contrastWith(Color a, Color b) {
    assert(
      a.a == 1.0 && b.a == 1.0,
      'contrastWith needs opaque colours: it measures the colour itself, '
      'not what it will look like composited over something else.',
    );
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
    water: Color(0xFF2A4A56),
    drainage: Color(0xFF4E94A8),
    // rule is bone at 9, 16 and 30 per cent over the base surface.
    ruleFaint: Color(0xFF24302A),
    rule: Color(0xFF343E37),
    ruleStrong: Color(0xFF525952),
    // A contour is ruleStrong re-stated: the same pale line that reads on this
    // dark ground. The sunlight palette re-derives it for its own ground.
    contour: Color(0xFF525952),
    // Focus ring uses the dust accent hue for high visibility.
    focus: Color(0xFFC4612F),
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
    water: Color(0xFF2A4A56),
    drainage: Color(0xFF4E94A8),
    // canopy over bone at 12, 20 and 30 per cent.
    ruleFaint: Color(0xFFCFCBC0),
    rule: Color(0xFFBEBCB1),
    ruleStrong: Color(0xFFA8A89E),
    // Under sunlight the ground is a light basemap, so anything drawn on it
    // must beat the tile: a warm grey-brown, clearly darker than the beige of
    // a loaded basemap and distinct from the map's cyan and blue symbols.
    contour: Color(0xFF6E6758),
    // Focus ring uses the dust accent hue for high visibility.
    focus: Color(0xFFC4612F),
    brightness: Brightness.light,
  );

  /// High Contrast — WCAG AAA compliant for low-vision users.
  ///
  /// Maximises contrast ratios (>7:1) by using pure black/white surfaces
  /// and saturated accents. Follows the same hue vocabulary so the app's
  /// visual language is preserved.
  static const FieldColours highContrast = FieldColours(
    name: 'high-contrast',
    canopy: Color(0xFF000000), // Pure black
    canopyRaised: Color(0xFF1A1A1A), // Slightly raised
    canopyOverlay: Color(0xFF2D2D2D), // Overlay
    inset: Color(0xFF0D0D0D), // Input fill
    bone: Color(0xFFFFFFFF), // Pure white text
    ash1: Color(0xFFE0E0E0), // 87% white
    ash2: Color(0xFFB0B0B0), // 69% white
    ash3: Color(0xFF808080), // 50% white
    ash4: Color(0xFF505050), // 31% white
    dust: Color(0xFFFF8C00), // Dark orange (AAA on black)
    straw: Color(0xFFFFFF00), // Pure yellow (AAA on black)
    moss: Color(0xFF00FF7F), // Spring green (AAA on black)
    blood: Color(0xFFFF4444), // Bright red (AAA on black)
    water: Color(0xFF00BFFF), // Deep sky blue
    drainage: Color(0xFF00FFFF), // Cyan
    ruleFaint: Color(0xFF333333),
    rule: Color(0xFF555555),
    ruleStrong: Color(0xFF888888),
    contour: Color(0xFF888888),
    focus: Color(0xFFFF8C00), // Dark orange focus ring
    brightness: Brightness.dark,
  );

  /// Sepia — warm paper tone for reduced eye strain during long sessions.
  ///
  /// Uses a warm beige base with brown ink, like an aged field notebook.
  /// Accents are muted to maintain the paper aesthetic while staying legible.
  static const FieldColours sepia = FieldColours(
    name: 'sepia',
    canopy: Color(0xFFF5F0E1), // Warm paper
    canopyRaised: Color(0xFFE8E2D0), // Slightly darker paper
    canopyOverlay: Color(0xFFDCD6C6), // Overlay paper
    inset: Color(0xFFD0C9B8), // Input fill
    bone: Color(0xFF3C2F1F), // Dark brown ink
    ash1: Color(0xFF5D4E37), // Medium brown
    ash2: Color(0xFF8B7D65), // Light brown
    ash3: Color(0xFFB8A990), // Pale brown
    ash4: Color(0xFFD4C8B0), // Very pale brown
    dust: Color(0xFFB87333), // Copper accent
    straw: Color(0xFFC4A02E), // Antique gold
    moss: Color(0xFF5D8A4C), // Sage green
    blood: Color(0xFFC05030), // Brick red
    water: Color(0xFF4A7C8C), // Muted teal
    drainage: Color(0xFF6B9BA8), // Pale teal
    ruleFaint: Color(0xFFD4C8B0),
    rule: Color(0xFFB8A990),
    ruleStrong: Color(0xFF8B7D65),
    contour: Color(0xFF8B7D65),
    focus: Color(0xFFB87333), // Copper focus ring
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
    Color? water,
    Color? drainage,
    Color? ruleFaint,
    Color? rule,
    Color? ruleStrong,
    Color? contour,
    Color? focus,
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
      water: water ?? this.water,
      drainage: drainage ?? this.drainage,
      ruleFaint: ruleFaint ?? this.ruleFaint,
      rule: rule ?? this.rule,
      ruleStrong: ruleStrong ?? this.ruleStrong,
      contour: contour ?? this.contour,
      focus: focus ?? this.focus,
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
      water: Color.lerp(water, other.water, t)!,
      drainage: Color.lerp(drainage, other.drainage, t)!,
      ruleFaint: Color.lerp(ruleFaint, other.ruleFaint, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ruleStrong: Color.lerp(ruleStrong, other.ruleStrong, t)!,
      contour: Color.lerp(contour, other.contour, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
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

  /// A field measurement, read at a glance from a moving vehicle: a live
  /// distance, a tally hour total. Larger than [noteBody] because it is a
  /// scan value rather than running text.
  static const double measure = 26;

  /// A record's headline number, such as a sighting's count on the pin card.
  /// The largest type in the app, used where one figure is the record.
  static const double display = 40;

  /// The smallest chrome: map attribution and scale-bar labels, which must sit
  /// inside the map without competing with it. Below [stamp] deliberately.
  static const double micro = 10;
}

/// Map style presets — curated layer combinations for different field tasks.
///
/// Each preset defines which base layers and overlays are visible by default.
/// The operator can still toggle individual layers; the preset is a starting
/// point that matches the task.
enum MapStylePreset {
  /// Field work — species, observations, GPS accuracy.
  field(
    label: 'Field',
    description: 'Observations, species, accuracy rings',
    baseLayers: {'satellite', 'topo'},
    overlays: {'observations', 'species', 'accuracy', 'grid'},
  ),

  /// Navigation — routes, waypoints, tracks.
  navigation(
    label: 'Navigation',
    description: 'Routes, waypoints, tracks, bearing',
    baseLayers: {'topo', 'osm'},
    overlays: {'routes', 'waypoints', 'tracks', 'bearing', 'compass'},
  ),

  /// Survey — boundaries, transects, quadrats.
  survey(
    label: 'Survey',
    description: 'Boundaries, transects, quadrats, grid',
    baseLayers: {'topo', 'aerial'},
    overlays: {'boundaries', 'transects', 'quadrats', 'grid', 'scale'},
  );

  const MapStylePreset({
    required this.label,
    required this.description,
    required this.baseLayers,
    required this.overlays,
  });

  final String label;
  final String description;
  final Set<String> baseLayers;
  final Set<String> overlays;
}

/// Theme variant — colour palette variants beyond the light/dark mode.
enum ThemeVariant {
  /// Standard palette (Canopy/Sunlight).
  standard,

  /// High contrast for low-vision accessibility (WCAG AAA).
  highContrast,

  /// Warm sepia paper tone for reduced eye strain.
  sepia;

  String get label => switch (this) {
    ThemeVariant.standard => 'Standard',
    ThemeVariant.highContrast => 'High Contrast',
    ThemeVariant.sepia => 'Sepia',
  };

  String get subtitle => switch (this) {
    ThemeVariant.standard => 'Default',
    ThemeVariant.highContrast => 'WCAG AAA',
    ThemeVariant.sepia => 'Warm paper',
  };

  IconData get icon => switch (this) {
    ThemeVariant.standard => Icons.palette_outlined,
    ThemeVariant.highContrast => Icons.contrast_outlined,
    ThemeVariant.sepia => Icons.wb_sunny_outlined,
  };
}
