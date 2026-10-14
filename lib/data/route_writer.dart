import 'package:drift/drift.dart';
import 'package:field_log/data/database.dart';
import 'package:field_log/data/operation_queue.dart';
import 'package:field_log/models/sync_operation.dart';

/// Writes a planned route and its waypoints, and queues them to reach the
/// service, in one transaction.
///
/// A route is owned by an outing and is *replaced* rather than edited: the
/// editor mints a fresh route id on every save, so the old route and its
/// waypoints are tombstoned (rule 9 — a removal is a record, not an absence)
/// and the new one is written. Leaving the old route live would give the map
/// two routes to choose between with no way to say which is current.
///
/// The row and the queue entry are one unit of work for the same reason they
/// are in [SightingWriter]: a route that exists locally but was never queued is
/// a plan the client believes it has recorded and will never send.
class RouteWriter {
  RouteWriter(this._db, this._queue, this._contextCode);

  final FieldLogDatabase _db;
  final OperationQueue _queue;
  final String _contextCode;

  /// Stores [waypoints] as the outing's current route, replacing whatever the
  /// outing had before.
  ///
  /// [routeLocalId] is the id the editor minted; [waypoints] already carry that
  /// id and their ordinals, so they are inserted as given rather than renumbered
  /// — ordering is the content of a route and a sequence is never rewritten.
  Future<void> saveRoute({
    required String outingId,
    required List<RouteWaypoint> waypoints,
    required String routeLocalId,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();

      // Replace: tombstone every live route the outing already had, so the
      // latest live one is the only one the map can draw.
      final existing =
          await (_db.select(_db.plannedRoutes)..where(
                (t) =>
                    t.outingId.equals(outingId) & t.isTombstone.equals(false),
              ))
              .get();
      for (final row in existing) {
        await (_db.update(
          _db.plannedRoutes,
        )..where((t) => t.localId.equals(row.localId))).write(
          PlannedRoutesCompanion(
            isTombstone: const Value(true),
            deletedAt: Value(now),
            hasPendingChanges: const Value(true),
          ),
        );
        await _queue.enqueueNew(
          entityId: row.localId,
          entity: EntityKind.plannedRoute,
          kind: OperationKind.delete,
          baseRevision: row.revision,
          capturedAt: now,
          recordedAt: now,
          payload: {'local_id': row.localId, 'outing_id': outingId},
        );
      }

      await _db
          .into(_db.plannedRoutes)
          .insert(
            PlannedRoutesCompanion(
              localId: Value(routeLocalId),
              outingId: Value(outingId),
              createdAt: Value(now),
              updatedAt: Value(now),
              revision: const Value(0),
              hasPendingChanges: const Value(true),
              isTombstone: const Value(false),
            ),
          );
      await _queue.enqueueNew(
        entityId: routeLocalId,
        entity: EntityKind.plannedRoute,
        kind: OperationKind.create,
        baseRevision: 0,
        capturedAt: now,
        recordedAt: now,
        payload: {
          'local_id': routeLocalId,
          'outing_id': outingId,
          'context_code': _contextCode,
        },
      );

      for (final waypoint in waypoints) {
        await _db
            .into(_db.routeWaypoints)
            .insert(
              RouteWaypointsCompanion(
                routeId: Value(routeLocalId),
                ordinal: Value(waypoint.ordinal),
                latitude: Value(waypoint.latitude),
                longitude: Value(waypoint.longitude),
                label: Value(waypoint.label),
                kind: Value(waypoint.kind),
                note: Value(waypoint.note),
                revision: const Value(0),
                isTombstone: const Value(false),
              ),
            );
        await _queue.enqueueNew(
          entityId: '$routeLocalId:${waypoint.ordinal}',
          entity: EntityKind.routeWaypoint,
          kind: OperationKind.create,
          baseRevision: 0,
          capturedAt: now,
          recordedAt: now,
          payload: {
            'route_id': routeLocalId,
            'ordinal': waypoint.ordinal,
            'latitude': waypoint.latitude,
            'longitude': waypoint.longitude,
            'kind': waypoint.kind,
          },
        );
      }
    });
  }
}
