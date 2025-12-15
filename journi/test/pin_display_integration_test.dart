import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/map_screen.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('🧭 Pruebas de integración: Listar_Viaje', () {
    testWidgets('✅ Se muestran pins cuando hay entradas con ubicación',
        (tester) async {
      final trip = Trip(
        id: 't1',
        title: 'Viaje Test',
        ownerId: 'u1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final entryRepo = InMemoryEntryRepository();
      final entryService = DefaultEntryService(repo: entryRepo);

      // Crear entrada con ubicación
      await entryService.create(
        CreateEntryCommand(
          id: 'e1',
          tripId: trip.id,
          type: EntryType.note,
          text: 'Nota en Madrid',
          location: EntryLocation(lat: 40.4168, lon: -3.7038),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapaDetalleScreen(
            viaje: trip,
            entryRepo: entryRepo,
            entryService: entryService,
            testUserPosition: LatLng(40.0, -3.0), // 👈 mock GPS
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 🔍 Buscamos los pins (Icon(Icons.location_pin))
      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    });

    testWidgets('❌ No se muestran pins si no hay entradas con ubicación',
        (tester) async {
      final trip = Trip(
        id: 't1',
        title: 'Viaje vacío',
        ownerId: 'u1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final entryRepo = InMemoryEntryRepository();
      final entryService = DefaultEntryService(repo: entryRepo);

      // Entrada SIN ubicación
      await entryService.create(
        CreateEntryCommand(
          id: 'e1',
          tripId: trip.id,
          type: EntryType.note,
          text: 'Nota sin ubicación',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MapaDetalleScreen(
            viaje: trip,
            entryRepo: entryRepo,
            entryService: entryService,
            testUserPosition: LatLng(40.0, -3.0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ❌ No hay pins
      expect(find.byIcon(Icons.location_pin), findsNothing);
    });
  });
}
