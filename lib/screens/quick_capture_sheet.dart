import 'package:field_log/design/components.dart';
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
    final colours = context.colours;
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
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.lg,
          Insets.lg,
          Insets.xxl,
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
                FieldIconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  color: colours.ash3,
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
              const SizedBox(height: Insets.sm),
              Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: [
                  for (final species in widget.recentSpecies)
                    FieldChoiceChip(
                      label: species.commonName,
                      isSelected: _choice?.code == species.code,
                      onSelected: (selected) {
                        if (selected) setState(() => _choice = species);
                      },
                      onTap: () => setState(() => _choice = species),
                    ),
                ],
              ),
              const SizedBox(height: Insets.lg),
            ],
            FieldFormField(
              controller: _query,
              label: 'Search species',
              hint: 'Search species',
              prefix: const Icon(Icons.search),
              onChanged: (_) => setState(() {}),
            ),
            if (_query.text.isNotEmpty) ...[
              const SizedBox(height: Insets.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final species in _matches)
                        FieldListTile(
                          title: species.commonName,
                          subtitle: species.scientificName.isEmpty
                              ? null
                              : species.scientificName,
                          trailing: _choice?.code == species.code
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: colours.canopy,
                                )
                              : null,
                          selected: _choice?.code == species.code,
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() => _choice = species);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (_choice != null) ...[
              const SizedBox(height: Insets.lg),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: colours.straw),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Selected: ${_choice!.commonName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: Faces.ui.first,
                        fontSize: Faces.stamp,
                        color: colours.bone,
                      ),
                    ),
                  ),
                ],
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
                FieldIconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _count > 1
                      ? () => setState(() => _count -= 1)
                      : null,
                  color: colours.bone,
                  size: 44,
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
                FieldIconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _count < 99
                      ? () => setState(() => _count += 1)
                      : null,
                  color: colours.bone,
                  size: 44,
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            FieldPrimaryButton(
              label: 'Record',
              onPressed: () =>
                  Navigator.of(context)
                      .pop(QuickCaptureResult(choice: _choice, count: _count)),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
