import 'package:flutter_test/flutter_test.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';

Entry _mk({
  required String id,
  required String trip,
  required DateTime ts,
  EntryType type = EntryType.note,
}) {
  return Entry.create(
    id: id,
    tripId: trip,
    type: type,
    text: type == EntryType.note ? 'text' : null,
    mediaUri: type == EntryType.note ? null : '/tmp/$id',
    createdAt: ts,
    updatedAt: ts,
  ).asOk().value;
}

void main() {
  group('CreateEntryUseCase', () {
    test('crea y persiste una NOTE válida', () async {
      final repo = InMemoryEntryRepository();
      final uc = CreateEntryUseCase(repo);
      final res = await uc(
        CreateEntryCommand(
          id: 'e1',
          tripId: 't1',
          type: EntryType.note,
          text: 'hola',
        ),
      );
      expect(res.isOk, isTrue);
      final stored = await repo.findById('e1');
      expect(stored.asOk().value?.tripId, 't1');
    });

    test('no persiste si validación falla (NOTE sin texto)', () async {
      final repo = InMemoryEntryRepository();
      final uc = CreateEntryUseCase(repo);
      final res = await uc(
        CreateEntryCommand(id: 'e1', tripId: 't1', type: EntryType.note),
      );
      expect(res.isErr, isTrue);
      final stored = await repo.findById('e1');
      expect(stored.asOk().value, isNull);
    });
  });

  group('List/Watch/Delete UseCases', () {
    test('ListEntriesUseCase respeta filtros y orden', () async {
      final repo = InMemoryEntryRepository();
      final listUC = ListEntriesUseCase(repo);
      final t0 = DateTime.utc(2025, 1, 1, 12);
      await repo.upsert(
        _mk(id: 'e1', trip: 't1', ts: t0.subtract(const Duration(seconds: 1))),
      );
      await repo.upsert(
        _mk(id: 'e2', trip: 't1', ts: t0, type: EntryType.photo),
      );
      await repo.upsert(_mk(id: 'e3', trip: 't2', ts: t0));

      final res = await listUC(tripId: 't1');
      expect(res.asOk().value.map((e) => e.id).toList(), ['e2', 'e1']);

      final photos = await listUC(tripId: 't1', type: EntryType.photo);
      expect(photos.asOk().value.map((e) => e.id), ['e2']);
    });

    test('WatchEntriesUseCase emite inicial y cambios', () async {
      final repo = InMemoryEntryRepository();
      final watchUC = WatchEntriesUseCase(repo);
      final stream = watchUC(tripId: 't1');

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isA<List<Entry>>().having((l) => l.length, 'initial', 0),
          isA<List<Entry>>().having((l) => l.first.id, 'after add', 'e1'),
        ]),
      );

      final t0 = DateTime.utc(2025);
      await repo.upsert(_mk(id: 'e1', trip: 't1', ts: t0));
      await expectation;
    });

    test('DeleteEntryUseCase es idempotente', () async {
      final repo = InMemoryEntryRepository();
      final delUC = DeleteEntryUseCase(repo);
      final r1 = await delUC('not-exists');
      expect(r1.isOk, isTrue);
      // crear y borrar
      final e = _mk(id: 'e1', trip: 't1', ts: DateTime.utc(2025));
      await repo.upsert(e);
      final r2 = await delUC('e1');
      expect(r2.isOk, isTrue);
      final r3 = await delUC('e1');
      expect(r3.isOk, isTrue); // sigue siendo idempotente
    });
  });
}
