import 'package:drift/drift.dart' as d;
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'app_database.dart' as db;

User _toDomain(db.DbUser row) {
  final res = User.create(
    id: row.id,
    name: row.name,
    lastName: row.lastName,
    email: row.email,
    passwordHash: row.passwordHash,
    passwordSalt: row.passwordSalt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
  if (res.isErr) {
    throw StateError(
      'Fila users inválida (id=${row.id}): ${res.asErr().errors}',
    );
  }
  return res.asOk().value;
}

db.UsersCompanion _toCompanion(User u) => db.UsersCompanion(
      id: d.Value(u.id),
      name: d.Value(u.name),
      lastName: d.Value(u.lastName),
      email: d.Value(u.email),
      passwordHash: d.Value(u.passwordHash),
      passwordSalt: d.Value(u.passwordSalt),
      createdAt: d.Value(u.createdAt.toUtc()),
      updatedAt: d.Value(u.updatedAt.toUtc()),
    );

class DriftUserRepository implements UserRepository {
  final db.AppDatabase _db;
  DriftUserRepository(this._db);

  @override
  Future<Result<User>> upsert(User user) async {
    try {
      // upsert por PK (id). Si choca UNIQUE(email) con otro id, SQLite lanza error.
      await _db.into(_db.users).insertOnConflictUpdate(_toCompanion(user));
      final row = await (_db.select(
        _db.users,
      )..where((t) => t.id.equals(user.id)))
          .getSingle();
      return Ok(_toDomain(row));
    } catch (e, st) {
      // mapea violación de UNIQUE(email)
      return Err<User>([
        RepoError('Email ya existe', cause: e, stackTrace: st),
      ]);
    }
  }

  @override
  Future<Result<User?>> findById(String id) async {
    final row = await (_db.select(
      _db.users,
    )..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return Ok(row == null ? null : _toDomain(row));
  }

  @override
  Future<Result<User?>> findByEmail(String email) async {
    final row = await (_db.select(
      _db.users,
    )..where((t) => t.email.equals(email.toLowerCase())))
        .getSingleOrNull();
    return Ok(row == null ? null : _toDomain(row));
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    await (_db.delete(_db.users)..where((t) => t.id.equals(id))).go();
    return const Ok(unit);
  }

  @override
  Stream<List<User>> watchAll() {
    final q = _db.select(_db.users)
      ..orderBy([(t) => d.OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }
}
