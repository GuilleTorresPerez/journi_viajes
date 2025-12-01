import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/application/shared/result.dart'; // Importar Result para asOk
import 'package:journi/domain/user.dart'; // 👈 Importar User
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

    late AppDatabase db;
    late DriftUserRepository userRepo;
    late DefaultUserService userService;

    // ID del usuario de prueba
    const String testUserId = 'test-user-id';

    setUp(() async {
      // 👈 setUp debe ser async para esperar a la DB
      // 1. Base de datos en memoria
      db = AppDatabase.forTesting(NativeDatabase.memory());
      userRepo = DriftUserRepository(db);
      userService = makeUserService(userRepo);

      // 2. CREAR USUARIO DUMMY (CRUCIAL PARA LA NUEVA REGLA DE OWNER_ID)
      final userRes = User.create(
        id: testUserId,
        name: 'Tester',
        lastName: 'Integration',
        email: 'test@journi.app',
        passwordHash: 'dummy',
        passwordSalt: 'dummy',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insertamos el usuario en el repo para que exista
      await userRepo.upsert(userRes.asOk().value);

      tripRepo = InMemoryTripRepository();
      entryRepo = InMemoryEntryRepository();
      final geoRepo = FakeGeocodingRepository();

      tripService = makeTripService(tripRepo, userRepo, entryRepo, geoRepo);
      entryService = DefaultEntryService(repo: entryRepo);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('✅ Viaje listado correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            // 3. Simular que ya hay sesión iniciada con el ID del test
            sesionIniciada: true,
            // NOTA: Si tu MyHomePage usa un Provider/Bloc para el usuario actual,
            // asegúrate de que esté inicializado con el usuario 'test-user-id'.
            // Si pasas el usuario explícitamente, hazlo aquí.
            viajes: const [],
            tripService: tripService,
            entryService: entryService,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            userRepo: userRepo,
            userService: userService,
            skipLogin:
                true, // Esto probablemente bypass el login screen, pero necesitamos el dato del usuario
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

      // Esperar a que la animación de cierre termine
      await tester.pumpAndSettle();

      // Verificar éxito: Si esto falla de nuevo, significa que la UI
      // sigue recibiendo un error al crear el viaje.
      expect(find.byType(MyHomePage), findsOneWidget);

      // Nota: Verifica si tu InMemoryRepo genera 'id0' o un UUID.
      // Si genera UUID, find.byKey('id0') fallará.
      // Mejor buscar por texto:
      expect(find.text('Vacaciones 2025'), findsOneWidget);
    });

    testWidgets(
      '❌ Error: El usuario ha cancelado la creacion',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MyHomePage(
              title: 'JOURNI',
              sesionIniciada: true, // Sesión activa
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
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.byType(MyHomePage), findsOneWidget);
        expect(find.text('Vacaciones 2025'), findsNothing);
      },
    );
  });
}
