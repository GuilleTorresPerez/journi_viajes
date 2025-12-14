import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';
import 'package:journi/editar_viaje.dart';

import 'fake_geocoding_repository.dart';

DateTime _dateOnlyLocal(DateTime dt) {
  final l = dt.toLocal();
  return DateTime(l.year, l.month, l.day);
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
    final uniqueEmail =
        'email_${DateTime.now().millisecondsSinceEpoch}@gmail.com';

    final cmd = RegisterUserCommand(
      id: generatedId,
      name: "nombre",
      lastName: "apellidos",
      email: uniqueEmail,
      password: "password",
    );

    final reg = await userService.register(cmd);
    expect(reg, isA<Ok<User>>(), reason: 'El registro debe ser correcto');
    final currentUser = (reg as Ok<User>).value;

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

    await tripRepo.upsert(viajes[0]);

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
        currentUser: currentUser,
      ),
    ));

    // Cambiamos los datos
    await tester.enterText(find.byKey(const Key('tituloField')), 'Viaje Editado');
    await tester.enterText(find.byKey(const Key('fechaIniField')), '05-01-2025');
    await tester.enterText(find.byKey(const Key('fechaFinField')), '15-01-2025');

    await tester.tap(find.byKey(const Key('guardarButton')));
    await tester.pump(); // deja que muestre SnackBar

    // SnackBar (más estable por key que por texto)
    expect(find.byKey(const Key('snackbar_ok')), findsOneWidget);

    // deja terminar el flujo (hay delayed + Navigator.pop)
    await tester.pumpAndSettle();

    // Verificar cambios en repo
    final updatedTripRes = await tripRepo.findById("1");
    final updatedTrip = updatedTripRes.valueOrNull;
    expect(updatedTrip, isNotNull);

    expect(updatedTrip!.title, 'Viaje Editado');

    // ✅ Comparación robusta ignorando zona horaria (UTC vs local)
    expect(_dateOnlyLocal(updatedTrip.startDate!), DateTime(2025, 1, 5));
    expect(_dateOnlyLocal(updatedTrip.endDate!), DateTime(2025, 1, 15));
  });

  testWidgets('Editar viaje con fecha inicio posterior a fin muestra error',
          (WidgetTester tester) async {
        final generatedId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        final uniqueEmail =
            'email_${DateTime.now().millisecondsSinceEpoch}@gmail.com';

        final cmd = RegisterUserCommand(
          id: generatedId,
          name: "nombre",
          lastName: "apellidos",
          email: uniqueEmail,
          password: "password",
        );

        final reg = await userService.register(cmd);
        expect(reg, isA<Ok<User>>(), reason: 'El registro debe ser correcto');
        final currentUser = (reg as Ok<User>).value;

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

        await tripRepo.upsert(viajes[0]);

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
            currentUser: currentUser,
          ),
        ));

        await tester.enterText(find.byKey(const Key('fechaIniField')), '20-01-2025');
        await tester.enterText(find.byKey(const Key('fechaFinField')), '15-01-2025');

        await tester.tap(find.byKey(const Key('guardarButton')));
        await tester.pumpAndSettle();

        expect(find.text('La fecha de inicio no puede ser posterior a la final'),
            findsOneWidget);

        // No debe aparecer el OK
        expect(find.byKey(const Key('snackbar_ok')), findsNothing);
      });
}
