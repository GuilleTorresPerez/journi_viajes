import 'package:drift/drift.dart' as d;
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/ports/trip_repository.dart';

import 'app_database.dart' as db;

// -------- mappers --------
Trip _toDomain(db.DbTrip row) {
  final res = Trip.create(
    id: row.id,
    title: row.title,
    description: row.description,
    coverImage: row.coverImage,
    startDate: row.startDate,
    endDate: row.endDate,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
  return res.isOk
      ? res.asOk().value
      : Trip(
          id: row.id,
          title: row.title,
          description: row.description,
          coverImage: row.coverImage,
          startDate: row.startDate,
          endDate: row.endDate,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        );
}

db.TripsCompanion _toCompanion(Trip t) => db.TripsCompanion(
      id: d.Value(t.id),
      title: d.Value(t.title),
      description: d.Value(t.description),
      coverImage: d.Value(t.coverImage),
      startDate: d.Value(t.startDate?.toUtc()),
      endDate: d.Value(t.endDate?.toUtc()),
      createdAt: d.Value(t.createdAt.toUtc()),
      updatedAt: d.Value(t.updatedAt.toUtc()),
    );

class DriftTripRepository implements TripRepository {
  final db.AppDatabase _db;
  DriftTripRepository(this._db);

  @override
  Future<Result<Trip>> upsert(Trip trip) async {
    final validated = Trip.create(
      id: trip.id,
      title: trip.title,
      description: trip.description,
      coverImage: trip.coverImage,
      startDate: trip.startDate,
      endDate: trip.endDate,
      createdAt: trip.createdAt,
      updatedAt: trip.updatedAt,
    );
    if (validated is Err<Trip>) return Err<Trip>(validated.errorsOrEmpty);

    final t = validated.asOk().value;
    await _db.into(_db.trips).insertOnConflictUpdate(_toCompanion(t));
    final row = await (_db.select(
      _db.trips,
    )..where((tbl) => tbl.id.equals(t.id)))
        .getSingle();
    return Ok(_toDomain(row));
  }

  @override
  Future<Result<Trip?>> findById(String id) async {
    final row = await (_db.select(
      _db.trips,
    )..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return Ok(row == null ? null : _toDomain(row));
  }

  @override
  Future<Result<List<Trip>>> list({TripPhase? phase}) async {
    final rows = await (_db.select(
      _db.trips,
    )..orderBy([(t) => d.OrderingTerm.desc(t.createdAt)]))
        .get();
    var items = rows.map(_toDomain).toList();
    if (phase != null) items = items.where((t) => t.phase == phase).toList();
    return Ok(List.unmodifiable(items));
  }

  @override
  Stream<List<Trip>> watchAll({TripPhase? phase}) {
    final q = (_db.select(_db.trips)
      ..orderBy([(t) => d.OrderingTerm.desc(t.createdAt)]));
    return q.watch().map((rows) {
      var items = rows.map(_toDomain).toList();
      if (phase != null) items = items.where((t) => t.phase == phase).toList();
      return items;
    });
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    // <- Unit
    await (_db.delete(_db.trips)..where((t) => t.id.equals(id))).go();
    return const Ok(unit);
  }
}
