// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter/material.dart';
// import 'package:journi/application/user_service.dart';
// import 'package:journi/data/local/drift/app_database.dart';
// import 'package:journi/data/local/drift/drift_user_repository.dart';
// import 'package:journi/data/memory/in_memory_entry_repository.dart';
// import 'package:journi/data/memory/in_memory_trip_repository.dart';
// import 'package:journi/application/trip_service.dart';
// import 'package:journi/application/entry_service.dart';
// import 'package:journi/domain/ports/user_repository.dart';
// import 'package:journi/main.dart';

void main() {
//   // 🔧 Inicializa el entorno de test (sustituye al antiguo IntegrationTestWidgetsFlutterBinding)
//   TestWidgetsFlutterBinding.ensureInitialized();

//   group('🧭 Pruebas de integración: Crear_Text_Entry', () {
//     late InMemoryTripRepository tripRepo;
//     late InMemoryEntryRepository entryRepo;
//     late DefaultTripService tripService;
//     late DefaultEntryService entryService;
//     final db = AppDatabase();
//     late UserRepository userRepo = DriftUserRepository(db);
//     final userService = makeUserService(userRepo);

//     setUp(() {
//       tripRepo = InMemoryTripRepository();
//       entryRepo = InMemoryEntryRepository();
//       tripService = DefaultTripService(repo: tripRepo);
//       entryService = DefaultEntryService(repo: entryRepo);
//     });

//     testWidgets('✅ Crear entrada correctamente', (WidgetTester tester) async {
//       await tester.pumpWidget(MaterialApp(
//         home: MyHomePage(
//           title: 'JOURNI',
//           inicionSesiada: false,
//           tripService: tripService,
//           entryService: entryService,
//           tripRepo: tripRepo,
//           entryRepo: entryRepo,
//           userRepo: userRepo,
//           userService: userService,
//         ),
//       ));

// // Pulsa el BottomNavigationBarItem "Nuevo viaje"
//       await tester.tap(find.byKey(const Key('anadirButton')));
//       await tester.pumpAndSettle();

//       // 🧩 Rellenar los campos
//       await tester.enterText(
//         find.byKey(const Key('tituloField')),
//         'Vacaciones 2025',
//       );
//       await tester.enterText(
//         find.byKey(const Key('fechaIniField')),
//         '01-01-2025',
//       );
//       await tester.enterText(
//         find.byKey(const Key('fechaFinField')),
//         '10-01-2025',
//       );

//       await tester.tap(find.byKey(const Key('guardarButton')));
//       await tester.pumpAndSettle(
//           const Duration(seconds: 1)); // Espera a que el SnackBar aparezca
//       await tester.tap(find.byKey(const Key('id0')));
//       await tester.pumpAndSettle();
//       await tester.tap(find.byKey(const Key('anadirEntrada')));
//       await tester.pumpAndSettle();
//       await tester.enterText(
//         find.byKey(const Key('textoEntrada')),
//         'Que grande que eres Nano',
//       );
//       await tester.tap(find.byKey(const Key('aceptarButton')));
//       await tester.pumpAndSettle();
//       await tester.tap(find.byKey(const Key('anadirFoto')));
//       await tester.pumpAndSettle();
//       // Pulsar botón de añadir foto
//       await tester.tap(find.byKey(const Key('adjuntarFoto')));
//       await tester.pumpAndSettle();
//       expect(find.byKey(const Key('eid0')), findsOneWidget);
//       expect(find.byKey(const Key('eid1')), findsOneWidget);
//       // ✅ Verificar éxito
//       // Verifica que la pantalla principal está visible
//     });

//     testWidgets('❌ Error: Entrada vacía', (WidgetTester tester) async {
//       await tester.pumpWidget(MaterialApp(
//         home: MyHomePage(
//           title: 'JOURNI',
//           inicionSesiada: false,
//           tripService: tripService,
//           entryService: entryService,
//           tripRepo: tripRepo,
//           entryRepo: entryRepo,
//           userRepo: userRepo,
//           userService: userService,
//         ),
//       ));

//       await tester.tap(find.byKey(const Key('anadirButton')));
//       await tester.pumpAndSettle();

//       // 🧩 Campos con fechas inválidas
//       await tester.enterText(
//         find.byKey(const Key('tituloField')),
//         'Nanosecso',
//       );
//       await tester.enterText(
//         find.byKey(const Key('fechaIniField')),
//         '10-01-2025',
//       );
//       await tester.enterText(
//         find.byKey(const Key('fechaFinField')),
//         '11-01-2025',
//       );

//       await tester.tap(find.byKey(const Key('guardarButton')));
//       await tester.pumpAndSettle();

//       await tester.tap(find.byKey(const Key('id0')));
//       await tester.pumpAndSettle();
//       await tester.tap(find.byKey(const Key('anadirEntrada')));
//       await tester.pumpAndSettle();
//       await tester.enterText(
//         find.byKey(const Key('textoEntrada')),
//         '',
//       );
//       await tester.tap(find.byKey(const Key('aceptarButton')));
//       expect(find.byKey(const Key('eid0')), findsNothing);
//     });
//   });
}
