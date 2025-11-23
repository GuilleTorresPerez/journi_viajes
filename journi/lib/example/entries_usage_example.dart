import 'package:journi/application/entry_service.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';

void main() async {
  final repo = InMemoryEntryRepository();
  final entries = makeEntryService(repo);

  // Crear una nota
  // ignore: unused_local_variable
  final r1 = await entries.create(
    CreateEntryCommand(
      id: 'e1',
      tripId: 't1',
      type: EntryType.note,
      text: 'Llegamos a Lisboa y comimos pasteis',
    ),
  );

  // Crear una foto
  // ignore: unused_local_variable
  final r2 = await entries.create(
    CreateEntryCommand(
      id: 'e2',
      tripId: 't1',
      type: EntryType.photo,
      mediaUri: '/storage/emulated/0/Pictures/lisboa_1.jpg',
    ),
  );

  // Listar
  final listRes = await entries.listByTrip('t1');
  print(listRes);

  // Watch
  final sub = entries.watchByTrip('t1').listen((items) {
    print('Cambios en t1: ${items.map((e) => e.id).toList()}');
  });

  await entries.deleteById('e1');
  await sub.cancel();
}
