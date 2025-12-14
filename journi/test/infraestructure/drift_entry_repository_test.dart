import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
// Asegúrate de importar tu base de datos y repositorio
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_entry_repository.dart';
// Importaciones de dominio y shared
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/application/shared/result.dart';

void main() {
  late AppDatabase db;
  late EntryRepository repo;

  // Configuración previa a cada test
  setUp(() {
    // [Fuente: Documentación de Drift - Testing]
    // Usamos una base de datos en memoria para aislamiento total.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftEntryRepository(db);
  });

  // Limpieza posterior a cada test
  tearDown(() async {
    await db.close();
  });

  // --- Helper Factory para crear entradas válidas rápidamente ---
  Entry _fakeEntry({
    required String id,
    String tripId = 'trip_default',
    EntryType type = EntryType.note,
    String? text = 'Default text',
    EntryLocation? location,
    DateTime? createdAt,
  }) {
    final now = DateTime.now().toUtc();
    final res = Entry.create(
      id: id,
      tripId: tripId,
      type: type,
      text: text,
      mediaUri: (type == EntryType.photo || type == EntryType.video)
          ? 'file://path/to/media'
          : null,
      location: location,
      tags: ['test', 'unit'],
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
    // Asumimos que el factory del dominio funciona (ya debería tener sus propios tests)
    return res.asOk().value;
  }

  group('DriftEntryRepository Tests', () {
    test(
        'upsert inserta una nueva entrada y findById la recupera correctamente',
        () async {
      // 1. Arrange
      final location = EntryLocation(lat: 40.7128, lon: -74.0060);
      final entry = _fakeEntry(
        id: 'e1',
        type: EntryType.location,
        text: 'New York Visit',
        location: location,
      );

      // 2. Act
      final resultUpsert = await repo.upsert(entry);
      final resultFind = await repo.findById('e1');

      // 3. Assert
      expect(resultUpsert.isOk, isTrue);
      expect(resultFind.isOk, isTrue);

      final retrieved = resultFind.asOk().value;
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(entry.id));
      expect(retrieved.type, equals(EntryType.location));
      // Verificamos el mapeo profundo de objetos (Location)
      expect(retrieved.location!.lat, equals(40.7128));
      // Verificamos el mapeo de listas (Tags)
      expect(retrieved.tags, containsAll(['test', 'unit']));
    });

    test('upsert actualiza una entrada existente (OnConflictUpdate)', () async {
      // 1. Arrange
      final entryOriginal = _fakeEntry(id: 'e2', text: 'Versión 1');
      await repo.upsert(entryOriginal);

      // Creamos una versión modificada (mismo ID)
      // Usamos copyValidated o create de nuevo
      final entryUpdated = entryOriginal
          .copyValidated(
            text: 'Versión 2 Editada',
            updatedAt: DateTime.now().toUtc(), // Actualizamos timestamp
          )
          .asOk()
          .value;

      // 2. Act
      await repo.upsert(entryUpdated);
      final result = await repo.findById('e2');

      // 3. Assert
      expect(result.isOk, isTrue);
      expect(result.asOk().value!.text, equals('Versión 2 Editada'));
    });

    test('deleteById elimina la entrada y findById retorna null', () async {
      // 1. Arrange
      final entry = _fakeEntry(id: 'e3');
      await repo.upsert(entry);

      // 2. Act
      final deleteRes = await repo.deleteById('e3');
      final findRes = await repo.findById('e3');

      // 3. Assert
      expect(deleteRes.isOk, isTrue); // Debe retornar Unit
      expect(findRes.isOk, isTrue); // La operación fue exitosa...
      expect(findRes.asOk().value, isNull); // ...pero el valor es nulo
    });

    test('list filtra correctamente por tripId y EntryType', () async {
      // 1. Arrange: Insertamos un set de datos diverso
      // Viaje A
      await repo
          .upsert(_fakeEntry(id: 'a1', tripId: 'TripA', type: EntryType.note));
      await repo
          .upsert(_fakeEntry(id: 'a2', tripId: 'TripA', type: EntryType.photo));
      // Viaje B
      await repo
          .upsert(_fakeEntry(id: 'b1', tripId: 'TripB', type: EntryType.note));

      // 2. Act & Assert

      // Caso A: Filtrar solo por TripA
      final listTripA = await repo.list(tripId: 'TripA');
      expect(listTripA.isOk, isTrue);
      expect(listTripA.asOk().value.length, equals(2));
      expect(listTripA.asOk().value.any((e) => e.id == 'b1'), isFalse);

      // Caso B: Filtrar solo por Type (Note)
      final listNotes = await repo.list(type: EntryType.note);
      expect(listNotes.isOk, isTrue);
      // Debería traer a1 (TripA) y b1 (TripB)
      expect(listNotes.asOk().value.length, equals(2));
      expect(listNotes.asOk().value.every((e) => e.type == EntryType.note),
          isTrue);

      // Caso C: Filtrar por ambos (TripA y Photo)
      final listTripAPhoto =
          await repo.list(tripId: 'TripA', type: EntryType.photo);
      expect(listTripAPhoto.asOk().value.length, equals(1));
      expect(listTripAPhoto.asOk().value.first.id, equals('a2'));
    });

    test('list ordena por createdAt descendente', () async {
      // 1. Arrange
      final t1 = DateTime(2023, 1, 1).toUtc();
      final t2 = DateTime(2023, 1, 2).toUtc();
      final t3 = DateTime(2023, 1, 3).toUtc();

      await repo.upsert(_fakeEntry(id: 'old', createdAt: t1));
      await repo.upsert(_fakeEntry(id: 'new', createdAt: t3));
      await repo.upsert(_fakeEntry(id: 'mid', createdAt: t2));

      // 2. Act
      final res = await repo.list();

      // 3. Assert
      final list = res.asOk().value;
      expect(list[0].id, equals('new')); // t3
      expect(list[1].id, equals('mid')); // t2
      expect(list[2].id, equals('old')); // t1
    });

    test('watchAll emite actualizaciones reactivas ante cambios', () async {
      // 1. Arrange
      final stream = repo.watchAll(tripId: 'TripX');

      // 2. Act & Assert

      // A) Estado inicial vacío
      expectLater(stream, emits(isEmpty));

      // B) Insertamos una entrada que coincide con el filtro
      await Future.delayed(
          Duration.zero); // Pequeña pausa para asegurar suscripción
      await repo.upsert(_fakeEntry(id: 'x1', tripId: 'TripX'));

      await expectLater(
        stream,
        emits(
            predicate<List<Entry>>((l) => l.length == 1 && l.first.id == 'x1')),
      );

      // C) Insertamos una entrada que NO coincide con el filtro
      await repo.upsert(_fakeEntry(id: 'y1', tripId: 'TripY'));
      // No deberíamos recibir un nuevo evento con TripY, o si recibimos evento, la lista sigue igual.
      // Drift suele emitir si la tabla cambia, pero la query filtra.
      // Verificamos que la siguiente emisión (si ocurre) sigue teniendo solo x1
      // Ojo: expectLater consume eventos. Si drift no emite, esto se bloquearía.
      // Para simplificar test de streams:

      final currentList = await stream.first;
      expect(currentList.length, equals(1));
      expect(currentList.first.tripId, equals('TripX'));
    });
  });
}
