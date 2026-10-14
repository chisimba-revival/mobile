import 'package:flutter/material.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/sighting_writer.dart';

/// Extracts sighting management state and operations from [lib/main.dart].
/// Responsibilities:
/// - Manage the sightings DB reference (_sightings)
/// - Handle recording, deletion, and restoration of sightings
/// - Coordinate with the operation queue for pending changes
/// - Expose _deleteSighting / _openSighting / _openObservations APIs
class SightingController {
  final Database database;
  final SightingWriter writer;
  final OperationQueue queue;

  SightingController({required this.database, required this.writer, required this.queue});

  final SightingWriter _sightings = SightingWriter(widget.database, widget.queue);

  Future<String?> delete(String localId) async {
    return _sightings.delete(localId);
  }

  Future<void> openSighting(String localId) async {
    final row = await _sightings.open(localId);
    if (row != null && mounted) {
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(builder: (_) => PinDetailScreen(sighting: _summaryOf(row), onAddDetail: (kind, value) => _amend(row.localId, kind, value))),
      );
    }
  }

  Future<void> openObservations() async {
    navigatorKey.currentContext!.push(
      MaterialPageRoute(builder: (_) => ObservationsScreen(database: widget.database)),
    );
  }
