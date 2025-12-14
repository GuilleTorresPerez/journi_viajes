import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/user.dart';

import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';

import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late DriftUserRepository userRepo;
  late DefaultUserService userService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    userRepo = DriftUserRepository(db);
    userService = makeUserService(userRepo);
  });

  tearDown(() async {
    await db.close();
  });

  // ------------------------------------------------------------
  // ✅ TEST 1 — Login correcto
  // ------------------------------------------------------------
  test('authenticate devuelve Ok<User> con credenciales válidas', () async {
    final registerCmd = RegisterUserCommand(
      id: 'user1',
      name: 'Nombre',
      lastName: 'Apellido',
      email: 'email@gmail.com',
      password: 'password',
    );

    await userService.register(registerCmd);

    final loginCmd = AuthenticateUserCommand(
      email: 'email@gmail.com',
      password: 'password',
    );

    final result = await userService.authenticate(loginCmd);

    expect(result, isA<Ok<User>>());
  });

  // ------------------------------------------------------------
  // ❌ TEST 2 — Password incorrecta
  // ------------------------------------------------------------
  test('authenticate devuelve Err si la contraseña es incorrecta', () async {
    final registerCmd = RegisterUserCommand(
      id: 'user2',
      name: 'Nombre',
      lastName: 'Apellido',
      email: 'email@gmail.com',
      password: 'password',
    );

    await userService.register(registerCmd);

    final loginCmd = AuthenticateUserCommand(
      email: 'email@gmail.com',
      password: 'wrongpass',
    );

    final result = await userService.authenticate(loginCmd);

    expect(result, isA<Err>());
  });

  // ------------------------------------------------------------
  // ❌ TEST 3 — Usuario inexistente
  // ------------------------------------------------------------
  test('authenticate devuelve Err si el usuario no existe', () async {
    final loginCmd = AuthenticateUserCommand(
      email: 'noexiste@gmail.com',
      password: 'password',
    );

    final result = await userService.authenticate(loginCmd);

    expect(result, isA<Err>());
  });
}
