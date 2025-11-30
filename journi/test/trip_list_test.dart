import 'package:drift/native.dart';
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
import 'package:journi/domain/trip.dart';
import 'package:journi/main.dart';
import 'package:journi/pantalla_viaje.dart';

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

  // Helper local para limpiar el código repetitivo
  Trip createTrip(String id, String title) {
    return Trip(
      id: id,
      ownerId: 'u1', // 👈 CORREGIDO
      title: title,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 5),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  testWidgets(
    'Muestra CircularProgressIndicator mientras se cargan los viajes',
    (tester) async {
      final repo = InMemoryTripRepository();
      final entryRepo = InMemoryEntryRepository();
      final geoRepo = FakeGeocodingRepository();
      final tripService = makeTripService(repo, userRepo, entryRepo, geoRepo);
      final entryService = makeEntryService(entryRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: false,
            viajes: const [],
            tripRepo: repo,
            tripService: tripService,
            entryRepo: entryRepo,
            entryService: entryService,
            userRepo: userRepo,
            userService: userService,
            skipLogin: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('Muestra mensaje si no hay viajes registrados', (tester) async {
    final repo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final geoRepo = FakeGeocodingRepository();
    final tripService = makeTripService(repo, userRepo, entryRepo, geoRepo);
    final entryService = makeEntryService(entryRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          sesionIniciada: false,
          viajes: const [],
          tripRepo: repo,
          tripService: tripService,
          entryRepo: entryRepo,
          entryService: entryService,
          userRepo: userRepo,
          userService: userService,
          skipLogin: true,
        ),
      ),
    );

    await tester.pump();
    expect(find.text('No tienes ningún viaje registrado.'), findsOneWidget);
  });

  testWidgets('Renderiza la lista de viajes correctamente', (tester) async {
    final repo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final geoRepo = FakeGeocodingRepository();
    final tripService = makeTripService(repo, userRepo, entryRepo, geoRepo);
    final entryService = makeEntryService(entryRepo);

    final trip1 = createTrip('1', 'Madrid'); // 👈 Usamos helper corregido
    repo.upsert(trip1);

    await tester.pumpWidget(
      MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          sesionIniciada: false,
          viajes: const [],
          tripRepo: repo,
          tripService: tripService,
          entryRepo: entryRepo,
          entryService: entryService,
          userRepo: userRepo,
          userService: userService,
          skipLogin: true,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Madrid'), findsOneWidget);
  });

  testWidgets('Al pulsar un viaje navega a Pantalla_Viaje', (tester) async {
    final repo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final geoRepo = FakeGeocodingRepository();
    final tripService = makeTripService(repo, userRepo, entryRepo, geoRepo);
    final entryService = makeEntryService(entryRepo);

    final trip = createTrip('1', 'TestTrip'); // 👈 Usamos helper corregido
    repo.upsert(trip);

    await tester.pumpWidget(
      MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          sesionIniciada: false,
          viajes: const [],
          tripRepo: repo,
          tripService: tripService,
          entryRepo: entryRepo,
          entryService: entryService,
          userRepo: userRepo,
          userService: userService,
          skipLogin: true,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('TestTrip'));
    await tester.pumpAndSettle();

    expect(find.byType(Pantalla_Viaje), findsOneWidget);
  });
}
