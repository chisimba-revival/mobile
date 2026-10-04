import 'package:field_log/data/database.dart';
import 'package:field_log/models/sighting.dart';

/// How a pin is drawn, and what it is called out loud.
///
/// The design's pin is a notched field-card tab, and the glyph on it carries
/// the identification status. All of that is decided here rather than in a
/// widget, because the rules are subtle enough to be worth testing and are
/// the same rules the prototype's `drawPins` applies.
class PinVisual {
  const PinVisual({
    required this.state,
    required this.glyph,
    required this.isSign,
    required this.isNote,
    required this.spoken,
  });

  final PinState state;

  /// The character on the tab: a count, a letter, a `?`, or a middot for a sign.
  final String glyph;

  /// A spoor, scat or heard-and-not-seen record rather than an animal seen.
  final bool isSign;

  /// Recorded in words and not yet identified.
  final bool isNote;

  /// What a screen reader should say. Never empty: a pin with no species still
  /// has to announce the thing that is there.
  final String spoken;
}

enum PinState { unverified, queued, verified, corrected, needsReview, deleted }

/// Species codes the design treats as a sign of an animal rather than the
/// animal itself. These are the codes whose records exist because something was
/// found or heard, not because something was seen.
const Set<String> signCodes = <String>{'SPOO', 'SCAT', 'VOX'};

/// Derive what a pin should look like from the row it stands for.
///
/// The glyph rules, in the design's order:
///
/// - a record written in words that nobody has identified reads `?`, because
///   that is the honest answer and a letter would be a guess;
/// - a sign of an animal reads a middot, because a count would imply an animal
///   was counted when nothing was counted at all;
/// - anything else reads its count when the count is more than one, and the
///   first letter of the species otherwise, because "4" is more use than "L".
PinVisual pinVisualFor(
  SightingRow row, {
  required String Function(String code) commonNameFor,
}) {
  final code = row.speciesCode?.trim().toUpperCase() ?? '';
  final hasCode = code.isNotEmpty;
  final isNote = !hasCode;
  final isSign = hasCode && signCodes.contains(code);
  final count = row.count ?? 0;

  final name = hasCode ? commonNameFor(code) : '';
  final spokenName = name.isEmpty ? '' : '$name, ';

  // A deleted record keeps its place on the map so the trail of the day still
  // reads. It is drawn hollow rather than solid, because it is a place that
  // used to hold something.
  if (row.isTombstone) {
    return PinVisual(
      state: PinState.deleted,
      glyph: hasCode ? code.substring(0, 1) : '?',
      isSign: isSign,
      isNote: isNote,
      spoken: 'Deleted. ${hasCode ? spokenName : ''}was recorded here.',
    );
  }

  final settled = row.status == SightingStatus.verified;

  // A note whose species arrived later reads the letter, and reads solid once
  // a mentor has verified it. The words stay in the record either way.
  if (isNote) {
    if (settled) {
      return PinVisual(
        state: PinState.verified,
        glyph: '?',
        isSign: false,
        isNote: true,
        spoken: 'Note, identified by a mentor as $name. ${_excerpt(row.notes)}',
      );
    }
    return PinVisual(
      state: row.hasPendingChanges ? PinState.queued : PinState.unverified,
      glyph: '?',
      isSign: false,
      isNote: true,
      spoken:
          'Note, not yet identified. ${_excerpt(row.notes)} '
          'Awaiting review.',
    );
  }

  // A correction keeps its original count on the record, and the pin says so,
  // because a number that quietly changed would be the one thing a trainee
  // could not learn from.
  if (hasCode && row.recordedCount != null && row.recordedCount != row.count) {
    return PinVisual(
      state: PinState.corrected,
      glyph: _glyphFor(count, code, isSign),
      isSign: isSign,
      isNote: false,
      spoken:
          '$name, corrected from ${row.recordedCount} to ${row.count ?? 0}. '
          '${_correctionReason(row)}',
    );
  }

  if (row.status == SightingStatus.needsReview) {
    return PinVisual(
      state: PinState.needsReview,
      glyph: _glyphFor(count, code, isSign),
      isSign: isSign,
      isNote: false,
      spoken: '$name, $count. A mentor looked and has not decided yet.',
    );
  }

  if (settled) {
    return PinVisual(
      state: PinState.verified,
      glyph: _glyphFor(count, code, isSign),
      isSign: isSign,
      isNote: false,
      spoken: '$name, $count. Verified.',
    );
  }

  return PinVisual(
    state: row.hasPendingChanges ? PinState.queued : PinState.unverified,
    glyph: _glyphFor(count, code, isSign),
    isSign: isSign,
    isNote: false,
    spoken: spokenName.isEmpty
        ? 'Sighting, not identified.'
        : '$spokenName$count. '
              'Awaiting review.',
  );
}

String _glyphFor(int count, String code, bool isSign) {
  if (isSign) {
    return '·';
  }
  if (count > 1) {
    return '$count';
  }
  return code.isEmpty ? '?' : code.substring(0, 1);
}

/// The design caps the note read-out at a screenful. Sixty characters is what
/// its prototype used, so a long note is never read out in full by accident.
String _excerpt(String? notes) {
  final trimmed = (notes ?? '').trim();
  if (trimmed.isEmpty) {
    return 'No note recorded.';
  }
  final flat = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  return flat.length <= 60 ? flat : '${flat.substring(0, 60)}…';
}

String _correctionReason(SightingRow row) {
  final reason = row.correctionReason?.trim() ?? '';
  if (reason.isEmpty) {
    return 'The reason given was not recorded.';
  }
  return 'Reason: $reason';
}
