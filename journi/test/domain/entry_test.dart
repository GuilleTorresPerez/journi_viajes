import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/entry.dart';

void main() {
  group('Entry.create validations', () {
    test('crea NOTE válida (normaliza texto y tags, fechas UTC)', () {
      final now = DateTime.utc(2025, 1, 1, 12);
      final res = Entry.create(
        id: ' e1 ',
        tripId: ' t1 ',
        type: EntryType.note,
        text: '  hola  ',
        tags: ['  food ', 'food', '  '],
        createdAt: now,
        updatedAt: now,
      );
      expect(res.isOk, isTrue);
      final e = res.asOk().value;
      expect(e.id, 'e1');
      expect(e.tripId, 't1');
      expect(e.text, 'hola');
      expect(e.createdAt.isUtc, isTrue);
      expect(e.updatedAt.isUtc, isTrue);
      expect(e.tags, unorderedEquals(['food']));
    });

    test('crea PHOTO válida (requiere mediaUri)', () {
      final now = DateTime.utc(2025, 1, 1, 12);
      final res = Entry.create(
        id: 'e2',
        tripId: 't1',
        type: EntryType.photo,
        mediaUri: '/tmp/pic.jpg',
        createdAt: now,
        updatedAt: now,
      );
      expect(res.isOk, isTrue);
    });

    test('falla si NOTE sin texto', () {
      final now = DateTime.utc(2025, 1, 1, 12);
      final res = Entry.create(
        id: 'e3',
        tripId: 't1',
        type: EntryType.note,
        createdAt: now,
        updatedAt: now,
      );
      expect(res.isErr, isTrue);
    });

    test('falla si PHOTO sin mediaUri', () {
      final now = DateTime.utc(2025, 1, 1, 12);
      final res = Entry.create(
        id: 'e4',
        tripId: 't1',
        type: EntryType.photo,
        createdAt: now,
        updatedAt: now,
      );
      expect(res.isErr, isTrue);
    });

    test('falla si coordenadas fuera de rango', () {
      final now = DateTime.utc(2025, 1, 1, 12);
      final res = Entry.create(
        id: 'e5',
        tripId: 't1',
        type: EntryType.note,
        text: 'hola',
        location: const EntryLocation(lat: 190, lon: 500),
        createdAt: now,
        updatedAt: now,
      );
      expect(res.isErr, isTrue);
    });

    test('falla si updatedAt < createdAt', () {
      final created = DateTime.utc(2025, 1, 1, 12);
      final updated = created.subtract(const Duration(seconds: 1));
      final res = Entry.create(
        id: 'e6',
        tripId: 't1',
        type: EntryType.note,
        text: 'hola',
        createdAt: created,
        updatedAt: updated,
      );
      expect(res.isErr, isTrue);
    });
  });

  group('Entry.copyValidated (Actualización Inmutable)', () {
    late Entry originalEntry;

    setUp(() {
      final now = DateTime.utc(2025, 1, 1, 12);
      originalEntry = Entry.create(
        id: 'e1',
        tripId: 't1',
        type: EntryType.note,
        text: 'Texto original',
        createdAt: now,
        updatedAt: now,
      ).asOk().value;
    });

    test('Éxito: actualiza texto y actualiza updatedAt automáticamente', () {
      final copyRes = originalEntry.copyValidated(text: 'Texto nuevo');

      expect(copyRes.isOk, isTrue);
      final copy = copyRes.asOk().value;

      expect(copy.text, 'Texto nuevo');
      expect(copy.id, originalEntry.id); // ID no cambia
      expect(copy.createdAt, originalEntry.createdAt); // CreatedAt no cambia
      expect(copy.updatedAt.isAfter(originalEntry.updatedAt),
          isTrue); // UpdatedAt cambia
    });

    test('Éxito: actualiza ubicación y mantiene otros campos', () {
      const newLoc = EntryLocation(lat: 40.0, lon: -3.0);
      final copyRes = originalEntry.copyValidated(location: newLoc);

      expect(copyRes.isOk, isTrue);
      final copy = copyRes.asOk().value;

      expect(copy.location!.lat, 40.0);
      expect(copy.text, 'Texto original'); // El texto se mantiene
    });

    test('Fallo: validación impide dejar NOTE sin texto al actualizar', () {
      // Intentamos actualizar con texto vacío
      final copyRes = originalEntry.copyValidated(text: '   ');

      expect(copyRes.isErr, isTrue);
      expect(
        copyRes.asErr().errors.first.toString(),
        contains('texto'),
      );
    });

    test('Fallo: validación impide coordenadas inválidas al actualizar', () {
      final copyRes = originalEntry.copyValidated(
        location: const EntryLocation(lat: 100, lon: 0), // Latitud inválida
      );
      expect(copyRes.isErr, isTrue);
    });
  });
}
