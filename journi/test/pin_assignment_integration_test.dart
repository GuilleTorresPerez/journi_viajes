import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/pantalla_viaje.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

import 'fake_geocoding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧭 Pruebas de integración: Listar_Viaje', () {
    late InMemoryTripRepository tripRepo;
    late InMemoryEntryRepository entryRepo;
    late DefaultTripService tripService;
    late DefaultEntryService entryService;
    late Result<User?> result;
    late AppDatabase db;
    late DriftUserRepository userRepo;
    late DefaultUserService userService;
    late FakeGeocodingRepository geoRepo; // <- usamos nuestro fake extendido

    const String testUserId = 'test-user-id';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      userRepo = DriftUserRepository(db);
      userService = makeUserService(userRepo);

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
      result = await userRepo.upsert(userRes.asOk().value);

      tripRepo = InMemoryTripRepository();
      entryRepo = InMemoryEntryRepository();

      // ← Aquí instanciamos nuestro FakeGeocodingRepository
      geoRepo = FakeGeocodingRepository();
      // Simular Londres como ubicación válida
      geoRepo.addSearchResult('Londres', LatLng(51.5074, -0.1278));
      // Simular búsqueda inexistente
      geoRepo.addSearchResult('fbdisboahovsofqvewyvfief', null);

      tripService = makeTripService(tripRepo, userRepo, entryRepo, geoRepo);
      entryService = DefaultEntryService(repo: entryRepo);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('✅ Pin añadido correctamente', (WidgetTester tester) async {
      final viajes = [
        Trip(
          id: '1',
          title: 'Viaje Test',
          description: 'Test',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 5),
          ownerId: testUserId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            selectedIndex: 0,
            sesionIniciada: true,
            viajes: viajes,
            num_viaje: 0,
            repo: tripRepo,
            entryRepo: entryRepo,
            tripService: tripService,
            entryService: entryService,
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.text_fields));
      await tester.pumpAndSettle();

      // Introducir texto
      await tester.enterText(find.byType(TextField), 'Mi primera nota');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('Texto añadido'), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('ubicacionButton')));
      await tester.pumpAndSettle();

      // Buscar ubicación válida
      await tester.enterText(find.byKey(Key('nombreUbicacion')), 'Londres');
      await tester.tap(find.byKey(Key('buscaUbicacion')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(Key('tituloUbicacion')), 'Londres 2025');
      await tester.tap(find.byKey(Key('guardarUbicacion')));
      await tester.pumpAndSettle();

      expect(find.text('Londres 2025'), findsOneWidget);
    });

    testWidgets('❌ Error: El usuario introduce una localización inexistente',
        (WidgetTester tester) async {
      final viajes = [
        Trip(
          id: '1',
          title: 'Viaje Test',
          description: 'Test',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 5),
          ownerId: testUserId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            selectedIndex: 0,
            sesionIniciada: true,
            viajes: viajes,
            num_viaje: 0,
            repo: tripRepo,
            entryRepo: entryRepo,
            tripService: tripService,
            entryService: entryService,
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.text_fields));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Mi primera nota');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('Texto añadido'), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('ubicacionButton')));
      await tester.pumpAndSettle();

      // Buscar ubicación inexistente
      await tester.enterText(
          find.byKey(Key('nombreUbicacion')), 'fbdisboahovsofqvewyvfief');
      await tester.tap(find.byKey(Key('buscaUbicacion')));

      await tester.pump();

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
