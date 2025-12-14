import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late DriftUserRepository userRepo;
  late DefaultUserService userService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    userRepo = DriftUserRepository(db);
    userService = makeUserService(userRepo);
  });

  tearDown(() async {
    await db.close();
  });

  // --------------------------------------------------
  // ✅ Registro correcto
  // --------------------------------------------------
  test('register devuelve Ok cuando datos son válidos', () async {
    final cmd = RegisterUserCommand(
      id: 'u1',
      name: 'Paula',
      lastName: 'Tester',
      email: 'paula@test.com',
      password: '1234',
    );

    final result = await userService.register(cmd);

    expect(result, isA<Ok>());
  });

  // --------------------------------------------------
  // ❌ Email duplicado
  // --------------------------------------------------
  test('register devuelve Error cuando email existe', () async {
    final cmd1 = RegisterUserCommand(
      id: 'u1',
      name: 'Ana',
      lastName: 'Tester',
      email: 'dup@test.com',
      password: '123',
    );

    final cmd2 = RegisterUserCommand(
      id: 'u2',
      name: 'Ana',
      lastName: 'Tester',
      email: 'dup@test.com',
      password: '123',
    );

    await userService.register(cmd1);
    final result = await userService.register(cmd2);

    expect(result.isErr, true);
    expect(result.errorsOrEmpty.first.message, 'Email ya existe');
  });
}
