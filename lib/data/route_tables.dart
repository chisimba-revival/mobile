import 'package:drift/drift.dart';
import 'package:field_log/data/tables.dart';

/// A planned route for an outing.
///
/// The route belongs to an outing and defines the path the guide intends to
/// follow. Waypoints are ordered vertices; POIs (points of interest) are named
/// locations along the route such as gates, waterholes, or landmarks.
///
/// The contract for this entity is local-first: the device plans the route, and
/// the server may or may not ever receive it. A planned route is not the same as
/// a trail log — a trail log records where the guide *actually* went; a planned
/// route records where they *intend* to go.
class PlannedRoutes extends Table {
  /// The client-minted id for this route.
  TextColumn get localId => text()();

  /// The server's id, once synced.
  TextColumn get serverId => text().nullable()();

  /// The outing this route belongs to.
  TextColumn get outingId =>
      text().references(Drives, #localId, onDelete: KeyAction.cascade)();

  /// When the route was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// When the route was last modified locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether this route has local changes not yet sent to the server.
  BoolColumn get hasPendingChanges =>
      boolean().withDefault(const Constant(false))();

  /// Whether this route has been deleted (soft delete).
  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

/// One waypoint along a planned route.
///
/// Waypoints are ordered vertices that define the route geometry. POIs are
/// optional named waypoints with a kind (gate, waterhole, landmark, custom).
/// The ordinal determines the sequence — waypoints are not renumbered once
/// created; a new waypoint gets the next ordinal.
class RouteWaypoints extends Table {
  /// The route this waypoint belongs to.
  TextColumn get routeId =>
      text().references(PlannedRoutes, #localId, onDelete: KeyAction.cascade)();

  /// Position in the sequence, from zero. Assigned once at creation.
  IntColumn get ordinal => integer()();

  /// Latitude of the waypoint.
  RealColumn get latitude => real()();

  /// Longitude of the waypoint.
  RealColumn get longitude => real()();

  /// Optional label for POI waypoints (e.g., "North Gate", "Main Pan").
  TextColumn get label => text().nullable()();

  /// Kind of waypoint: vertex, gate, waterhole, landmark, custom.
  TextColumn get kind => text().withDefault(const Constant('vertex'))();

  /// Optional note for this waypoint.
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {routeId, ordinal};
}

/// Waypoint kinds as an enum for type safety in the UI.
enum RouteWaypointKind { vertex, gate, waterhole, landmark, custom }
