import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/shared/result.dart';

void main() {
  late AppDatabase db;
  late UserRepository repo;
  late UserService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftUserRepository(db);
    service = DefaultUserService(repo);
  });

  tearDown(() async => db.close());

  test('register -> ok y guarda hash/salt (no plaintext)', () async {
    final cmd = RegisterUserCommand(
      id: 'u1',
      name: 'Ada',
      lastName: 'Lovelace',
      email: 'ADA@EXAMPLE.COM',
      password: 's3cret!',
    );
    final res = await service.register(cmd);
    expect(res.isOk, isTrue);

    final u = res.asOk().value;
    expect(u.email, 'ada@example.com'); // normalizado
    expect(u.passwordHash.isNotEmpty, isTrue);
    expect(u.passwordSalt.isNotEmpty, isTrue);
    expect(u.passwordHash == 's3cret!', isFalse); // no en claro
  });

  test('authenticate ok y wrong password falla', () async {
    // registro
    final reg = await service.register(
      RegisterUserCommand(
        id: 'u1',
        name: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        password: 'pass123',
      ),
    );
    expect(reg.isOk, isTrue);

    // login correcto (case-insensitive email)
    final ok = await service.authenticate(
      const AuthenticateUserCommand(
        email: 'ADA@EXAMPLE.COM',
        password: 'pass123',
      ),
    );
    expect(ok.isOk, isTrue);

    // login incorrecto
    final bad = await service.authenticate(
      const AuthenticateUserCommand(
        email: 'ada@example.com',
        password: 'wrong',
      ),
    );
    expect(bad.isErr, isTrue);
  });

  test('duplicate email en register -> Err(RepoError)', () async {
    final c1 = RegisterUserCommand(
      id: 'u1',
      name: 'A',
      lastName: 'B',
      email: 'dup@example.com',
      password: 'x',
    );
    final c2 = RegisterUserCommand(
      id: 'u2',
      name: 'C',
      lastName: 'D',
      email: 'dup@example.com',
      password: 'y',
    );

    expect((await service.register(c1)).isOk, isTrue);
    final r2 = await service.register(c2);
    expect(r2.isErr, isTrue);
    expect(r2.asErr().errors.first, isA<RepoError>());
  });
}
