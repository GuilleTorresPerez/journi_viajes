import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as d; // Necesario para d.Value

// Importa tu base de datos y repositorios
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_entry_repository.dart';

// Imports de dominio
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/application/shared/result.dart';

void main() {
  late AppDatabase db;
  late EntryRepository repo;

  setUp(() async {
    // 1. Base de datos en memoria limpia
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftEntryRepository(db);

    // ✅ FIX 1: Habilitar claves foráneas explícitamente (buena práctica en SQLite test)
    await db.customStatement('PRAGMA foreign_keys = ON');
  });

  tearDown(() async {
    await db.close();
  });

  // ✅ FIX 2: Helper para crear las dependencias (User y Trip)
  // Sin esto, la FK constraint falla al insertar la Entry.
  Future<void> _ensureTripExists(String tripId) async {
    const userId = 'user_default';

    // A) Insertar Usuario (Si la tabla trips tiene FK a users)
    // Usamos insertOnConflictUpdate para no fallar si ya existe
    await db.into(db.users).insertOnConflictUpdate(
          UsersCompanion(
            id: d.Value(userId),
            email: d.Value('test@user.com'),
            name: d.Value('Test User'),
            lastName: d.Value('Test Lastname'),
            passwordHash: d.Value('hash'),
            passwordSalt: d.Value('salt'),
            createdAt: d.Value(DateTime.now()),
            updatedAt: d.Value(DateTime.now()),
          ),
        );

    // B) Insertar Trip
    await db.into(db.trips).insertOnConflictUpdate(
          TripsCompanion(
            id: d.Value(tripId),
            ownerId: d.Value(userId),
            title: d.Value('Test Trip $tripId'),
            createdAt: d.Value(DateTime.now()),
            updatedAt: d.Value(DateTime.now()),
            // Rellenar otros campos obligatorios si los hay en tu tabla trips
          ),
        );
  }

  // Helper para crear entradas en memoria (Dominio)
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
    return res.asOk().value;
  }

  group('DriftEntryRepository Tests', () {
    test(
        'upsert inserta una nueva entrada y findById la recupera correctamente',
        () async {
      // ✅ FIX 3: Asegurar que el trip existe antes de insertar la entry
      await _ensureTripExists('trip_default');

      // 1. Arrange
      final location = EntryLocation(lat: 40.7128, lon: -74.0060);
      final entry = _fakeEntry(
        id: 'e1',
        tripId: 'trip_default', // Coincide con el seed
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
      expect(retrieved.location!.lat, equals(40.7128));
    });

    test('upsert actualiza una entrada existente (OnConflictUpdate)', () async {
      await _ensureTripExists('trip_default');

      // 1. Arrange
      final entryOriginal = _fakeEntry(id: 'e2', text: 'Versión 1');
      await repo.upsert(entryOriginal);

      final entryUpdated = entryOriginal
          .copyValidated(
            text: 'Versión 2 Editada',
            updatedAt: DateTime.now().toUtc(),
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
      await _ensureTripExists('trip_default');

      // 1. Arrange
      final entry = _fakeEntry(id: 'e3');
      await repo.upsert(entry);

      // 2. Act
      await repo.deleteById('e3');
      final findRes = await repo.findById('e3');

      // 3. Assert
      expect(findRes.asOk().value, isNull);
    });

    test('list filtra correctamente por tripId y EntryType', () async {
      // ✅ FIX 4: Crear los viajes específicos necesarios para este test
      await _ensureTripExists('TripA');
      await _ensureTripExists('TripB');

      // 1. Arrange
      await repo
          .upsert(_fakeEntry(id: 'a1', tripId: 'TripA', type: EntryType.note));
      await repo
          .upsert(_fakeEntry(id: 'a2', tripId: 'TripA', type: EntryType.photo));
      await repo
          .upsert(_fakeEntry(id: 'b1', tripId: 'TripB', type: EntryType.note));

      // 2. Act & Assert

      // Caso A: Filtrar solo por TripA
      final listTripA = await repo.list(tripId: 'TripA');
      expect(listTripA.isOk, isTrue);
      expect(listTripA.asOk().value.length, equals(2));

      // Caso B: Filtrar solo por Type (Note) - Debe traer de TripA y TripB
      final listNotes = await repo.list(type: EntryType.note);
      expect(listNotes.asOk().value.length, equals(2)); // a1 y b1

      // Caso C: Filtrar por ambos (TripA y Photo)
      final listTripAPhoto =
          await repo.list(tripId: 'TripA', type: EntryType.photo);
      expect(listTripAPhoto.asOk().value.length, equals(1));
      expect(listTripAPhoto.asOk().value.first.id, equals('a2'));
    });

    test('list ordena por createdAt descendente', () async {
      await _ensureTripExists('trip_default');

      final t1 = DateTime(2023, 1, 1).toUtc();
      final t2 = DateTime(2023, 1, 2).toUtc();
      final t3 = DateTime(2023, 1, 3).toUtc();

      await repo.upsert(_fakeEntry(id: 'old', createdAt: t1));
      await repo.upsert(_fakeEntry(id: 'new', createdAt: t3));
      await repo.upsert(_fakeEntry(id: 'mid', createdAt: t2));

      final res = await repo.list();
      final list = res.asOk().value;

      expect(list[0].id, equals('new')); // t3
      expect(list[1].id, equals('mid')); // t2
      expect(list[2].id, equals('old')); // t1
    });

    test('watchAll emite actualizaciones reactivas ante cambios', () async {
      // ✅ FIX 5: Crear viajes específicos para el test reactivo
      await _ensureTripExists('TripX');
      await _ensureTripExists('TripY');

      final stream = repo.watchAll(tripId: 'TripX');

      // A) Estado inicial vacío
      expectLater(stream, emits(isEmpty));

      // B) Insertamos
      await Future.delayed(Duration.zero);
      await repo.upsert(_fakeEntry(id: 'x1', tripId: 'TripX'));

      // Verificamos que emita la lista con x1
      await expectLater(
        stream,
        emits(
            predicate<List<Entry>>((l) => l.length == 1 && l.first.id == 'x1')),
      );
    });
  });
}
