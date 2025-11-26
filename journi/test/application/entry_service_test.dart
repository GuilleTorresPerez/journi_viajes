import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'package:journi/domain/entry.dart';

void main() {
  test('EntryService crea, actualiza y lista', () async {
    final repo = InMemoryEntryRepository();
    final svc = makeEntryService(repo); // Usa la fábrica por defecto

    // 1. Crear
    final rCreate = await svc.create(
      const CreateEntryCommand(
        id: 'e1',
        tripId: 't1',
        type: EntryType.note,
        text: 'hola',
      ),
    );
    expect(rCreate.isOk, isTrue);

    // 2. Actualizar (Prueba de integración del servicio con el nuevo caso de uso)
    final rUpdate = await svc.update(
      const UpdateEntryCommand(
        id: 'e1',
        text: 'hola editado',
      ),
    );
    expect(rUpdate.isOk, isTrue);
    expect(rUpdate.asOk().value.text, 'hola editado');

    // 3. Verificar listado
    final listed = await svc.listByTrip('t1');
    expect(listed.asOk().value.first.text, 'hola editado');
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
