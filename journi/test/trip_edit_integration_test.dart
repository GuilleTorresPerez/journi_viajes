import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter/material.dart';
// import 'package:journi/application/user_service.dart';
// import 'package:journi/data/local/drift/app_database.dart';
// import 'package:journi/data/local/drift/drift_user_repository.dart';
// import 'package:journi/data/memory/in_memory_entry_repository.dart';
// import 'package:journi/data/memory/in_memory_trip_repository.dart';
// import 'package:journi/application/trip_service.dart';
// import 'package:journi/application/entry_service.dart';
// import 'package:journi/main.dart';
// import 'package:journi/pantalla_viaje.dart';

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
//       await tester.tap(find.byIcon(Icons.edit));
//       await tester.pumpAndSettle();

//       await tester.tap(find.byKey(const Key('fechaIniField')));
//       await tester.pumpAndSettle();
//       await tester.enterText(
//         find.byKey(const Key('fechaIniField')),
//         '10-01-2026',
//       );
//       await tester.pumpAndSettle();
//       await tester.tap(find.byKey(const Key('guardarButton')));
//       await tester.pumpAndSettle(
//           const Duration(seconds: 1)); // Espera a que el SnackBar aparezca

//       // ❌ Verificar error
//       expect(find.text('Error'), findsOneWidget);
//       expect(find.text('La fecha de inicio no puede ser posterior a la final'),
//           findsOneWidget);
//       expect(find.text('Viaje creado correctamente'), findsNothing);
//     });
//   });
}
