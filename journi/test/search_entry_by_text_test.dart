import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/entry_search.dart';
import 'package:journi/application/shared/result.dart';

Entry unwrapEntry(Result<Entry> r) {
  expect(r, isA<Ok<Entry>>(), reason: 'Se esperaba Ok<Entry>');
  return (r as Ok<Entry>).value;
}

void main() {
  group('filterEntriesByText', () {
    test('devuelve todas las entradas si el texto está vacío', () {
      final entries = [
        unwrapEntry(
          Entry.create(
            id: '1',
            tripId: 't1',
            type: EntryType.note,
            text: 'Hola mundo',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: const [],
          ),
        ),
      ];

      final result = filterEntriesByText(entries: entries, query: '');

      expect(result.length, 1);
      expect(result.first.text, 'Hola mundo');
    });

    test('filtra correctamente por texto', () {
      final entries = [
        unwrapEntry(
          Entry.create(
            id: '1',
            tripId: 't1',
            type: EntryType.note,
            text: 'Primera nota',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: const [],
          ),
        ),
        unwrapEntry(
          Entry.create(
            id: '2',
            tripId: 't1',
            type: EntryType.note,
            text: 'Segunda diferente',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: const [],
          ),
        ),
      ];

      final result = filterEntriesByText(entries: entries, query: 'Primera');

      expect(result.length, 1);
      expect(result.first.text, 'Primera nota');
    });

    test('no devuelve entradas si no hay coincidencias', () {
      final entries = [
        unwrapEntry(
          Entry.create(
            id: '1',
            tripId: 't1',
            type: EntryType.note,
            text: 'Texto existente',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: const [],
          ),
        ),
      ];

      final result = filterEntriesByText(entries: entries, query: 'NoExiste');

      expect(result, isEmpty);
    });

    test('ignora fotos y vídeos aunque coincida el texto', () {
      final entries = [
        unwrapEntry(
          Entry.create(
            id: '1',
            tripId: 't1',
            type: EntryType.photo,
            mediaUri: '/path/foto.jpg',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: const [],
          ),
        ),
      ];

      final result = filterEntriesByText(entries: entries, query: 'foto');

      expect(result, isEmpty);
    });
  });
}
