import 'package:flutter/material.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/progress/progress_summary.dart';

/// Extracts outing progress state and ticking logic from [lib/main.dart].
/// Responsibilities:
/// - Track whether an outing is active (_activeOutingId != null)
/// - Maintain the live elapsed readout (_clock)
/// - Handle [onStop] / [onDismiss] callbacks from the map progress card
/// - Persist active-outing state to SharedPreferences (same keys as main.dart)
class ProgressController {
  final Database database;
  final SharedPreferences prefs;

  ProgressController({required this.database, required this.prefs});

  String? _activeOutingId;
  String _activeOutingKind = 'drive';
  String _activeOutingLabel = '';
  DateTime? _activeOutingStartedAt;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (_activeOutingId == null) {
      _ticker = null;
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void setActiveOuting(String id, String kind, DateTime startedAt) {
    _activeOutingId = id;
    _activeOutingKind = kind;
    _activeOutingStartedAt = startedAt;
    _activeOutingLabel = kind == 'trail' ? 'Trail' : 'Drive';
    // persist
    prefs.setString('chisimba_active_outing', id);
    prefs.setString('chisimba_active_outing_kind', kind);
    prefs.setString('chisimba_active_outing_started_at', startedAt.toIso8601String());
  }

  void clearActiveOuting() {
    _activeOutingId = null;
    _activeOutingKind = 'drive';
    _activeOutingLabel = '';
    _activeOutingStartedAt = null;
    prefs.remove('chisimba_active_outing');
    prefs.remove('chisimba_active_outing_kind');
    prefs.remove('chisimba_active_outing_started_at');
  }

  String formatElapsed(DateTime startedAt) {
    final elapsed = DateTime.now().difference(startedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
