import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds a Material theme from a [FieldColours] set.
///
/// Material is used for behaviour only: focus traversal, semantics and
/// platform affordances. Colour comes entirely from the token set, so that a
/// control cannot acquire a Material accent that has no counterpart in the
/// design. `colorScheme` is derived rather than hand-written for the same
/// reason, and is named from the reserve rather than from Material's scale.
ThemeData fieldTheme(FieldColours colours) {
  return ThemeData(
    useMaterial3: true,
    brightness: colours.brightness,
    scaffoldBackgroundColor: colours.canopy,
    canvasColor: colours.canopy,
    dividerColor: colours.rule,
    colorScheme: ColorScheme(
      brightness: colours.brightness,
      primary: colours.dust,
      onPrimary: colours.bone,
      secondary: colours.moss,
      onSecondary: colours.bone,
      error: colours.blood,
      onError: colours.bone,
      surface: colours.canopy,
      onSurface: colours.bone,
      surfaceContainerHighest: colours.canopyOverlay,
      outline: colours.ruleStrong,
      outlineVariant: colours.rule,
    ),
    textTheme: _textTheme(colours),
    extensions: <ThemeExtension<dynamic>>[colours],
  );
}

/// Counters use tabular numerals so a changing digit does not reflow the row.
const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

TextTheme _textTheme(FieldColours colours) {
  return TextTheme(
    // A recorded sentence is the largest thing in the app, set in the serif.
    displaySmall: TextStyle(
      fontFamily: Faces.book.first,
      fontFamilyFallback: Faces.book.skip(1).toList(),
      fontSize: Faces.noteBody,
      height: 1.5,
      color: colours.bone,
    ),
    titleLarge: TextStyle(
      fontFamily: Faces.book.first,
      fontFamilyFallback: Faces.book.skip(1).toList(),
      fontSize: Faces.cardTitle,
      height: 1.3,
      color: colours.bone,
    ),
    bodyLarge: TextStyle(
      fontFamily: Faces.book.first,
      fontFamilyFallback: Faces.book.skip(1).toList(),
      fontSize: Faces.body,
      height: 1.5,
      color: colours.bone,
    ),
    bodyMedium: TextStyle(
      fontFamily: Faces.ui.first,
      fontFamilyFallback: Faces.ui.skip(1).toList(),
      fontSize: Faces.body,
      height: 1.4,
      color: colours.bone,
    ),
    labelLarge: TextStyle(
      fontFamily: Faces.ui.first,
      fontFamilyFallback: Faces.ui.skip(1).toList(),
      fontSize: Faces.label,
      color: colours.bone,
    ),
    labelMedium: TextStyle(
      fontFamily: Faces.ui.first,
      fontFamilyFallback: Faces.ui.skip(1).toList(),
      fontSize: Faces.supporting,
      color: colours.ash2,
    ),
    labelSmall: TextStyle(
      fontFamily: Faces.ui.first,
      fontFamilyFallback: Faces.ui.skip(1).toList(),
      fontSize: Faces.stamp,
      letterSpacing: 0.8,
      color: colours.ash3,
      fontFeatures: _tabular,
    ),
  );
}

/// Convenience accessors, so a widget reads `context.reserve` rather than
/// reaching into the extension list and casting.
extension FieldThemeAccess on BuildContext {
  FieldColours get reserve =>
      Theme.of(this).extension<FieldColours>() ?? FieldColours.dark;
}
