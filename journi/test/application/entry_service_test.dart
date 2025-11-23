import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/entry.dart';

void main() {
  test('EntryService crea y lista por trip', () async {
    final repo = InMemoryEntryRepository();
    final svc = makeEntryService(repo);

    final r = await svc.create(
      const CreateEntryCommand(
        id: 'e1',
        tripId: 't1',
        type: EntryType.note,
        text: 'hola',
      ),
    );
    expect(r.isOk, isTrue);

    final listed = await svc.listByTrip('t1');
    expect(listed.asOk().value.length, 1);
    expect(listed.asOk().value.first.id, 'e1');
  });

  test('EntryService.watchByTrip emite inicial y cambios', () async {
    final repo = InMemoryEntryRepository();
    final svc = makeEntryService(repo);

    final expectation = expectLater(
      svc.watchByTrip('t1'),
      emitsInOrder([
        isA<List<Entry>>().having((l) => l.isEmpty, 'initial', isTrue),
        isA<List<Entry>>().having((l) => l.first.id, 'after create', 'e1'),
      ]),
    );

    await svc.create(
      const CreateEntryCommand(
        id: 'e1',
        tripId: 't1',
        type: EntryType.note,
        text: 'hola',
      ),
    );

    await expectation;
  });
}
