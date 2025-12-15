import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/select_location_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Trip.create - validaciones y normalización', () {
    late AppDatabase db;
    late DefaultEntryService entryService;
    late InMemoryEntryRepository entryRepo;

    setUp(() async {
      entryRepo = InMemoryEntryRepository();
      entryService = DefaultEntryService(repo: entryRepo);
    });

    testWidgets('✅ Ubicacion existente', (WidgetTester tester) async {
      final entryId = UniqueKey().toString();
      final cmd = CreateEntryCommand(
        id: entryId,
        tripId: 'test1',
        type: EntryType.note,
        text: 'El nano',
      );
      await entryService.create(cmd);

      final entry = await entryRepo.findById(entryId);
      await tester.pumpWidget(
        MaterialApp(
          home: SelectLocationScreen(
            entry: entry.valueOrNull!,
            entryRepo: entryRepo,
            entryService: entryService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('nombreUbicacion')), 'Londres');

      final res = await tester.tap(find.byKey(Key('buscaUbicacion')));
      await tester.pumpAndSettle();

      expect(find.text('No se encontró esa ubicación'), findsNothing);
    });

    testWidgets('❌ Ubicacion inexistente', (WidgetTester tester) async {
      final entryId = UniqueKey().toString();
      final cmd = CreateEntryCommand(
        id: entryId,
        tripId: 'test1',
        type: EntryType.note,
        text: 'El nano',
      );
      await entryService.create(cmd);

      final entry = await entryRepo.findById(entryId);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // ⚠️ IMPORTANTE
            body: SelectLocationScreen(
              entry: entry.valueOrNull!,
              entryRepo: entryRepo,
              entryService: entryService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(Key('nombreUbicacion')), 'jsfbadlbafywelfavke');

      await tester.tap(find.byKey(Key('buscaUbicacion')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
    });

    /*
    test('trimea el título y devuelve Ok', () async {
      var repo = InMemoryEntryRepository();
      EntryService entryService = makeEntryService(repo);
      final cmd = CreateEntryCommand(
          id: 'eid0',
          tripId: 'id0',
          type: EntryType.note,
          text: 'Que grande que eres Nano');
      entryService.create(cmd);

      final res = await repo.findById('eid0');
      final Entry? entry;
      if (res is Ok<Entry>) {
        entry = res.value;
      } else {
        entry = null;
      }

      final edit = CreateEntryCommand(
        id: 'eid0',
        text: 'Te quiero Nano',
        tripId: entry!.tripId,
        type: EntryType.note,
      );

      repo.deleteById('eid0');
      entryService.create(edit);
      expect(res,
          isA<Ok<void>>()); // group/test/expect son prácticas estándar. :contentReference[oaicite:2]{index=2}
    });*/
  });
}
