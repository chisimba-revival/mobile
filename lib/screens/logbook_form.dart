import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:flutter/material.dart';

// ----------------------------------------------------------------- pieces
//
// The form vocabulary both logbooks speak. These were first written for the
// drive logbook and moved here when the trail logbook asked for the same
// words: one stamp label, one note line, one chip, one number field — so a
// guide who has closed a drive recognises the walk's closing form without
// being taught it again.

/// A group of fields under a stamp label, the same shape the field card uses.
class LogGroup extends StatelessWidget {
  const LogGroup({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.stamp,
            letterSpacing: 0.8,
            color: colours.ash1,
          ),
        ),
        const SizedBox(height: Insets.sm),
        child,
        if (hint != null) ...[
          const SizedBox(height: Insets.sm),
          LogSupporting(hint!, colours),
        ],
      ],
    );
  }
}

class LogSupporting extends StatelessWidget {
  const LogSupporting(this.text, this.colours, {super.key});

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Faces.ui.first,
        fontSize: Faces.supporting,
        height: 1.4,
        color: colours.ash3,
      ),
    );
  }
}

/// One live measurement: label, value, and what the value is made of.
class LogMeasure extends StatelessWidget {
  const LogMeasure({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    required this.colours,
  });

  final String label;
  final String value;
  final String note;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colours.canopyRaised,
        borderRadius: BorderRadius.circular(Corners.sheet),
        border: Border.all(color: colours.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: Faces.ui.first,
                    fontSize: Faces.label,
                    color: colours.ash2,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: Faces.book.first,
                  fontSize: 26,
                  color: colours.bone,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            note,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              height: 1.4,
              color: colours.ash3,
            ),
          ),
        ],
      ),
    );
  }
}

class LogTextField extends StatelessWidget {
  const LogTextField({
    super.key,
    required this.controller,
    required this.colours,
    this.hint,
    this.lines = 1,
  });

  final TextEditingController controller;
  final FieldColours colours;
  final String? hint;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: lines,
      minLines: lines,
      style: TextStyle(
        fontFamily: Faces.book.first,
        fontSize: Faces.body,
        height: 1.45,
        color: colours.bone,
      ),
      cursorColor: colours.straw,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: Faces.book.first,
          fontSize: Faces.body,
          color: colours.ash3,
        ),
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
          borderSide: BorderSide(color: colours.straw),
        ),
      ),
    );
  }
}

class LogNumberField extends StatelessWidget {
  const LogNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.colours,
    this.optional = false,
  });

  final String label;
  final TextEditingController controller;
  final FieldColours colours;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.label,
                color: colours.bone,
              ),
            ),
            if (optional)
              Text(
                '  optional',
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  color: colours.ash3,
                ),
              ),
          ],
        ),
        const SizedBox(height: Insets.xs),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontFamily: Faces.book.first,
            fontSize: Faces.body,
            color: colours.bone,
          ),
          cursorColor: colours.straw,
          decoration: InputDecoration(
            hintText: '—',
            hintStyle: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.body,
              color: colours.ash3,
            ),
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
              borderSide: BorderSide(color: colours.straw),
            ),
          ),
        ),
      ],
    );
  }
}

/// The head count.
///
/// A stepper rather than a keypad: counting who is aboard is a careful act,
/// and the field starts unset rather than at one, because the app was not
/// there when people got in.
class LogStepper extends StatelessWidget {
  const LogStepper({
    super.key,
    required this.value,
    required this.colours,
    required this.onChanged,
  });

