// The field component library.
//
// This single-file library replaces the lost untracked components.dart. Screens
// import it for the shared controls (`FieldPrimaryButton`, `FieldChoiceChip`,
// `FieldFormField`…) and the `context.colours` accessor. Tests do not import it
// directly, but several screens under test do, so its behaviour is pinned
// indirectly (see test/screens/settings_screen_test.dart and
// test/screens/design_rules_test.dart).
//
// Two rules from the design shape the implementation here:
//  * Colour comes only from the [FieldColours] theme extension, never from a
//    Material accent, so `Theme.of(context).extension<FieldColours>()` is the
//    single source of truth.
//  * Controls are named for what they are, and a "ghost" control is not a
//    button: it never renders as a raised Material button, which is what the
//    ledger rule asserts (`find.byType(ElevatedButton)`/`TextButton` finds
//    nothing).

import 'package:flutter/material.dart';

import 'tokens.dart';
import 'theme.dart';

/// Convenience extension to read the token set from any build context.
extension FieldComponentsContext on BuildContext {
  FieldColours get colours =>
      Theme.of(this).extension<FieldColours>() ?? FieldColours.dark;
}

/// How much a [FieldCard] sits off the surface beneath it.
enum FieldCardElevation { flat, raised, overlay }

/// A surface for grouped content, with a border that says where it ends.
class FieldCard extends StatelessWidget {
  const FieldCard({
    super.key,
    this.elevation = FieldCardElevation.flat,
    this.borderColor,
    this.padding,
    required this.child,
  });

  final FieldCardElevation elevation;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    final fill = switch (elevation) {
      FieldCardElevation.flat => colours.canopy,
      FieldCardElevation.raised => colours.canopyRaised,
      FieldCardElevation.overlay => colours.canopyOverlay,
    };
    final border = borderColor ?? colours.rule;
    return Container(
      padding: padding ?? const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Corners.control),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

/// A stamp over a group, optionally carrying a trailing control.
///
/// [uppercase] is on by default because a stamp is set in caps elsewhere; the
/// ledger turns it off where the heading is a sentence rather than a stamp.
class FieldSectionHeader extends StatelessWidget {
  const FieldSectionHeader({
    super.key,
    required this.label,
    this.uppercase = true,
    this.trailing,
  });

  final String label;
  final bool uppercase;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontFamilyFallback: Faces.ui.skip(1).toList(),
                fontSize: Faces.stamp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: colours.ash3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A section: a heading and its content, with the spacing between them owned
/// here so every section in the app is spaced the same way.
class FieldSection extends StatelessWidget {
  const FieldSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontFamilyFallback: Faces.ui.skip(1).toList(),
              fontSize: Faces.label,
              color: colours.ash2,
            ),
          ),
          const SizedBox(height: Insets.sm),
          child,
        ],
      ),
    );
  }
}

/// The primary action. Renders as a [FilledButton] so it is the one control a
/// screen reads as "do this".
class FieldPrimaryButton extends StatelessWidget {
  const FieldPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;

  /// Null disables the control: a disabled primary action is a real state, not
  /// a bug, so it is passed through rather than swallowed.
  final VoidCallback? onPressed;

  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colours.dust,
        foregroundColor: colours.inkOn(colours.dust),
        disabledBackgroundColor: colours.rule,
        disabledForegroundColor: colours.ash3,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.xl,
          vertical: Insets.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colours.inkOn(colours.dust),
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontFamilyFallback: Faces.ui.skip(1).toList(),
                fontSize: Faces.label,
                color: colours.inkOn(colours.dust),
              ),
            ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A secondary action. Renders as an [OutlinedButton]: quieter than the primary
/// but still unmistakably a control.
class FieldSecondaryButton extends StatelessWidget {
  const FieldSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colours.bone,
        disabledForegroundColor: colours.ash3,
        side: BorderSide(color: colours.ruleStrong),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.xl,
          vertical: Insets.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Faces.ui.first,
          fontFamilyFallback: Faces.ui.skip(1).toList(),
          fontSize: Faces.label,
          color: onPressed == null ? colours.ash3 : colours.bone,
        ),
      ),
    );
  }
}

/// A ghost action: present, tappable, and deliberately not a raised button.
///
/// Implemented as an [InkWell], not a [TextButton] or [ElevatedButton], because
/// the ledger rule is that a control which cannot send sooner must not look
/// like one that can.
class FieldGhostButton extends StatelessWidget {
  const FieldGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Corners.control),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontFamilyFallback: Faces.ui.skip(1).toList(),
                fontSize: Faces.label,
                color: onPressed == null ? colours.ash4 : colours.ash1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single icon control, held to the 44px minimum target.
class FieldIconButton extends StatelessWidget {
  const FieldIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      color: color,
      iconSize: size,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: icon,
    );
  }
}

