import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/crear_viaje.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/editar_viaje.dart';
import 'package:journi/estadisticasScreen.dart';
import 'package:journi/login_screen.dart';
import 'package:journi/main.dart';
import 'package:journi/map_screen.dart';
import 'package:journi/mi_perfil.dart';
import 'package:journi/pantalla_viaje.dart';
import 'package:journi/domain/entry.dart';

import 'fake_geocoding_repository.dart';

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

  group('Barra de navegación de main - Navegación entre pantallas', () {
    testWidgets('Pantalla main a 0', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: true,
            viajes: viajes,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            tripService: makeTripService(
                tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
            entryService: makeEntryService(entryRepo),
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
            skipLogin: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Pantalla main a 1', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: true,
            viajes: viajes,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            tripService: makeTripService(
                tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
            entryService: makeEntryService(entryRepo),
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
            skipLogin: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MapaPaisScreen), findsOneWidget);
    });
    testWidgets('Pantalla main a 2', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: true,
            viajes: viajes,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            tripService: makeTripService(
                tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
            entryService: makeEntryService(entryRepo),
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
            skipLogin: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byKey(Key('addButton')));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Crear_Viaje), findsOneWidget);
    });
    testWidgets('Pantalla main a 3', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: true,
            viajes: viajes,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            tripService: makeTripService(
                tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
            entryService: makeEntryService(entryRepo),
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
            skipLogin: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.equalizer));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(EstadisticasScreen), findsOneWidget);
    });
    testWidgets('Pantalla main a 4', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: true,
            viajes: viajes,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            tripService: makeTripService(
                tripRepo, userRepo, entryRepo, FakeGeocodingRepository()),
            entryService: makeEntryService(entryRepo),
            userRepo: userRepo,
            userService: userService,
            currentUser: result.valueOrNull,
            skipLogin: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MiPerfil), findsOneWidget);
    });
  });

  // PANTALLA_VIAJE

  group('Barra de navegación de pantalla_viaje - Navegación entre pantallas',
      () {
    testWidgets('Pantalla pantalla_viaje a 0', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Pantalla_Viaje), findsNothing);
    });

    testWidgets('Pantalla pantalla_viaje a 1', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MapaPaisScreen), findsOneWidget);
    });
    testWidgets('Pantalla pantalla_viaje a 2', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Crear_Viaje), findsOneWidget);
    });
    testWidgets('Pantalla pantalla_viaje a 3', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.equalizer));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(EstadisticasScreen), findsOneWidget);
    });
    testWidgets('Pantalla pantalla_viaje a 4', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Pantalla_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MiPerfil), findsOneWidget);
    });
  });

  group('Barra de navegación de crear_viaje - Navegación entre pantallas', () {
    testWidgets('Pantalla crear_viaje a 0', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Crear_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Pantalla crear_viaje a 1', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Crear_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MapaPaisScreen), findsOneWidget);
    });
    testWidgets('Pantalla crear_viaje a 2', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Crear_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byKey(Key('tituloField')));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Crear_Viaje), findsOneWidget);
    });
    testWidgets('Pantalla crear_viaje a 3', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Crear_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.equalizer));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(EstadisticasScreen), findsOneWidget);
    });
    testWidgets('Pantalla crear_viaje a 4', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Crear_Viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MiPerfil), findsOneWidget);
    });
  });

  group('Barra de navegación de editar_viaje - Navegación entre pantallas', () {
    testWidgets('Pantalla editar_viaje a 0', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Editar_viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Pantalla editar_viaje a 1', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Editar_viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MapaPaisScreen), findsOneWidget);
    });
    testWidgets('Pantalla editar_viaje a 2', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Editar_viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Crear_Viaje), findsOneWidget);
    });
    testWidgets('Pantalla editar_viaje a 3', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Editar_viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.equalizer));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(EstadisticasScreen), findsOneWidget);
    });
    testWidgets('Pantalla editar_viaje a 4', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Editar_viaje(
            sesionIniciada: true,
            selectedIndex: 0,
            num_viaje: 0,
            viajes: viajes,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MiPerfil), findsOneWidget);
    });
  });

  group('Barra de navegación de map_screen - Navegación entre pantallas', () {
    testWidgets('Pantalla map_screen a 0', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MapaPaisScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Pantalla map_screen a 1', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MapaPaisScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byKey(Key('button1')));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MapaPaisScreen), findsOneWidget);
    });
    testWidgets('Pantalla map_screen a 2', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MapaPaisScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Crear_Viaje), findsOneWidget);
    });
    testWidgets('Pantalla map_screen a 3', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MapaPaisScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.equalizer));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(EstadisticasScreen), findsOneWidget);
    });
    testWidgets('Pantalla map_screen a 4', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MapaPaisScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MiPerfil), findsOneWidget);
    });
  });

  group('Barra de navegación de estadisticas - Navegación entre pantallas', () {
    testWidgets('Pantalla estadisticas a 0', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: EstadisticasScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Pantalla estadisticas a 1', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: EstadisticasScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MapaPaisScreen), findsOneWidget);
    });
    testWidgets('Pantalla estadisticas a 2', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: EstadisticasScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Crear_Viaje), findsOneWidget);
    });

    testWidgets('Pantalla estadisticas a 3', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: EstadisticasScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.equalizer));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(EstadisticasScreen), findsOneWidget);
    });

    testWidgets('Pantalla estadisticas a 4', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: EstadisticasScreen(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MiPerfil), findsOneWidget);
    });
  });

  group('Barra de navegación de mi_perfil - Navegación entre pantallas', () {
    testWidgets('Pantalla mi_perfil a 0', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MiPerfil(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.folder));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('Pantalla mi_perfil a 1', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MiPerfil(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MapaPaisScreen), findsOneWidget);
    });

    testWidgets('Pantalla mi_perfil a 2', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MiPerfil(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(Crear_Viaje), findsOneWidget);
    });
    testWidgets('Pantalla mi_perfil a 3', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MiPerfil(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byIcon(Icons.equalizer));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(EstadisticasScreen), findsOneWidget);
    });
    testWidgets('Pantalla mi_perfil a 4', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: MiPerfil(
            sesionIniciada: true,
            selectedIndex: 0,
            viajes: viajes,
            tripRepo: tripRepo,
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

      // Abrir el diálogo de añadir texto
      await tester.tap(find.byKey(Key('button4')));
      await tester.pumpAndSettle();

      // Comprobamos que el SnackBar aparece
      expect(find.byType(MiPerfil), findsOneWidget);
    });
  });
}
