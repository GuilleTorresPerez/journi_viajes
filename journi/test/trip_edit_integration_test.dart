import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/editar_viaje.dart';
import 'package:journi/main.dart';
import 'package:journi/pantalla_viaje.dart';

import 'fake_geocoding_repository.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpUntilFound(Finder finder, WidgetTester tester,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (any(finder)) return;
    }
    throw Exception(
        'Widget ${finder.description} no encontrado tras ${timeout.inSeconds}s');
  }
}

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

  testWidgets('Editar viaje correctamente', (WidgetTester tester) async {
    final generatedId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final cmd = RegisterUserCommand(
      id: generatedId,
      name: "nombre",
      lastName: "apellidos",
      email: "email@gmail.com",
      password: "password",
    );

    final result = await userService.register(cmd);

    final viajes = [
      Trip(
        id: "1",
        title: "Italia",
        description: "Roma",
        startDate: DateTime(2024, 1, 10),
        endDate: DateTime(2024, 1, 15),
        ownerId: generatedId,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Editar_viaje(
        selectedIndex: 0,
        num_viaje: 0,
        viajes: viajes,
        sesionIniciada: true,
        repo: tripRepo,
        entryRepo: entryRepo,
        tripService: makeTripService(
            tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
        entryService: makeEntryService(entryRepo),
        userRepo: userRepo,
        userService: userService,
        currentUser: result.valueOrNull,
      ),
    ));

    // Cambiamos los datos
    await tester.enterText(
        find.byKey(const Key('tituloField')), 'Viaje Editado');
    await tester.enterText(
        find.byKey(const Key('fechaIniField')), '05-01-2025');
    await tester.enterText(
        find.byKey(const Key('fechaFinField')), '15-01-2025');

    await tester.tap(find.byKey(const Key('guardarButton')));
    await tester.pump();                    // dispara el onPressed
    await tester.pump(const Duration(milliseconds: 500));

    // Verificar SnackBar de éxito
    expect(find.byKey(const Key('snackbar_ok')), findsOneWidget);

    // Verificar cambios en repo
    final updatedTrip = await tripRepo.findById("1");
    expect(updatedTrip.valueOrNull?.title, 'Viaje Editado');
    expect(updatedTrip.valueOrNull?.startDate, DateTime(2025, 1, 5));
    expect(updatedTrip.valueOrNull?.endDate, DateTime(2025, 1, 15));
  });

  testWidgets('Editar viaje con fecha inicio posterior a fin muestra error',
      (WidgetTester tester) async {
    final generatedId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final cmd = RegisterUserCommand(
      id: generatedId,
      name: "nombre",
      lastName: "apellidos",
      email: "email@gmail.com",
      password: "password",
    );

    final result = await userService.register(cmd);

    final viajes = [
      Trip(
        id: "1",
        title: "Italia",
        description: "Roma",
        startDate: DateTime(2024, 1, 10),
        endDate: DateTime(2024, 1, 15),
        ownerId: generatedId,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Editar_viaje(
        selectedIndex: 0,
        num_viaje: 0,
        viajes: viajes,
        sesionIniciada: true,
        repo: tripRepo,
        entryRepo: entryRepo,
        tripService: makeTripService(
            tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
        entryService: makeEntryService(entryRepo),
        userRepo: userRepo,
        userService: userService,
        currentUser: result.valueOrNull,
      ),
    ));

    // Introducimos fecha inicio posterior a fecha fin
    await tester.enterText(
        find.byKey(const Key('fechaIniField')), '20-01-2025');
    await tester.enterText(
        find.byKey(const Key('fechaFinField')), '15-01-2025');
    await tester.tap(find.byKey(const Key('guardarButton')));
    await tester.pumpAndSettle();

    // Verificar que aparece el diálogo de error
    expect(find.text('La fecha de inicio no puede ser posterior a la final'),
        findsOneWidget);
    expect(find.text('Viaje actualizado correctamente'), findsNothing);
  });
}
