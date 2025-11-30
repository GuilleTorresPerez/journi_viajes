import 'package:drift/native.dart'; // 👈 Importante para NativeDatabase
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'fake_geocoding_repository.dart';
import 'package:journi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧭 Pruebas de integración: Listar_Viaje', () {
    late InMemoryTripRepository tripRepo;
    late InMemoryEntryRepository entryRepo;
    late DefaultTripService tripService;
    late DefaultEntryService entryService;

    // Usamos late para inicializar en setUp
    late AppDatabase db;
    late DriftUserRepository userRepo;
    late DefaultUserService userService;

    setUp(() {
      // 1. Base de datos en memoria (limpia para cada test)
      db = AppDatabase.forTesting(NativeDatabase.memory());
      userRepo = DriftUserRepository(db);
      userService = makeUserService(userRepo);

      tripRepo = InMemoryTripRepository();
      entryRepo = InMemoryEntryRepository();
      final geoRepo = FakeGeocodingRepository();

      // 2. CORRECCIÓN: Pasamos userRepo como 4º argumento
      tripService = makeTripService(tripRepo, userRepo, entryRepo, geoRepo);

      entryService = DefaultEntryService(repo: entryRepo);
    });

    tearDown(() async {
      await db.close(); // Limpiamos recursos
    });

    testWidgets('✅ Viaje listado correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: false,
            viajes: const [],
            tripService: tripService,
            entryService: entryService,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            userRepo: userRepo,
            userService: userService,
            skipLogin: true,
          ),
        ),
      );

      // Pulsa "Nuevo viaje"
      await tester.tap(find.byKey(const Key('anadirButton')));
      await tester.pumpAndSettle();

      // Rellenar campos
      await tester.enterText(
          find.byKey(const Key('tituloField')), 'Vacaciones 2025');
      await tester.enterText(
          find.byKey(const Key('fechaIniField')), '01-01-2025');
      await tester.enterText(
          find.byKey(const Key('fechaFinField')), '10-01-2025');

      await tester.tap(find.byKey(const Key('guardarButton')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verificar éxito
      expect(find.byType(MyHomePage), findsOneWidget);
      // Nota: Asumimos que el ID generado es 'id0' por la lógica del InMemoryRepo
      expect(find.byKey(const Key('id0')), findsOneWidget);
    });

    testWidgets(
      '❌ Error: El usuario ha cancelado la creacion',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MyHomePage(
              title: 'JOURNI',
              sesionIniciada: false,
              viajes: const [],
              tripService: tripService,
              entryService: entryService,
              tripRepo: tripRepo,
              entryRepo: entryRepo,
              userRepo: userRepo,
              userService: userService,
              skipLogin: true,
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('anadirButton')));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('tituloField')), 'Vacaciones 2025');
        await tester.tap(find.byTooltip('Back')); // Volver atrás
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.byType(MyHomePage), findsOneWidget);
        expect(find.byKey(const Key('id0')), findsNothing);
      },
    );
  });
}
