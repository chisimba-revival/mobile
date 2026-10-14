import 'dart:async';

import 'package:field_log/design/components.dart';
import 'package:field_log/design/theme.dart';
import 'package:field_log/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final colours = context.colours;
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

/// A form-level error: the reason a record cannot be saved yet.
///
/// Distinct from [LogSupporting], which is a quiet hint. A disabled control
/// with only a muted hint beside it reads as a dead end, so an error is drawn
/// in the rejected ink on a raised surface with a mark, and announced as a
/// live region for screen readers.
class LogErrorBanner extends StatelessWidget {
  const LogErrorBanner(this.text, this.colours, {super.key});

  final String text;
  final FieldColours colours;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: colours.canopyRaised,
          borderRadius: BorderRadius.circular(Corners.control),
          border: Border.all(color: colours.blood),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: Faces.cardTitle,
              color: colours.blood,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: Faces.ui.first,
                  fontSize: Faces.supporting,
                  height: 1.4,
                  color: colours.bone,
                ),
              ),
            ),
          ],
        ),
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
                  fontSize: Faces.measure,
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

class LogTextField extends StatefulWidget {
  const LogTextField({
    super.key,
    required this.controller,
    required this.colours,
    this.hint,
    this.lines = 1,
    this.validator,
    this.debounceMs = 500,
    this.autofillHints,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FieldColours colours;
  final String? hint;
  final int lines;
  final String? Function(String?)? validator;
  final int debounceMs;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LogTextField> createState() => _LogTextFieldState();
}

class _LogTextFieldState extends State<LogTextField> {
  Timer? _debounceTimer;
  String? _errorText;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasFocus) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (mounted && widget.validator != null) {
        final error = widget.validator!(widget.controller.text);
        setState(() => _errorText = error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;
    final colours = widget.colours;
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      child: FieldFormField(
        controller: widget.controller,
        label: '',
        hint: widget.hint,
        maxLines: widget.lines,
        minLines: widget.lines,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction ?? TextInputAction.next,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        onSubmitted: widget.onSubmitted,
        errorText: _errorText,
        enabled: true,
        autocorrect: false,
        enableSuggestions: true,
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
    return FieldFormField(
      controller: controller,
      label: label,
      hint: '—',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofillHints: const [
        AutofillHints.creditCardNumber,
      ], // closest match for numeric
      helperText: optional ? 'optional' : null,
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
        FieldIconButton(
          icon: const Icon(Icons.remove),
          onPressed: value == null || value! <= 0
              ? null
              : () => onChanged(value! - 1),
          size: 44,
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
        FieldIconButton(
          icon: const Icon(Icons.add),
          onPressed: () => onChanged((value ?? -1) + 1),
          size: 44,
        ),
        if (value != null)
          FieldGhostButton(label: 'clear', onPressed: () => onChanged(null)),
      ],
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
        FieldSegmentedControl<bool?>(
          segments: {true: const Text('OK'), false: const Text('Not OK')},
          selectedValue: value,
          onChanged: (v) => onChanged(v),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
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
        FieldSegmentedControl<bool?>(
          segments: {true: const Text('Yes'), false: const Text('No')},
          selectedValue: value,
          onChanged: (v) => onChanged(v),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
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
              FieldChoiceChip(
                label: caption,
                isSelected: selected == value,
                onSelected: (selected) {
                  onChanged(selected ? value : null);
                },
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
    return FieldChoiceChip(
      label: label,
      isSelected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
