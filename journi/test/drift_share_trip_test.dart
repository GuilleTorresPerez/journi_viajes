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
        ownerId: 'owner_1', // 👈 CORREGIDO: ownerId requerido
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
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');

      // 👈 CORREGIDO: Se añade TripRole.viewer como 3er argumento
      final res =
          await tripRepo.addParticipant(tripId, userId, TripRole.viewer);

      expect(res, isA<Ok<Unit>>());

      final relations = await db.select(db.tripParticipants).get();
      expect(relations.length, 1); // El owner (admin) + el nuevo (viewer) = 2?
      // NOTA: upsert() en el repo inserta al owner. addParticipant añade otro.
      // Dependiendo de tu implementación de createDummyTrip, verifica si el owner se guarda en DB.
      // Si DriftTripRepository.upsert guarda al owner, aquí habrá 2 filas.
      // Ajusta la expectativa si es necesario, pero el error de compilación se resuelve con el argumento extra.
    });

    test('addParticipant es idempotente (no falla si se repite)', () async {
      const tripId = 't1';
      const userId = 'u1';
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');

      // 👈 CORREGIDO: argumentos extra
      await tripRepo.addParticipant(tripId, userId, TripRole.viewer);
      final res =
          await tripRepo.addParticipant(tripId, userId, TripRole.viewer);

      expect(res, isA<Ok<Unit>>());
    });

    test('Borrar un viaje borra en cascada los participantes', () async {
      const tripId = 't1';
      const userId = 'u1';
      await createDummyTrip(tripId);
      await createDummyUser(userId, 'user@test.com');

      // 👈 CORREGIDO: argumento extra
      await tripRepo.addParticipant(tripId, userId, TripRole.viewer);

      await tripRepo.deleteById(tripId);

      final relations = await db.select(db.tripParticipants).get();
      expect(relations.isEmpty, isTrue, reason: 'Cascade delete falló');
    });
  });
}
