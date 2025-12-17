import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';

import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';

import 'package:journi/login_screen.dart';

import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'fake_geocoding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftUserRepository userRepo;
  late DefaultUserService userService;

  late InMemoryTripRepository tripRepo;
  late InMemoryEntryRepository entryRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    userRepo = DriftUserRepository(db);
    userService = makeUserService(userRepo);

    tripRepo = InMemoryTripRepository();
    entryRepo = InMemoryEntryRepository();
  });

  tearDown(() async {
    await db.close();
  });

  // 📌 Crear usuario válido para tests
  Future<void> createTestUser() async {
    // 🔑 Generar un id aleatorio/simple para el usuario
    final generatedId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final cmd = RegisterUserCommand(
      id: generatedId,
      name: "nombre",
      lastName: "apellidos",
      email: "email@gmail.com",
      password: "password",
    );

    final result = await userService.register(cmd);
  }

  // ------------------------------------------------------------
  // 🚀 TEST 1 — Login correcto
  // ------------------------------------------------------------
  testWidgets("✅ Login correcto con usuario válido",
      (WidgetTester tester) async {
    await createTestUser();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          sesionIniciada: false,
          viajes: const [],
          selectedIndex: 0,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          tripService: makeTripService(
              tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
          entryService: makeEntryService(entryRepo),
          userRepo: userRepo,
          userService: userService,
        ),
      ),
    );

    // Introducir email y password correctos
    await tester.enterText(
        find.byKey(const Key('usuarioTextField')), 'email@gmail.com');
    await tester.enterText(
        find.byKey(const Key('passwordTextField')), 'password');

    // Pulsar botón Entrar
    await tester.tap(find.byKey(const Key('entrarButton')));
    await tester.pumpAndSettle();

    // Debe cerrar el LoginScreen y devolver un usuario
    expect(find.byType(LoginScreen), findsNothing);
  });

  // ------------------------------------------------------------
  // ❌ TEST 2 — Error por contraseña incorrecta
  // ------------------------------------------------------------
  testWidgets("❌ Error: contraseña incorrecta", (WidgetTester tester) async {
    await createTestUser();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          sesionIniciada: false,
          viajes: const [],
          selectedIndex: 0,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          tripService: makeTripService(
              tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
          entryService: makeEntryService(entryRepo),
          userRepo: userRepo,
          userService: userService,
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('usuarioTextField')), 'paula@gmail.com');
    await tester.enterText(
        find.byKey(const Key('passwordTextField')), 'wrongpass');

    await tester.tap(find.byKey(const Key('entrarButton')));
    await tester.pump(); // mostrar snackbar

    expect(find.text('Credenciales inválidas'), findsOneWidget);
  });

  // ------------------------------------------------------------
  // ❌ TEST 3 — Email con formato inválido
  // ------------------------------------------------------------
  testWidgets("❌ Error: email en formato incorrecto",
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          sesionIniciada: false,
          viajes: const [],
          selectedIndex: 0,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          tripService: makeTripService(
              tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
          entryService: makeEntryService(entryRepo),
          userRepo: userRepo,
          userService: userService,
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('usuarioTextField')), 'incorrecto');
    await tester.enterText(find.byKey(const Key('passwordTextField')), '123');

    await tester.tap(find.byKey(const Key('entrarButton')));
    await tester.pump();

    expect(
      find.text(
          'El correo introducido no sigue el formato correcto. Inténtelo de nuevo'),
      findsOneWidget,
    );
  });

  // ------------------------------------------------------------
  // ❌ TEST 4 — Campos vacíos
  // ------------------------------------------------------------
  testWidgets("❌ Error: campos vacíos", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          sesionIniciada: false,
          viajes: const [],
          selectedIndex: 0,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          tripService: makeTripService(
              tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
          entryService: makeEntryService(entryRepo),
          userRepo: userRepo,
          userService: userService,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('entrarButton')));
    await tester.pump();

    expect(find.text('Rellena correo y contraseña'), findsOneWidget);
  });
}
