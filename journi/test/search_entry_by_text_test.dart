import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/pantalla_viaje.dart';
import 'package:journi/domain/entry.dart';

import 'fake_geocoding_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftUserRepository userRepo;
  late DefaultUserService userService;
  late DefaultEntryService entryService;

  late InMemoryTripRepository tripRepo;
  late InMemoryEntryRepository entryRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    userRepo = DriftUserRepository(db);
    userService = makeUserService(userRepo);

    tripRepo = InMemoryTripRepository();
    entryRepo = InMemoryEntryRepository();
    entryService = makeEntryService(entryRepo);
  });

  tearDown(() async {
    await db.close();
  });

  group('🔍 Pantalla_Viaje - Búsqueda por texto', () {
    testWidgets('✅ Filtrar entradas por texto correctamente',
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
          id: '1',
          title: 'Viaje Test',
          description: 'Test',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 5),
          ownerId: generatedId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ];

      // Añadimos entradas de texto
      final entry1 = Entry.create(
        id: 'e1',
        tripId: '1',
        type: EntryType.note,
        text: 'Primera nota de prueba',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: [],
      );

      final entry2 = Entry.create(
        id: 'e2',
        tripId: '1',
        type: EntryType.note,
        text: 'Segunda nota diferente',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: [],
      );

      final entry11 = CreateEntryCommand(
        id: UniqueKey().toString(),
        tripId: '1',
        type: EntryType.note,
        text: 'Primera nota de prueba',
      );

      final entry22 = CreateEntryCommand(
        id: UniqueKey().toString(),
        tripId: '1',
        type: EntryType.note,
        text: 'Segunda nota diferente',
      );

      await entryService.create(entry11);
      await entryService.create(entry22);

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            selectedIndex: 0,
            sesionIniciada: true,
            viajes: viajes,
            num_viaje: 0,
            repo: tripRepo,
            entryRepo: entryRepo,
            tripService: makeTripService(
                tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
            entryService: makeEntryService(entryRepo),
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el diálogo de búsqueda
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Introducir texto a buscar
      await tester.enterText(find.byType(TextField), 'Primera');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      // Comprobamos que solo aparece la entrada que coincide
      expect(find.text('Primera nota de prueba'), findsOneWidget);
      expect(find.text('Segunda nota diferente'), findsNothing);

      // Deshacer búsqueda
      await tester.tap(find.text('Deshacer búsqueda'));
      await tester.pumpAndSettle();

      // Comprobamos que ambas entradas vuelven a aparecer
      expect(find.text('Primera nota de prueba'), findsOneWidget);
      expect(find.text('Segunda nota diferente'), findsOneWidget);
    });

    testWidgets('❌ Búsqueda sin coincidencias muestra lista vacía',
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
          id: '1',
          title: 'Viaje Test',
          description: 'Test',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 5),
          ownerId: generatedId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ];

      // Añadimos entrada de texto
      final entryy = CreateEntryCommand(
        id: UniqueKey().toString(),
        tripId: '1',
        type: EntryType.note,
        text: 'Texto existente',
      );

      await entryService.create(entryy);

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            selectedIndex: 0,
            sesionIniciada: true,
            viajes: viajes,
            num_viaje: 0,
            repo: tripRepo,
            entryRepo: entryRepo,
            tripService: makeTripService(
                tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
            entryService: makeEntryService(entryRepo),
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir diálogo de búsqueda
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Buscar texto que no existe
      await tester.enterText(find.byType(TextField), 'NoExiste');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      // Comprobamos que no aparece ninguna entrada
      expect(find.text('Texto existente'), findsNothing);
      expect(find.text('Aún no has añadido contenido.'), findsOneWidget);
    });
  });
}
