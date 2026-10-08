import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// The shared screen shell for every pushed route: a reserve header with a
/// back arrow, an optional leading clip, an eyebrow, a serif title and
/// trailing actions, above a body and an optional bottom dock.
///
/// Every screen uses this so that there is always a visible way back. On a
/// phone the system back gesture and the arrow are two doors to the same
/// room; on a desktop build there is no system back at all, and a screen
/// with no back affordance is a screen you cannot leave.
class FieldScaffold extends StatelessWidget {
  const FieldScaffold({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
    this.onBack,
    this.backTooltip = 'Back',
    this.showBack = true,
  });

  /// Serif title, one or two lines, the largest thing in the header.
  final String title;

  /// Small stamp above the title — the screen's kind, not its name.
  final String? eyebrow;

  /// Widget before the text block, e.g. the species clip or card number.
  final Widget? leading;

  /// Trailing controls, e.g. a close button when a callback is supplied.
  final List<Widget> actions;

  /// Content below the header. Takes the full remaining height.
  final Widget body;

  /// Fixed bar below the body — save/cancel docks.
  final Widget? bottom;

  /// Defaults to `Navigator.maybePop`. Set to keep a different exit, e.g. a
  /// form that must run its own cancel logic.
  final VoidCallback? onBack;

  final String backTooltip;

  /// Hidden only where a route genuinely cannot pop, so an arrow that does
  /// nothing never appears.
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final canPop = showBack && Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: colours.canopy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              // The arrow carries its own 44px target inside the button, so
              // the row starts tighter than a full margin would suggest.
              padding: const EdgeInsets.fromLTRB(
                Insets.xs,
                Insets.sm,
                Insets.lg,
                Insets.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canPop)
                    IconButton(
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.arrow_back, color: colours.ash1),
                      tooltip: backTooltip,
                      padding: const EdgeInsets.all(Insets.sm),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  if (leading != null) ...[
                    const SizedBox(width: Insets.xs),
                    leading!,
                    const SizedBox(width: Insets.md),
                  ],
                  Expanded(
                    child: Padding(
                      // Aligns the eyebrow with the clip when the leading
                      // slot is empty, so titles sit at one x wherever the
                      // screen puts its clip.
                      padding: canPop || leading != null
                          ? EdgeInsets.zero
                          : const EdgeInsets.only(left: Insets.sm - Insets.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null) ...[
                            Text(
                              eyebrow!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: Faces.ui.first,
                                fontSize: Faces.stamp,
                                color: colours.ash2,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: Faces.book.first,
                              fontSize: Faces.cardTitle,
                              height: 1.2,
                              color: colours.bone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final action in actions) action,
                ],
              ),
            ),
            Expanded(child: body),
            ?bottom,
          ],
        ),
      ),
    );
  }
}
