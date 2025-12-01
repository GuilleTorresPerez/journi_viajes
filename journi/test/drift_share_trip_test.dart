import 'package:drift/drift.dart'; // Necesario para InsertMode
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
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tripRepo = DriftTripRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // Helper para crear usuarios
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
          // 👇 IMPORTANTE: Si el usuario ya existe (ej. owner_1), lo ignoramos para no fallar
          mode: InsertMode.insertOrIgnore,
        );
  }

  // Helper para crear viajes
  Future<void> createDummyTrip(String id) async {
    // 👇 CORRECCIÓN CRUCIAL:
    // Primero creamos al dueño para satisfacer la Foreign Key de la DB
    await createDummyUser('owner_1', 'owner@journi.app');

    await tripRepo.upsert(
      (Trip.create(
        id: id,
        ownerId: 'owner_1', // Ahora 'owner_1' ya existe en la tabla users
        title: 'Drift Trip',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ) as Ok<Trip>)
          .value,
    );
  }

  group('DriftTripRepository - Share Functionality', () {
    test('addParticipant inserta fila en TripParticipants', () async {
      const tripId = 't1';
      const userId = 'u1';

      // 1. Crea viaje (y su dueño 'owner_1' internamente)
      await createDummyTrip(tripId);
      // 2. Crea el usuario que vamos a invitar
      await createDummyUser(userId, 'user@test.com');

      // 3. Añadir participante
      final res =
          await tripRepo.addParticipant(tripId, userId, TripRole.viewer);

      expect(res, isA<Ok<Unit>>());

      // Verificamos
      final relations = await db.select(db.tripParticipants).get();

      // Debería haber al menos 1 relación (la que acabamos de añadir)
      // Filtramos para asegurarnos que 'u1' está ahí
      final userRelation = relations.where((r) => r.userId == userId);
      expect(userRelation.length, 1,
          reason: 'El usuario u1 debería estar en participantes');
    });

    test('addParticipant es idempotente (no falla si se repite)', () async {
      const tripId = 't1';
      const userId = 'u1';
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');

      await tripRepo.addParticipant(tripId, userId, TripRole.viewer);

      // Repetimos
      final res =
          await tripRepo.addParticipant(tripId, userId, TripRole.viewer);

      expect(res, isA<Ok<Unit>>());

      // Aseguramos que no se duplicó la fila
      final relations = await db.select(db.tripParticipants).get();
      final userRelations = relations.where((r) => r.userId == userId);
      expect(userRelations.length, 1);
    });

    test('Borrar un viaje borra en cascada los participantes', () async {
      const tripId = 't1';
      const userId = 'u1';
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');
      await tripRepo.addParticipant(tripId, userId, TripRole.viewer);

      // Borramos el viaje
      await tripRepo.deleteById(tripId);

      // Verificamos que no queden relaciones
      final relations = await db.select(db.tripParticipants).get();
      expect(relations.isEmpty, isTrue, reason: 'Cascade delete falló');
    });
  });
}
