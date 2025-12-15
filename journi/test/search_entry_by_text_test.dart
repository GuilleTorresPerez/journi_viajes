import 'package:flutter_test/flutter_test.dart';
import 'package:journi/entry_search.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/application/shared/result.dart';

void main() {
  group('filterEntriesByText', () {
    late List<Result<Entry>> entriesResults;

    setUp(() {
      // Creamos algunas entradas de ejemplo
      entriesResults = [
        Ok<Entry>(
          Entry.create(
            id: '1',
            tripId: 't1',
            type: EntryType.note,
            text: 'Primera nota',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: [],
          ) as Entry,
        ),
        Ok<Entry>(
          Entry.create(
            id: '2',
            tripId: 't1',
            type: EntryType.note,
            text: 'Segunda nota diferente',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: [],
          ) as Entry,
        ),
        Ok<Entry>(
          Entry.create(
            id: '3',
            tripId: 't1',
            type: EntryType.photo,
            mediaUri: '/path/foto.jpg',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: [],
          ) as Entry,
        ),
      ];
    });

    // Función helper para convertir Result<Entry> a Entry
    List<Entry> unwrap(List<Result<Entry>> results) {
      return results.whereType<Ok<Entry>>().map((r) => r.value).toList();
    }

    test('devuelve todas las notas si la query está vacía', () {
      final entries = unwrap(entriesResults);

      final result = filterEntriesByText(entries: entries, query: '');

      expect(result.length, 2); // Solo las notas
      expect(result.any((e) => e.type == EntryType.photo), false);
    });

    test('filtra correctamente por texto existente', () {
      final entries = unwrap(entriesResults);

      final result = filterEntriesByText(entries: entries, query: 'Primera');

      expect(result.length, 1);
      expect(result.first.text, 'Primera nota');
    });

    test('no devuelve entradas si no hay coincidencias', () {
      final entries = unwrap(entriesResults);

      final result = filterEntriesByText(entries: entries, query: 'NoExiste');

      expect(result.isEmpty, true);
    });

    test('ignora fotos y vídeos aunque coincida el texto', () {
      final entries = unwrap(entriesResults);

      final result = filterEntriesByText(entries: entries, query: 'foto');

      expect(result.isEmpty, true); // La foto no se devuelve
    });
  });
}
