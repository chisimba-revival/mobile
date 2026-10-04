import 'package:drift/drift.dart';
import 'package:field_log/data/tables.dart';

/// One position along a trail log.
///
/// The contract is unusually specific about this entity, and this table is
/// shaped to make its rule structural rather than a promise. From the service
/// contract:
///
/// > "A trail log carries ordered waypoints and any observations made along
/// > the route. Appends are additive; a trail log is not rewritten, because the
/// > sequence of observations is itself the record. This is the one entity
/// > where ordering is the content, so a revision conflict on a waypoint list
/// > is resolved by appending rather than by refusing."
///
/// Three consequences, and none of them is a matter of discipline:
///
/// [ordinal] is part of the primary key. A waypoint's identity *is* its
/// position in the sequence, so there is no surrogate key that could be used to
/// renumber one. Reordering the sequence would rewrite the record, which is the
/// one thing this entity forbids, so the database will not permit it even by
/// accident.
///
/// There is deliberately no surrogate id column and no "updated at". A row that
/// could be edited in place would contradict the contract's statement that the
/// log is not rewritten, so those columns simply do not exist. A correction is
/// a new waypoint, not an edit to an old one.
///
/// There is no `hasPendingChanges`. The queue already knows what has not been
/// sent, and a second flag here would be a second answer to the same question,
/// free to disagree with the first.
///
/// Note also that a waypoint carries no revision of its own and takes no part
/// in conflict resolution. That is the contract's documented exception: a
/// conflict on a waypoint list resolves by appending, never by refusing.
class TrailWaypoints extends Table {
  TextColumn get trailLogId =>
      text().references(TrailLogs, #localId, onDelete: KeyAction.cascade)();

  /// Position in the sequence, from zero. Assigned once, at append time, and
  /// never changed.
  IntColumn get ordinal => integer()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  /// Measured accuracy at the time. Part of the record, so it is never smoothed
  /// into a tidier number after the fact.
  RealColumn get accuracyMetres => real().nullable()();

  DateTimeColumn get recordedAt => dateTime()();

  /// What the trainee noted here. Free text, because it may be a track, a call,
  /// a plant, a water sign, or something they could not name at all.
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {trailLogId, ordinal};
}