/// A labelled text input.
///
/// Renders a real [TextField] so a screen (and a test) can read its controller.
/// An empty [label] is permitted and drawn as nothing rather than as blank
/// space above the field.
class FieldFormField extends StatelessWidget {
  const FieldFormField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines,
    this.minLines,
    this.autofillHints,
    this.textInputAction,
    this.keyboardType,
    this.helperText,
    this.errorText,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.obscureText = false,
    this.enabled = true,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int? maxLines;
  final int? minLines;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final String? helperText;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool obscureText;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    final hasLabel = label != null && label!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel) ...[
          Text(
            label!,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontFamilyFallback: Faces.ui.skip(1).toList(),
              fontSize: Faces.supporting,
              color: colours.ash2,
            ),
          ),
          const SizedBox(height: Insets.xs),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          minLines: obscureText ? 1 : minLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          obscureText: obscureText,
          style: TextStyle(
            fontFamily: Faces.book.first,
            fontFamilyFallback: Faces.book.skip(1).toList(),
            fontSize: Faces.body,
            color: colours.bone,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colours.ash3),
            helperText: helperText,
            helperStyle: TextStyle(color: colours.ash3),
            errorText: errorText,
            errorStyle: TextStyle(color: colours.blood),
            prefixIcon: prefix,
            prefixIconColor: colours.ash2,
            suffixIcon: suffix,
            suffixIconColor: colours.ash2,
            isDense: true,
            filled: true,
            fillColor: colours.inset,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.rule),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.rule),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.focus, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.blood),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.control),
              borderSide: BorderSide(color: colours.blood, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of mutually exclusive segments, keyed by value.
///
/// Generic over the value type so the same control serves booleans
/// (`FieldSegmentedControl<bool?>`) and richer values such as a connectivity
/// status. The selected segment is filled; the rest are transparent.
class FieldSegmentedControl<T> extends StatelessWidget {
  const FieldSegmentedControl({
    super.key,
    required this.segments,
    this.selectedValue,
    this.onChanged,
    this.padding,
  });

  final Map<T, Widget> segments;
  final T? selectedValue;
  final ValueChanged<T>? onChanged;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in segments.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.xs / 2),
              child: _Segment(
                selected: selectedValue == entry.key,
                colours: colours,
                child: entry.value,
                onTap: onChanged == null ? null : () => onChanged!(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.selected,
    required this.colours,
    required this.child,
    required this.onTap,
  });

  final bool selected;
  final FieldColours colours;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.control),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colours.canopyOverlay : Colors.transparent,
            borderRadius: BorderRadius.circular(Corners.control),
            border: Border.all(
              color: selected ? colours.ruleStrong : colours.rule,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// A tappable row: an optional leading and trailing widget around a title and a
/// supporting line.
class FieldListTile extends StatelessWidget {
  const FieldListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: Insets.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontFamilyFallback: Faces.ui.skip(1).toList(),
                      fontSize: Faces.label,
                      color: colours.bone,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: Faces.book.first,
                        fontFamilyFallback: Faces.book.skip(1).toList(),
                        fontSize: Faces.supporting,
                        height: 1.35,
                        color: colours.ash3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: Insets.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A choice chip: one option among a set.
///
/// The selected state is a fill, not a tick, and it is drawn on an
/// [AnimatedContainer] whose decoration carries the accent so the selection is
/// legible as a colour a test can also read.
class FieldChoiceChip extends StatelessWidget {
  const FieldChoiceChip({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    required this.isSelected,
    this.onSelected,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final Widget? icon;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onTap;

  void _handleTap() {
    onTap?.call();
    onSelected?.call(!isSelected);
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(Corners.control),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colours.dust : colours.canopyRaised,
          borderRadius: BorderRadius.circular(Corners.control),
          border: Border.all(color: isSelected ? colours.dust : colours.rule),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(
                  size: 18,
                  color: isSelected
                      ? colours.inkOn(colours.dust)
                      : colours.ash2,
                ),
                child: icon!,
              ),
              const SizedBox(width: Insets.sm),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontFamilyFallback: Faces.ui.skip(1).toList(),
                    fontSize: Faces.label,
                    color: isSelected
                        ? colours.inkOn(colours.dust)
                        : colours.bone,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontFamilyFallback: Faces.ui.skip(1).toList(),
                      fontSize: Faces.supporting,
                      color: isSelected
                          ? colours.inkOn(colours.dust)
                          : colours.ash3,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A progress spinner.
///
/// Named for the field's own vocabulary; its colour is always passed from a
/// token rather than taken from a Material accent.
class FieldCircularProgress extends StatelessWidget {
  const FieldCircularProgress({super.key, this.valueColor, this.strokeWidth});

  final Color? valueColor;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      color: valueColor,
      strokeWidth: strokeWidth ?? 2.5,
    );
  }
}

/// The four kinds of inline message.
enum FieldSnackBarType { info, success, warning, error }

Color _bannerColour(FieldColours colours, FieldSnackBarType type) {
  return switch (type) {
    FieldSnackBarType.info => colours.ash2,
    FieldSnackBarType.success => colours.moss,
    FieldSnackBarType.warning => colours.straw,
    FieldSnackBarType.error => colours.blood,
  };
}

/// Shows a transient message through the enclosing [ScaffoldMessenger].
void showFieldSnackBar({
  required BuildContext context,
  required String message,
  FieldSnackBarType type = FieldSnackBarType.info,
}) {
  final colours = context.colours;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontFamilyFallback: Faces.ui.skip(1).toList(),
            fontSize: Faces.label,
            color: colours.inkOn(_bannerColour(colours, type)),
          ),
        ),
        backgroundColor: _bannerColour(colours, type),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// An inline message that stays on the screen rather than timing out, for a
/// problem the reader should act on before continuing.
class FieldBanner extends StatelessWidget {
  const FieldBanner({
    super.key,
    required this.message,
    required this.type,
    this.onDismiss,
  });

  final String message;
  final FieldSnackBarType type;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    final accent = _bannerColour(colours, type);
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: BorderRadius.circular(Corners.control),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontFamilyFallback: Faces.ui.skip(1).toList(),
                fontSize: Faces.supporting,
                height: 1.4,
                color: colours.bone,
              ),
            ),
          ),
          if (onDismiss != null)
            FieldIconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              color: colours.ash2,
              size: 18,
            ),
        ],
      ),
    );
  }
}
