import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/application/shared/result.dart';

void main() {
  late AppDatabase db;
  late UserRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory()); // ✅ en memoria
    repo = DriftUserRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  User _fakeUser(String id, String email) {
    final now = DateTime.now().toUtc();
    final r = User.create(
      id: id,
      name: 'Test',
      lastName: 'User',
      email: email,
      passwordHash: 'hashhex',
      passwordSalt: 'saltb64',
      createdAt: now,
      updatedAt: now,
    );
    return r.asOk().value;
  }

  test('upsert y findByEmail funcionan', () async {
    final cols = await db.customSelect('PRAGMA table_info(users);').get();
    final names = cols.map((r) => r.data['name'] as String).toList();
    print('Users columns => $names');
    // Expect opcional:
    expect(names.toSet(), containsAll(['password_hash', 'password_salt']));

    final u = _fakeUser('u1', 'USER@EXAMPLE.com');
    final up = await repo.upsert(u);
    expect(up.isOk, isTrue);

    final got = await repo.findByEmail('user@example.com');
    expect(got.isOk, isTrue);
    expect(got.asOk().value!.id, equals('u1'));
  });

  test('UNIQUE(email) produce Err(RepoError)', () async {
    final u1 = _fakeUser('u1', 'dup@example.com');
    final u2 = _fakeUser('u2', 'dup@example.com');
    expect((await repo.upsert(u1)).isOk, isTrue);
    final res = await repo.upsert(u2);
    expect(res.isErr, isTrue);
    // opcional: inspeccionar tipo de error
    expect(res.asErr().errors.first, isA<RepoError>());
  });

  test('deleteById elimina y watchAll emite', () async {
    final stream = repo.watchAll();
    // primer snapshot (vacío)
    expectLater(stream, emits(isA<List<User>>()));

    final u = _fakeUser('u1', 'a@b.com');
    await repo.upsert(u);

    // tras insertar, al menos una emisión con 1 elemento
    await expectLater(
      stream,
      emits(predicate<List<User>>((l) => l.any((x) => x.id == 'u1'))),
    );

    await repo.deleteById('u1');

    // después de borrar, debería emitir una lista donde no esté 'u1'
    await expectLater(
      stream,
      emits(predicate<List<User>>((l) => l.every((x) => x.id != 'u1'))),
    );
  });
}
