import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';

import 'package:journi/domain/user.dart';

import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';

import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/mi_perfil.dart';

import 'fake_geocoding_repository.dart';
import 'package:drift/native.dart';

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

  // ------------------------------------------------------------------
  // 🚀 TEST — La pantalla MiPerfil muestra los datos correctamente
  // ------------------------------------------------------------------
  testWidgets("👤 MiPerfil muestra los datos del usuario correctamente",
          (WidgetTester tester) async {
        // Usuario de prueba
        final fakeUser = User(
          id: "u100",
          name: "Paula",
          lastName: "Tester",
          email: "paula@test.com",
          createdAt: DateTime(2024, 01, 15), passwordHash: '', passwordSalt: '', updatedAt: DateTime(2024, 01, 15),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MiPerfil(
              sesionIniciada: true,
              viajes: const [],
              selectedIndex: 4,
              tripRepo: tripRepo,
              entryRepo: entryRepo,
              tripService: makeTripService(
                  tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
              entryService: makeEntryService(entryRepo),
              userRepo: userRepo,
              userService: userService,
              currentUser: fakeUser,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 🔎 1. Nombre completo
        expect(find.text("Paula Tester"), findsOneWidget);

        // 🔎 2. ID
        expect(find.text("u100"), findsOneWidget);

        // 🔎 3. Email
        expect(find.text("paula@test.com"), findsOneWidget);

        // 🔎 4. Fecha de creación (YYYY-MM-DD)
        expect(find.text("2024-01-15"), findsOneWidget);
      });
}
