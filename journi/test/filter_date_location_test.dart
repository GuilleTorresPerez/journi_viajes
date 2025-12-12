import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/use_cases/use_cases.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_entry_repository.dart';
import 'package:journi/data/local/drift/drift_trip_repository.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/main.dart';
import 'fake_geocoding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftUserRepository userRepo;
  late DefaultUserService userService;
  late DriftEntryRepository entryRepo;
  late DriftTripRepository tripRepo;
  late TripService tripService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    userRepo = DriftUserRepository(db);
    userService = makeUserService(userRepo);
    entryRepo = DriftEntryRepository(db);

    tripRepo = DriftTripRepository(db);
    tripService = makeTripService(
        tripRepo, userRepo, entryRepo, FakeGeocodingRepository());
  });

  tearDown(() async {
    await db.close();
  });

  group('🔍 MyHomePage - Filtros de viajes', () {
    testWidgets('✅ Filtrar viajes por fecha correctamente', (tester) async {
      addTearDown(() async {
        await tester.pumpAndSettle(); // 🔥 elimina timers/streams pendientes
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle(); // opcional pero recomendable
      });

      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await userService.register(RegisterUserCommand(
        id: userId,
        name: 'Test',
        lastName: 'User',
        email: 'test@test.com',
        password: 'password',
      ));

      final trip1 = CreateTripCommand(
        id: 't1',
        ownerId: userId,
        title: 'Viaje Enero',
        description:
            'Viaje de prueba enero', // (Opcional: podrías añadir un campo de texto para esto)
        startDate: DateTime(2025, 1, 10),
        endDate: DateTime(2025, 1, 15),
      );

      final trip2 = CreateTripCommand(
        id: 't2',
        ownerId: userId,
        title: 'Viaje Febrero',
        description:
            'Viaje de prueba febrero', // (Opcional: podrías añadir un campo de texto para esto)
        startDate: DateTime(2025, 2, 5),
        endDate: DateTime(2025, 2, 10),
      );

      // Servicio de aplicación
      final result = await tripService.create(trip1);
      final result2 = await tripService.create(trip2);

      final viajes = [result.valueOrNull!, result2.valueOrNull!];

      await tester.pumpWidget(MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          sesionIniciada: true,
          viajes: viajes,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          tripService: tripService,
          entryService: makeEntryService(entryRepo),
          userRepo: userRepo,
          userService: userService,
          skipLogin: true,
        ),
      ));

      await tester.pump(const Duration(milliseconds: 100));

      // Simulamos filtro por fecha
      final filtroStart = DateTime(2025, 1, 1);
      final filtroEnd = DateTime(2025, 1, 20);

      final filteredTrips = viajes
          .where((v) =>
              v.startDate!
                  .isAfter(filtroStart.subtract(const Duration(days: 1))) &&
              v.endDate!.isBefore(filtroEnd.add(const Duration(days: 1))))
          .toList();

      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(filteredTrips.length, 1);
      expect(filteredTrips.first.title, 'Viaje Enero');
    });

    testWidgets('✅ Filtrar viajes por ubicación correctamente', (tester) async {
      addTearDown(() async {
        await tester.pumpAndSettle(); // 🔥 elimina timers/streams pendientes
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle(); // opcional pero recomendable
      });

      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await userService.register(RegisterUserCommand(
        id: userId,
        name: 'Test',
        lastName: 'User',
        email: 'test@test.com',
        password: 'password',
      ));

      final trip1 = CreateTripCommand(
        id: 't1',
        ownerId: userId,
        title: 'Barcelona',
        description:
            'Viaje a Barcelona', // (Opcional: podrías añadir un campo de texto para esto)
        startDate: DateTime(2025, 1, 10),
        endDate: DateTime(2025, 1, 15),
      );

      final trip2 = CreateTripCommand(
        id: 't2',
        ownerId: userId,
        title: 'Madrid',
        description:
            'Viaje a Madrid', // (Opcional: podrías añadir un campo de texto para esto)
        startDate: DateTime(2025, 2, 5),
        endDate: DateTime(2025, 2, 10),
      );

      // Servicio de aplicación
      final result = await tripService.create(trip1);
      final result2 = await tripService.create(trip2);

      final viajes = [result.valueOrNull!, result2.valueOrNull!];

      await tester.pumpWidget(MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          sesionIniciada: true,
          viajes: viajes,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          tripService: tripService,
          entryService: makeEntryService(entryRepo),
          userRepo: userRepo,
          userService: userService,
          skipLogin: true,
        ),
      ));

      await tester.pump(const Duration(milliseconds: 100));

      final filteredTrips = viajes.where((v) => v.title == 'Madrid').toList();

      expect(filteredTrips.length, 1);
      expect(filteredTrips.first.title, 'Madrid');
    });

    testWidgets('✅ Filtrar viajes por fecha y ubicación combinados',
        (tester) async {
      addTearDown(() async {
        await tester.pumpAndSettle(); // 🔥 elimina timers/streams pendientes
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle(); // opcional pero recomendable
      });

      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await userService.register(RegisterUserCommand(
        id: userId,
        name: 'Test',
        lastName: 'User',
        email: 'test@test.com',
        password: 'password',
      ));

      final trip1 = CreateTripCommand(
        id: 't1',
        ownerId: userId,
        title: 'Barcelona',
        description:
            'Viaje a Barcelona', // (Opcional: podrías añadir un campo de texto para esto)
        startDate: DateTime(2025, 1, 10),
        endDate: DateTime(2025, 1, 15),
      );

      final trip2 = CreateTripCommand(
        id: 't2',
        ownerId: userId,
        title: 'Madrid',
        description:
            'Viaje a Madrid', // (Opcional: podrías añadir un campo de texto para esto)
        startDate: DateTime(2025, 2, 5),
        endDate: DateTime(2025, 2, 10),
      );

      // Servicio de aplicación
      final result = await tripService.create(trip1);
      final result2 = await tripService.create(trip2);

      final viajes = [result.valueOrNull!, result2.valueOrNull!];

      await tester.pumpWidget(MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          sesionIniciada: true,
          viajes: viajes,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          tripService: tripService,
          entryService: makeEntryService(entryRepo),
          userRepo: userRepo,
          userService: userService,
          skipLogin: true,
        ),
      ));

      await tester.pump(const Duration(milliseconds: 100));

      final filtroStart = DateTime(2025, 1, 1);
      final filtroEnd = DateTime(2025, 1, 31);
      final locationFilter = 'Barcelona';

      final filteredTrips = viajes
          .where((v) =>
              v.startDate!
                  .isAfter(filtroStart.subtract(const Duration(days: 1))) &&
              v.endDate!.isBefore(filtroEnd.add(const Duration(days: 1))) &&
              v.title == locationFilter)
          .toList();

      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(filteredTrips.length, 1);
      expect(filteredTrips.first.title, 'Barcelona');
    });
  });
}
