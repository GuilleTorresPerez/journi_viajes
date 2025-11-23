import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧭 Pruebas de integración: Listar_Viaje', () {
    late InMemoryTripRepository tripRepo;
    late InMemoryEntryRepository entryRepo;
    late DefaultTripService tripService;
    late DefaultEntryService entryService;
    final db = AppDatabase();
    final userRepo = DriftUserRepository(db);
    final userService = makeUserService(userRepo);

    setUp(() {
      tripRepo = InMemoryTripRepository();
      entryRepo = InMemoryEntryRepository();
      tripService = DefaultTripService(repo: tripRepo);
      entryService = DefaultEntryService(repo: entryRepo);
    });

    testWidgets('✅ Viaje listado correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(
            title: 'JOURNI',
            sesionIniciada: false,
            viajes: [],
            tripService: tripService,
            entryService: entryService,
            tripRepo: tripRepo,
            entryRepo: entryRepo,
            userRepo: userRepo,
            userService: userService,
          ),
        ),
      );

      // Pulsa el BottomNavigationBarItem "Nuevo viaje"
      await tester.tap(find.byKey(const Key('anadirButton')));
      await tester.pumpAndSettle();

      // 🧩 Rellenar los campos
      await tester.enterText(
        find.byKey(const Key('tituloField')),
        'Vacaciones 2025',
      );
      await tester.enterText(
        find.byKey(const Key('fechaIniField')),
        '01-01-2025',
      );
      await tester.enterText(
        find.byKey(const Key('fechaFinField')),
        '10-01-2025',
      );

      await tester.tap(find.byKey(const Key('guardarButton')));
      await tester.pumpAndSettle(
        const Duration(seconds: 1),
      ); // Espera a que el SnackBar aparezca

      // ✅ Verificar éxito
      // Verifica que la pantalla principal está visible
      expect(find.byType(MyHomePage), findsOneWidget);
      expect(find.byKey(const Key('id0')), findsOneWidget);
    });

    testWidgets(
      '❌ Error: El usuario ha cancelado la creacion, por lo que no se lista nada',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MyHomePage(
              title: 'JOURNI',
              sesionIniciada: false,
              viajes: [],
              tripService: tripService,
              entryService: entryService,
              tripRepo: tripRepo,
              entryRepo: entryRepo,
              userRepo: userRepo,
              userService: userService,
            ),
          ),
        );

        // Pulsa el BottomNavigationBarItem "Nuevo viaje"
        await tester.tap(find.byKey(const Key('anadirButton')));
        await tester.pumpAndSettle();

        // 🧩 Rellenar los campos
        await tester.enterText(
          find.byKey(const Key('tituloField')),
          'Vacaciones 2025',
        );
        await tester.enterText(
          find.byKey(const Key('fechaIniField')),
          '01-01-2025',
        );
        await tester.enterText(
          find.byKey(const Key('fechaFinField')),
          '10-01-2025',
        );

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle(
          const Duration(seconds: 1),
        ); // Espera a que el SnackBar aparezca

        // ✅ Verificar éxito
        // Verifica que la pantalla principal está visible
        expect(find.byType(MyHomePage), findsOneWidget);
        expect(find.byKey(const Key('id0')), findsNothing);
      },
    );
  });
}
