import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_trip_repository.dart';
import 'package:journi/domain/trip.dart';

void main() {
  late AppDatabase db;
  late DriftTripRepository tripRepo;

  setUp(() {
    // Usamos base de datos en memoria real (SQLite)
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tripRepo = DriftTripRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> createDummyUser(String id, String email) async {
    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: id,
            name: 'Test',
            lastName: 'User',
            email: email,
            passwordHash: 'hash',
            passwordSalt: 'salt',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> createDummyTrip(String id) async {
    await tripRepo.upsert(
      (Trip.create(
        id: id,
        title: 'Drift Trip',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ) as Ok<Trip>)
          .value,
    );
  }

  group('DriftTripRepository - Share Functionality', () {
    test('addParticipant inserta fila en TripParticipants', () async {
      // 1. Arrange
      const tripId = 't1';
      const userId = 'u1';
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');

      // 2. Act
      final res = await tripRepo.addParticipant(tripId, userId);

      // 3. Assert
      expect(res, isA<Ok<Unit>>());

      // Verificación directa en la tabla de unión
      final relations = await db.select(db.tripParticipants).get();
      expect(relations.length, 1);
      expect(relations.first.tripId, tripId);
      expect(relations.first.userId, userId);
    });

    test('addParticipant es idempotente (no falla si se repite)', () async {
      const tripId = 't1';
      const userId = 'u1';
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');

      // Primera inserción
      await tripRepo.addParticipant(tripId, userId);

      // Segunda inserción (mismos datos)
      final res = await tripRepo.addParticipant(tripId, userId);

      expect(res, isA<Ok<Unit>>()); // Debería seguir siendo OK

      // Solo debe haber 1 fila gracias a la Primary Key compuesta
      final relations = await db.select(db.tripParticipants).get();
      expect(relations.length, 1);
    });

    test(
        'Borrar un viaje borra en cascada los participantes (Integridad Referencial)',
        () async {
      //  - Conceptualmente: Trip borrado -> relación borrada

      const tripId = 't1';
      const userId = 'u1';
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');
      await tripRepo.addParticipant(tripId, userId);

      // Confirmamos que existe
      expect((await db.select(db.tripParticipants).get()).length, 1);

      // Act: Borrar el viaje
      await tripRepo.deleteById(tripId);

      // Assert: La relación debió desaparecer automáticamente
      final relations = await db.select(db.tripParticipants).get();
      expect(relations.isEmpty, isTrue, reason: 'Cascade delete falló');
    });
  });
}
