import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/entry.dart';

void main() {
  group('Trip.create - validaciones y normalización', () {
    test('trimea el título y devuelve Ok', () {
      final res = Entry.create(
        id: 't1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tripId: 'tt1',
        text: 'Mi entrada',
        type: EntryType.note,
      );
      expect(res,
          isA<Ok<Entry>>()); // group/test/expect son prácticas estándar. :contentReference[oaicite:2]{index=2}
      final entry = (res as Ok<Entry>).value;
      expect(entry.text, 'Mi entrada');
    });

    test('title vacío -> Err', () {
      final res = Entry.create(
        id: 't2',
        text: '   ',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tripId: 'tt2',
        type: EntryType.note,
      );
      expect(res, isA<Err<Entry>>());
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
