import 'package:flutter_test/flutter_test.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/entry.dart';

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
  test('list devuelve una lista inmodificable', () async {
    final repo = InMemoryEntryRepository();
    final res = await repo.list(tripId: 't1');
    final list = res.asOk().value;
    expect(
      () => list.add(_mk(id: 'x', trip: 't1', ts: DateTime.utc(2025))),
      throwsUnsupportedError,
    );
  });

  test(
    'deleteById es idempotente y findById devuelve null si no existe',
    () async {
      final repo = InMemoryEntryRepository();
      final d1 = await repo.deleteById('NOPE');
      expect(d1.isOk, isTrue);
      final f = await repo.findById('NOPE');
      expect(f.asOk().value, isNull);
    },
  );

  test('orden por createdAt DESC y filtros por tripId/type', () async {
    final repo = InMemoryEntryRepository();
    final t0 = DateTime.utc(2025, 1, 1, 12, 00, 00);
    final e1 = _mk(
      id: 'e1',
      trip: 't1',
      ts: t0.subtract(const Duration(seconds: 5)),
      type: EntryType.note,
    );
    final e2 = _mk(id: 'e2', trip: 't1', ts: t0, type: EntryType.photo);
    final e3 = _mk(id: 'e3', trip: 't2', ts: t0, type: EntryType.video);

    await repo.upsert(e1);
    await repo.upsert(e2);
    await repo.upsert(e3);

    final listT1 = (await repo.list(tripId: 't1')).asOk().value;
    expect(listT1.map((e) => e.id).toList(), ['e2', 'e1']);

    final onlyPhotos = (await repo.list(
      tripId: 't1',
      type: EntryType.photo,
    ))
        .asOk()
        .value;
    expect(onlyPhotos.map((e) => e.id), ['e2']);
  });

  test('watchAll emite snapshot inicial y cambios', () async {
    final repo = InMemoryEntryRepository();
    final stream = repo.watchAll(tripId: 't1');

    final expectation = expectLater(
      stream,
      emitsInOrder([
        isA<List<Entry>>().having((l) => l.length, 'initial empty', 0),
        isA<List<Entry>>().having(
          (l) => l.map((e) => e.id).toList(),
          'after add',
          ['e1'],
        ),
        isA<List<Entry>>().having((l) => l.isEmpty, 'after delete', isTrue),
      ]),
    );

    await pumpEventQueue();

    final e1 = _mk(id: 'e1', trip: 't1', ts: DateTime.utc(2025));
    await repo.upsert(e1);
    await repo.deleteById('e1');

    await expectation;
  });
}
