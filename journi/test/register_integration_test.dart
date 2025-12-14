import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/shared/result.dart';

import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';

import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';

import 'package:journi/register_screen.dart';
import 'package:journi/login_screen.dart';

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

  // ------------------------------------------------------------
  // 🚀 TEST 1 — Registro correcto
  // ------------------------------------------------------------
  testWidgets("✅ Registro correcto", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
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

    await tester.enterText(find.byKey(const Key('nombreField')), "Paula");
    await tester.enterText(find.byKey(const Key('apellidosField')), "Tester");
    await tester.enterText(
        find.byKey(const Key('emailField')), "paula@reg.com");
    await tester.enterText(find.byKey(const Key('passwordField')), "abc123");

    await tester.tap(find.byKey(const Key('guardarButton')));
    await tester.pumpAndSettle();

    expect(find.text('Usuario registrado correctamente'), findsOneWidget);
  });

  // ------------------------------------------------------------
  // ❌ TEST 2 — Error por campos vacíos
  // ------------------------------------------------------------
  testWidgets("❌ Error: campos vacíos", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
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

    await tester.tap(find.byKey(const Key('guardarButton')));
    await tester.pump();

    expect(find.text('Falta algún campo'), findsOneWidget);
  });

  // ------------------------------------------------------------
  // ❌ TEST 3 — Error servicio (email duplicado)
  // ------------------------------------------------------------
  testWidgets("❌ Error: email ya existe", (WidgetTester tester) async {
    // 1. Creamos usuario previo
    final cmd = RegisterUserCommand(
      id: "u1",
      name: "Ana",
      lastName: "Tester",
      email: "duplicado@test.com",
      password: "123",
    );
    await userService.register(cmd);

    // 2. Intento de registrar otro igual
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
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

    await tester.enterText(find.byKey(const Key('nombreField')), "Ana");
    await tester.enterText(find.byKey(const Key('apellidosField')), "Tester");
    await tester.enterText(
        find.byKey(const Key('emailField')), "duplicado@test.com");
    await tester.enterText(find.byKey(const Key('passwordField')), "abc123");

    await tester.tap(find.byKey(const Key('guardarButton')));
    await tester.pump();

    expect(find.text('Email ya existe'), findsOneWidget);
  });

  // ------------------------------------------------------------
  // 🔄 TEST 4 — Navegación “Ya tengo cuenta”
  // ------------------------------------------------------------
  testWidgets("➡ Navega a Login", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
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

    await tester.tap(find.byKey(const Key('yaTengoCuentaButton')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
