import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/main.dart';

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
  // 🔧 Inicializa el entorno de test (sustituye al antiguo IntegrationTestWidgetsFlutterBinding)
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧭 Pruebas de integración: Eliminar_viaje', () {
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

    testWidgets('✅ Eliminar viaje correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          inicionSesiada: false,
          tripService: tripService,
          entryService: entryService,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          userRepo: userRepo,
          userService: userService,
        ),
      ));

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
          const Duration(seconds: 1)); // Espera a que el SnackBar aparezca

      await tester.tap(find.byKey(const Key('anadirButton')));
      await tester.pumpAndSettle();

      // 🧩 Rellenar los campos
      await tester.enterText(
        find.byKey(const Key('tituloField')),
        'Vacaciones 2026',
      );
      await tester.enterText(
        find.byKey(const Key('fechaIniField')),
        '01-02-2025',
      );
      await tester.enterText(
        find.byKey(const Key('fechaFinField')),
        '10-02-2025',
      );

      await tester.tap(find.byKey(const Key('guardarButton')));
      await tester.pumpAndSettle(
          const Duration(seconds: 1)); // Espera a que el SnackBar aparezca

      await tester.tap(find.byKey(const Key('id0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('aceptarButton')));

      await tester.pumpAndSettle();
      // ✅ Verificar éxito
      // Verifica que la pantalla principal está visible
      expectLater(find.byKey(const Key('id0')), findsAny);
    });

    testWidgets('❌ No se elimina viaje porque se cancela',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MyHomePage(
          title: 'JOURNI',
          inicionSesiada: false,
          tripService: tripService,
          entryService: entryService,
          tripRepo: tripRepo,
          entryRepo: entryRepo,
          userRepo: userRepo,
          userService: userService,
        ),
      ));

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
          const Duration(seconds: 1)); // Espera a que el SnackBar aparezca
      await tester.tap(find.byKey(const Key('id0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelarButton')));

      await tester.pumpAndSettle(
          const Duration(seconds: 1)); // Espera a que el SnackBar aparezca

      // ❌ Verificar error
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
