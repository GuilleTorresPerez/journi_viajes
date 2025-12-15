import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';
import 'package:journi/estadisticasScreen.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:drift/native.dart';

import 'fake_geocoding_repository.dart';

Widget wrap(Widget widget) {
  return MaterialApp(home: widget);
}

void main(){
  testWidgets('Muestra tarjeta de estadísticas con título', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final userRepo = DriftUserRepository(db);
    final userService = makeUserService(userRepo);

    final tripRepo = InMemoryTripRepository();
    final entryRepo = InMemoryEntryRepository();

    final screen = EstadisticasScreen(
      selectedIndex: 3,
      sesionIniciada: true,
      viajes: [],
      tripRepo: tripRepo,
      entryRepo: entryRepo,
      tripService: makeTripService(tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
      entryService: makeEntryService(entryRepo),
      userRepo: userRepo,
      userService: userService,
      currentUser: null,
    );

    await tester.pumpWidget(wrap(screen));

    // El título de la tarjeta existe
    expect(find.text('Duración de cada viaje (días)'), findsOneWidget);
    expect(find.text('Destinos visitados'), findsOneWidget);

    await db.close();
  });

  testWidgets('Muestra BarChart cuando hay viajes', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final userRepo = DriftUserRepository(db);
    final viajes = [
      Trip(
        id: '1',
        title: 'Italia',
        description: '',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
        ownerId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final screen = EstadisticasScreen(
      selectedIndex: 3,
      sesionIniciada: true,
      viajes: viajes,
      tripRepo: InMemoryTripRepository(),
      entryRepo: InMemoryEntryRepository(),
      tripService: makeTripService(
          InMemoryTripRepository(), userRepo, InMemoryEntryRepository(), FakeGeocodingRepository()),
      entryService: makeEntryService(InMemoryEntryRepository()),
      userRepo: userRepo,
      userService: makeUserService(userRepo),
      currentUser: null,
    );

    await tester.pumpWidget(wrap(screen));

    // BarChart existe
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('Muestra PieChart cuando hay viajes', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final userRepo = DriftUserRepository(db);

    final viajes = [
      Trip(
        id: '1',
        title: 'Francia',
        description: '',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 10),
        ownerId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    final screen = EstadisticasScreen(
      selectedIndex: 3,
      sesionIniciada: true,
      viajes: viajes,
      tripRepo: InMemoryTripRepository(),
      entryRepo: InMemoryEntryRepository(),
      tripService: makeTripService(
          InMemoryTripRepository(), userRepo, InMemoryEntryRepository(), FakeGeocodingRepository()),
      entryService: makeEntryService(InMemoryEntryRepository()),
      userRepo: userRepo,
      userService: makeUserService(userRepo),
      currentUser: null,
    );

    await tester.pumpWidget(wrap(screen));

    // PieChart existe
    expect(find.byType(PieChart), findsOneWidget);
  });

}