  final int? value;
  final FieldColours colours;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Passengers',
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.label,
            color: colours.bone,
          ),
        ),
        const Spacer(),
        LogStepButton(
          icon: Icons.remove,
          onTap: value == null || value! <= 0
              ? null
              : () => onChanged(value! - 1),
        ),
        SizedBox(
          width: 56,
          child: Text(
            value?.toString() ?? '—',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Faces.book.first,
              fontSize: Faces.cardTitle,
              color: value == null ? colours.ash3 : colours.bone,
            ),
          ),
        ),
        LogStepButton(
          icon: Icons.add,
          // Zero is the first honest answer, not one: the driver may be
          // alone, and starting the count at a passenger who was never in
          // the vehicle would put a person in the record who was not there.
          onTap: () => onChanged(value ?? 0),
        ),
        if (value != null)
          TextButton(
            onPressed: () => onChanged(null),
            child: Text(
              'clear',
              style: TextStyle(
                fontFamily: Faces.ui.first,
                fontSize: Faces.supporting,
                color: colours.ash3,
              ),
            ),
          ),
      ],
    );
  }
}

class LogStepButton extends StatelessWidget {
  const LogStepButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colours = context.reserve;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.chip),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Corners.chip),
          border: Border.all(color: colours.ruleStrong),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colours.bone : colours.ash3,
        ),
      ),
    );
  }
}

/// One inspection line: OK, not OK, or unset.
///
/// Two answers and no default. An inspection the guide did not make is
/// recorded as unset rather than as a pass, because a tick the app put there
/// is a check nobody performed.
class LogOkRow extends StatelessWidget {
  const LogOkRow({
    super.key,
    required this.label,
    required this.value,
    required this.colours,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final FieldColours colours;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.label,
              color: colours.bone,
            ),
          ),
        ),
        LogAnswer(
          label: 'OK',
          selected: value == true,
          colours: colours,
          onTap: () => onChanged(value == true ? null : true),
        ),
        const SizedBox(width: Insets.sm),
        LogAnswer(
          label: 'Not OK',
          selected: value == false,
          colours: colours,
          onTap: () => onChanged(value == false ? null : false),
        ),
      ],
    );
  }
}

class LogYesNo extends StatelessWidget {
  const LogYesNo({
    super.key,
    required this.label,
    required this.value,
    required this.colours,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final FieldColours colours;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.label,
              color: colours.bone,
            ),
          ),
        ),
        LogAnswer(
          label: 'Yes',
          selected: value == true,
          colours: colours,
          onTap: () => onChanged(value == true ? null : true),
        ),
        const SizedBox(width: Insets.sm),
        LogAnswer(
          label: 'No',
          selected: value == false,
          colours: colours,
          onTap: () => onChanged(value == false ? null : false),
        ),
      ],
    );
  }
}

/// A stamp label over a row of chips: one choice from several short words.
///
/// Nothing is preselected. A role nobody chose is a role nobody took, and a
/// chip the app ticked on its own would put the guide in a job they did not
/// do.
class LogChoices extends StatelessWidget {
  const LogChoices({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.colours,
    required this.onChanged,
    this.hint,
  });

  /// The stamp above the chips.
  final String label;

  /// `(value, caption)` pairs in the order the service names them.
  final List<(String, String)> options;

  /// The value currently chosen, or null for none.
  final String? selected;

  final FieldColours colours;
  final ValueChanged<String?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: Faces.ui.first,
            fontSize: Faces.stamp,
            letterSpacing: 0.8,
            color: colours.ash1,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            for (final (value, caption) in options)
              LogAnswer(
                label: caption,
                selected: selected == value,
                colours: colours,
                onTap: () => onChanged(selected == value ? null : value),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: Insets.sm),
          LogSupporting(hint!, colours),
        ],
      ],
    );
  }
}

/// A fill, never text — the same measured rule the field card's chips follow.
class LogAnswer extends StatelessWidget {
  const LogAnswer({
    super.key,
    required this.label,
    required this.selected,
    required this.colours,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final FieldColours colours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? colours.straw : colours.canopyRaised;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Corners.chip),
            border: Border.all(color: selected ? colours.straw : colours.rule),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Faces.ui.first,
              fontSize: Faces.supporting,
              color: colours.inkOn(fill),
            ),
          ),
        ),
      ),
    );
  }
}
