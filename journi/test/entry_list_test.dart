import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';

import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/pantalla_viaje.dart';
import 'fake_geocoding_repository.dart';

void main() {
  final db =
      AppDatabase(); // Nota: Mejor usar .forTesting(memory) aquí también si es posible

  // Helper para crear trips válidos en los tests de UI
  Trip createTestTrip() {
    return Trip(
        id: '1',
        ownerId: 'u1', // 👈 CORREGIDO
        title: 'Viaje Test',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 5),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: {'u1': TripRole.admin} // Opcional, pero consistente
        );
  }

  testWidgets(
    'Muestra CircularProgressIndicator mientras se cargan las entradas',
    (tester) async {
      final tripRepo = InMemoryTripRepository();
      final entryRepo = InMemoryEntryRepository();
      final geoRepo = FakeGeocodingRepository();
      final UserRepository userRepo = DriftUserRepository(db);
      final tripService =
          makeTripService(tripRepo, userRepo, entryRepo, geoRepo);
      final entryService = makeEntryService(entryRepo);
      final userService = makeUserService(userRepo);
      User? _currentUser;

      final trip = createTestTrip(); // 👈 Usamos el helper corregido
      tripRepo.upsert(trip);

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            selectedIndex: 0,
            sesionIniciada: false,
            viajes: [trip],
            num_viaje: 0,
            repo: tripRepo,
            entryRepo: entryRepo,
            tripService: tripService,
            entryService: entryService,
            userRepo: userRepo,
            userService: userService,
            currentUser: _currentUser,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('Muestra mensaje si no hay entradas registradas', (tester) async {
    final tripRepo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final geoRepo = FakeGeocodingRepository();
    final userRepo = DriftUserRepository(db);
    final tripService = makeTripService(tripRepo, userRepo, entryRepo, geoRepo);
    final entryService = makeEntryService(entryRepo);
    final userService = makeUserService(userRepo);
    User? _currentUser;

    final trip = createTestTrip(); // 👈 Usamos el helper corregido
    tripRepo.upsert(trip);

    await tester.pumpWidget(
      MaterialApp(
        home: Pantalla_Viaje(
          selectedIndex: 0,
          sesionIniciada: false,
          viajes: [trip],
          num_viaje: 0,
          repo: tripRepo,
          entryRepo: entryRepo,
          tripService: tripService,
          entryService: entryService,
          userRepo: userRepo,
          userService: userService,
          currentUser: _currentUser,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aún no has añadido contenido.'), findsOneWidget);
  });

  testWidgets('Renderiza lista de entradas correctamente', (tester) async {
    final tripRepo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final geoRepo = FakeGeocodingRepository();
    final UserRepository userRepo = DriftUserRepository(db);
    final tripService = makeTripService(tripRepo, userRepo, entryRepo, geoRepo);
    final userService = makeUserService(userRepo);
    final entryService = makeEntryService(entryRepo);
    User? _currentUser;

    final trip = createTestTrip(); // 👈 Usamos el helper corregido
    tripRepo.upsert(trip);

    final e1 = Entry.create(
      id: 'e1',
      tripId: trip.id,
      type: EntryType.note,
      text: 'Texto de prueba',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final e2 = Entry.create(
      id: 'e2',
      tripId: trip.id,
      type: EntryType.note,
      text: 'Madrid',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (e1 is Ok<Entry>) entryRepo.upsert(e1.value);
    if (e2 is Ok<Entry>) entryRepo.upsert(e2.value);

    await tester.pumpWidget(
      MaterialApp(
        home: Pantalla_Viaje(
          selectedIndex: 0,
          sesionIniciada: false,
          viajes: [trip],
          num_viaje: 0,
          repo: tripRepo,
          entryRepo: entryRepo,
          tripService: tripService,
          entryService: entryService,
          userRepo: userRepo,
          userService: userService,
          currentUser: _currentUser,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Texto de prueba'), findsOneWidget);
    expect(find.textContaining('Madrid'), findsOneWidget);
  });

  testWidgets('Elimina una entrada al pulsar el icono de borrar',
      (tester) async {
    final tripRepo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();
    final geoRepo = FakeGeocodingRepository();
    final UserRepository userRepo = DriftUserRepository(db);
    final tripService = makeTripService(tripRepo, userRepo, entryRepo, geoRepo);
    final entryService = makeEntryService(entryRepo);
    final userService = makeUserService(userRepo);
    User? _currentUser;

    final trip = createTestTrip(); // 👈 Usamos el helper corregido
    tripRepo.upsert(trip);

    final e = Entry.create(
      id: 'e1',
      tripId: trip.id,
      type: EntryType.note,
      text: 'Borrar esto',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (e is Ok<Entry>) entryRepo.upsert(e.value);

    await tester.pumpWidget(
      MaterialApp(
        home: Pantalla_Viaje(
          selectedIndex: 0,
          sesionIniciada: false,
          viajes: [trip],
          num_viaje: 0,
          repo: tripRepo,
          entryRepo: entryRepo,
          tripService: tripService,
          entryService: entryService,
          userRepo: userRepo,
          userService: userService,
          currentUser: _currentUser,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Borrar esto'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Borrar esto'), findsNothing);
  });
}
