import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:field_log/field/card_state.dart';
import 'package:flutter/material.dart';

/// What the quick capture sheet collected.
///
/// [choice] is null when the driver tapped Record without naming a species,
/// which is allowed: rule 21 lets a sighting be recorded without an
/// identification, and stopping a drive for a form would defeat the point of a
/// quick capture.
class QuickCaptureResult {
  const QuickCaptureResult({this.choice, this.count = 1, this.notes = ''});

  final SpeciesChoice? choice;
  final int count;
  final String notes;
}

/// The one-tap capture: open, name the species if you can, tap Record.
///
/// Built for a thumb and one glance — everything is a chip or a stepper, and
/// the driver is never asked to type more than a sentence.
Future<QuickCaptureResult?> showQuickCaptureSheet(
  BuildContext context, {
  required String coordinateLabel,
  required List<SpeciesChoice> recentSpecies,
  required List<SpeciesChoice> allSpecies,
}) {
  return showModalBottomSheet<QuickCaptureResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickCaptureSheet(
      coordinateLabel: coordinateLabel,
      recentSpecies: recentSpecies,
      allSpecies: allSpecies,
    ),
  );
}

class _QuickCaptureSheet extends StatefulWidget {
  const _QuickCaptureSheet({
    required this.coordinateLabel,
    required this.recentSpecies,
    required this.allSpecies,
  });

  final String coordinateLabel;
  final List<SpeciesChoice> recentSpecies;
  final List<SpeciesChoice> allSpecies;

  @override
  State<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<_QuickCaptureSheet> {
  SpeciesChoice? _choice;
  int _count = 1;
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<SpeciesChoice> get _matches {
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.allSpecies;
    }
    return widget.allSpecies.where((s) => s.matches(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colours.canopyRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Corners.sheet),
          ),
          border: Border.all(color: colours.rule),
        ),
        padding: EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.lg,
          Insets.lg,
          Insets.lg + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Log a sighting',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.cardTitle,
                      color: colours.bone,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 18, color: colours.ash3),
                  tooltip: 'Close',
                ),
              ],
            ),
            Text(
              widget.coordinateLabel,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.stamp,
                color: colours.ash2,
              ),
            ),
            const SizedBox(height: Insets.lg),
            if (widget.recentSpecies.isNotEmpty) ...[
              Text(
                'Recent',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.label,
                  color: colours.ash2,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final species in widget.recentSpecies)
                    _Chip(
                      label: species.commonName,
                      selected: _choice?.code == species.code,
                      onTap: () => setState(() => _choice = species),
                    ),
                ],
              ),
              const SizedBox(height: Insets.lg),
            ],
            TextField(
              controller: _query,
              style: TextStyle(color: colours.bone, fontFamily: Faces.ui.first),
              decoration: InputDecoration(
                hintText: 'Search species',
                hintStyle: TextStyle(color: colours.ash3),
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
                  borderSide: BorderSide(color: colours.ruleStrong),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_query.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final species in _matches)
                      ListTile(
                        dense: true,
                        title: Text(
                          species.commonName,
                          style: TextStyle(
                            color: colours.bone,
                            fontFamily: Faces.ui.first,
                          ),
                        ),
                        subtitle: species.scientificName.isEmpty
                            ? null
                            : Text(
                                species.scientificName,
                                style: TextStyle(
                                  color: colours.ash3,
                                  fontFamily: Faces.ui.first,
                                  fontSize: Faces.stamp,
                                ),
                              ),
                        onTap: () => setState(() => _choice = species),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Insets.lg),
            Row(
              children: [
                Text(
                  'How many',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                    color: colours.ash2,
                  ),
                ),
                const Spacer(),
                _StepButton(
                  icon: Icons.remove,
                  onTap: _count > 1 ? () => setState(() => _count -= 1) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                  child: Text(
                    '$_count',
                    style: TextStyle(
                      fontFamily: Faces.ui.first,
                      fontSize: Faces.cardTitle,
                      color: colours.bone,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add,
                  onTap: _count < 99 ? () => setState(() => _count += 1) : null,
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colours.dust,
                  foregroundColor: colours.canopy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(context)
                    .pop(QuickCaptureResult(choice: _choice, count: _count)),
                child: Text(
                  'Record',
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colours.dust : colours.canopyOverlay,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? colours.dust : colours.rule),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.stamp,
            color: selected ? colours.canopy : colours.bone,
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: onTap == null ? colours.ash3 : colours.bone,
      ),
      style: IconButton.styleFrom(
        side: BorderSide(color: colours.rule),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.control),
        ),
      ),
    );
  }
}
