import 'package:drift/drift.dart' as d;
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'app_database.dart' as db;

// ---------- mappers -----------
db.EntriesCompanion _toCompanion(Entry e) => db.EntriesCompanion(
  id: d.Value(e.id),
  tripId: d.Value(e.tripId),
  type: d.Value(e.type), // requiere converter en la tabla
  textContent: d.Value(e.text),
  mediaUri: d.Value(e.mediaUri),
  lat: d.Value(e.location?.lat),
  lon: d.Value(e.location?.lon),
  tagsJson: d.Value(e.tags),
  createdAt: d.Value(e.createdAt.toUtc()),
  updatedAt: d.Value(e.updatedAt.toUtc()),
);

// 👇 DbEntry (no EntriesData)
Entry _toDomain(db.DbEntry row) {
  final loc = (row.lat != null && row.lon != null)
      ? EntryLocation(lat: row.lat!, lon: row.lon!)
      : null;

  final res = Entry.create(
    id: row.id,
    tripId: row.tripId,
    type: row.type, // EntryType (gracias al converter)
    text: row.textContent,
    mediaUri: row.mediaUri,
    location: loc,
    tags: row.tagsJson, // List<String> (gracias al converter)
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  if (res.isErr) {
    throw StateError(
      'Fila entries inválida (id=${row.id}): ${res.asErr().errors}',
    );
  }
  return res.asOk().value;
}

class DriftEntryRepository implements EntryRepository {
  final db.AppDatabase _db;
  DriftEntryRepository(this._db);

  @override
  Future<Result<Entry>> upsert(Entry entry) async {
    await _db.into(_db.entries).insertOnConflictUpdate(_toCompanion(entry));
    final row = await (_db.select(
      _db.entries,
    )..where((e) => e.id.equals(entry.id))).getSingle();
    return Ok(_toDomain(row));
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    await (_db.delete(_db.entries)..where((e) => e.id.equals(id))).go();
    return const Ok(unit);
  }

  @override
  Future<Result<Entry?>> findById(String id) async {
    final row = await (_db.select(
      _db.entries,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    return Ok(row == null ? null : _toDomain(row));
  }

  @override
  Future<Result<List<Entry>>> list({String? tripId, EntryType? type}) async {
    final q = _db.select(_db.entries)
      ..orderBy([(e) => d.OrderingTerm.desc(e.createdAt)]);
    if (tripId != null) q.where((e) => e.tripId.equals(tripId));
    if (type != null)
      q.where((e) => e.type.equals(type as String)); // ahora acepta EntryType
    final rows = await q.get();
    return Ok(List.unmodifiable(rows.map(_toDomain).toList()));
  }

  @override
  Stream<List<Entry>> watchAll({String? tripId, EntryType? type}) {
    final q = _db.select(_db.entries)
      ..orderBy([(e) => d.OrderingTerm.desc(e.createdAt)]);
    if (tripId != null) q.where((e) => e.tripId.equals(tripId));
    if (type != null) q.where((e) => e.type.equals(type as String));
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }
}
