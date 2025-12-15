/*import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/application/user_service.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/entry_search.dart';
import 'package:journi/domain/entry.dart';

void main() {
  late AppDatabase db;
  late DriftUserRepository userRepo;
  late DefaultUserService userService;

  late InMemoryTripRepository tripRepo;
  late InMemoryEntryRepository entryRepo;
  late EntryService entryService;

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

  group('filterEntriesByText', () {
    test('devuelve todas las entradas si el texto está vacío', () {
      final entries = [
        Entry.create(
          id: '1',
          tripId: 't1',
          type: EntryType.note,
          text: 'Hola mundo',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
        ),
      ];
      final entries2 = [
        Entry()
      ];

      final cmd = CreateEntryCommand(id: 'id', tripId: 'tripId', type: EntryType.note);
      entryService.create(cmd);
      final result = filterEntriesByText(entries: entries, query: '');

      expect(result.length, 1);
    });

    test('filtra correctamente por texto', () {
      final entries = [
        Entry.create(
          id: '1',
          tripId: 't1',
          type: EntryType.note,
          text: 'Primera nota',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
        ),
        Entry.create(
          id: '2',
          tripId: 't1',
          type: EntryType.note,
          text: 'Segunda diferente',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
        ),
      ];

      final result =
      filterEntriesByText(entries: entries, query: 'Primera');

      expect(result.length, 1);
      expect(result.first.text, 'Primera nota');
    });

    test('no devuelve entradas si no hay coincidencias', () {
      final entries = [
        Entry.create(
          id: '1',
          tripId: 't1',
          type: EntryType.note,
          text: 'Texto existente',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
        ),
      ];

      final result =
      filterEntriesByText(entries: entries, query: 'NoExiste');

      expect(result.isEmpty, true);
    });

    test('ignora fotos y vídeos aunque coincida el texto', () {
      final entries = [
        Entry.create(
          id: '1',
          tripId: 't1',
          type: EntryType.photo,
          mediaUri: '/path/foto.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: [],
        ),
      ];



      final result =
      filterEntriesByText(entries: entries, query: 'foto');

      expect(result.isEmpty, true);
    });
  });
}*/
