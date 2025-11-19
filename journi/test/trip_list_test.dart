import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/main.dart';
import 'package:journi/pantalla_viaje.dart';

void main() {
  final db = AppDatabase();
  testWidgets('Muestra CircularProgressIndicator mientras se cargan los viajes',
      (tester) async {
    // Simulamos un stream que todavía no ha emitido nada
    final repo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final tripService = makeTripService(repo);
    final entryService = makeEntryService(entryRepo);

    final userRepo = DriftUserRepository(db);
    final userService = makeUserService(userRepo);

    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(
        title: 'JOURNI',
        inicionSesiada: false,
        tripRepo: repo,
        tripService: tripService,
        entryRepo: entryRepo,
        entryService: entryService,
        userRepo: userRepo,
        userService: userService,
      ),
    ));

    // Como aún no hay datos, debería mostrar el indicador
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Muestra mensaje si no hay viajes registrados', (tester) async {
    final repo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final tripService = makeTripService(repo);
    final entryService = makeEntryService(entryRepo);
    final userRepo = DriftUserRepository(db);
    final userService = makeUserService(userRepo);

    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(
        title: 'JOURNI',
        inicionSesiada: false,
        tripRepo: repo,
        tripService: tripService,
        entryRepo: entryRepo,
        entryService: entryService,
        userRepo: userRepo,
        userService: userService,
      ),
    ));

    await tester.pump(); // dejar que StreamBuilder se actualice

    expect(find.text('No tienes ningún viaje registrado.'), findsOneWidget);
  });

  testWidgets('Renderiza la lista de viajes correctamente', (tester) async {
    final repo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final tripService = makeTripService(repo);
    final entryService = makeEntryService(entryRepo);
    final userRepo = DriftUserRepository(db);
    final userService = makeUserService(userRepo);

    // Insertamos algunos viajes
    final trip1 = Trip(
      id: '1',
      title: 'Madrid',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 5),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final trip2 = Trip(
      id: '2',
      title: 'Barcelona',
      startDate: DateTime(2025, 2, 1),
      endDate: DateTime(2025, 2, 10),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    repo.upsert(trip1);
    repo.upsert(trip2);

    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(
        title: 'JOURNI',
        inicionSesiada: false,
        tripRepo: repo,
        tripService: tripService,
        entryRepo: entryRepo,
        entryService: entryService,
        userRepo: userRepo,
        userService: userService,
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Madrid'), findsOneWidget);
    expect(find.text('Barcelona'), findsOneWidget);
  });

  testWidgets('Al pulsar un viaje navega a Pantalla_Viaje', (tester) async {
    final repo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final tripService = makeTripService(repo);
    final entryService = makeEntryService(entryRepo);
    final userRepo = DriftUserRepository(db);
    final userService = makeUserService(userRepo);

    final trip = Trip(
      id: '1',
      title: 'TestTrip',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    repo.upsert(trip);

    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(
        title: 'JOURNI',
        inicionSesiada: false,
        tripRepo: repo,
        tripService: tripService,
        entryRepo: entryRepo,
        entryService: entryService,
        userRepo: userRepo,
        userService: userService,
      ),
    ));

    await tester.pumpAndSettle();

    // Pulsamos el ListTile
    await tester.tap(find.text('TestTrip'));
    await tester.pumpAndSettle();

    // Verificamos que se ha navegado a la nueva pantalla
    expect(find.byType(Pantalla_Viaje), findsOneWidget);
  });
}
