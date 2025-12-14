import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';

import 'package:journi/estadisticasScreen.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';

import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/user_service.dart';

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

  Widget _wrap(EstadisticasScreen screen) {
    return MaterialApp(home: screen);
  }

  // 📌 Crear usuario válido para tests
  Future<User?> createTestUser() async {
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
    return result.valueOrNull;
  }

  group('EstadisticasScreen Tests', () {
    testWidgets('Muestra mensaje de que no hay viajes y botón Crear viaje',
        (tester) async {
      User? user = await createTestUser();
      final screen = EstadisticasScreen(
        selectedIndex: 3,
        sesionIniciada: true,
        viajes: [],
        tripRepo: tripRepo,
        entryRepo: entryRepo,
        tripService: makeTripService(
            tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
        entryService: makeEntryService(entryRepo),
        userRepo: userRepo,
        userService: userService,
        currentUser: user,
      );

      await tester.pumpWidget(_wrap(screen));

      // Mensajes principales
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text
                  .toPlainText()
                  .contains("Todavía no tienes ningún viaje registrado"),
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains("¿Quieres crear uno?"),
        ),
        findsOneWidget,
      );

      // Botón crear viaje visible
      expect(find.text("Crear viaje"), findsOneWidget);
    });

    testWidgets('Muestra estadísticas correctamente cuando hay viajes',
        (tester) async {
      final viajes = [
        Trip(
          id: "1",
          title: "Italia",
          description: "Roma",
          startDate: DateTime(2024, 1, 10),
          endDate: DateTime(2024, 1, 15),
          ownerId: '',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
        Trip(
          id: "2",
          title: "Francia",
          description: "París",
          startDate: DateTime(2024, 2, 5),
          endDate: DateTime(2024, 1, 15),
          ownerId: '',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
      ];

      User? user = await createTestUser();

      final screen = EstadisticasScreen(
        selectedIndex: 3,
        sesionIniciada: true,
        viajes: viajes,
        tripRepo: tripRepo,
        entryRepo: entryRepo,
        tripService: makeTripService(
            tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
        entryService: makeEntryService(entryRepo),
        userRepo: userRepo,
        userService: userService,
        currentUser: user,
      );

      await tester.pumpWidget(_wrap(screen));

      // Mensaje de éxito visible
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains("🌍 ¡Enhorabuena!"),
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains("Has realizado 2 viajes"),
        ),
        findsOneWidget,
      );

      // Título de la sección
      expect(find.text("Resumen de tus viajes"), findsOneWidget);

      // Tarjeta de duración
      expect(find.text("Duración de cada viaje (días)"), findsOneWidget);

      // Tarjeta de destinos
      expect(find.text("Destinos visitados"), findsOneWidget);

      // Asegurar que las gráficas están presentes (solo validar que aparecen contenedores y SizedBox)
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });
  });
}
