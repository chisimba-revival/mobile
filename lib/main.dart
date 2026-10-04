import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FieldLogApp());
}

/// The application root.
///
/// This slice is the foundation: tokens and contract-derived models. The
/// screens are not built yet, so the home route states what exists and what
/// does not, rather than showing a scaffold counter that would look like a
/// finished app.
class FieldLogApp extends StatelessWidget {
  const FieldLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field log',
      debugShowCheckedModeBanner: false,
      // Dark first, and this is a field decision: the work happens at first
      // light and a white screen at 05:40 blinds.
      theme: fieldTheme(FieldColours.dark),
      darkTheme: fieldTheme(FieldColours.dark),
      home: const FoundationRoute(),
    );
  }
}

class FoundationRoute extends StatelessWidget {
  const FoundationRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final FieldColours colours = context.reserve;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colours.canopyRaised,
        surfaceTintColor: colours.canopyRaised,
        title: Text('Field log', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.xl),
        children: <Widget>[
          Text(
            'Foundation slice',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: Insets.md),
          Text(
            'The design tokens and the contract-derived models exist. '
            'The screens do not yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Insets.xl),
          _Token(
            label: 'canopy',
            colour: colours.canopy,
            description: 'Base surface',
          ),
          _Token(
            label: 'dust',
            colour: colours.dust,
            description: 'Single accent, laterite earth',
          ),
          _Token(label: 'straw', colour: colours.straw, description: 'Pending'),
          _Token(label: 'moss', colour: colours.moss, description: 'Verified'),
          _Token(
            label: 'blood',
            colour: colours.blood,
            description: 'Rejected',
          ),
        ],
      ),
    );
  }
}

/// One token, shown with the ink that is legible on it.
///
/// The swatch is the only reason [FieldColours.inkOn] exists: an accent is
/// used as a fill, and the label sits on the fill, so the label colour is
/// chosen per palette by measurement rather than assumed.
class _Token extends StatelessWidget {
  const _Token({
    required this.label,
    required this.colour,
    required this.description,
  });

  final String label;
  final Color colour;
  final String description;

  @override
  Widget build(BuildContext context) {
    final FieldColours colours = context.reserve;
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(Corners.control),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: colours.inkOn(colour),
              fontSize: Faces.label,
            ),
          ),
          const SizedBox(width: Insets.md),
          Text(
            description,
            style: TextStyle(
              color: colours.inkOn(colour),
              fontSize: Faces.supporting,
            ),
          ),
        ],
      ),
    );
  }
}
