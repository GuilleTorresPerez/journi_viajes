import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_trip_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:drift/drift.dart' as d; // Para InsertMode

void main() {
  late AppDatabase db;
  late DriftTripRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTripRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // Helper para crear usuarios rápido
  Future<void> seedUser(String id) async {
    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: id,
            name: 'User',
            lastName: id,
            email: '$id@test.com',
            passwordHash: 'x',
            passwordSalt: 'x',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          mode: d.InsertMode.insertOrIgnore,
        );
  }

  // Helper para crear viajes rápido
  Future<void> seedTrip(String tripId, String ownerId) async {
    await repo.upsert(
      (Trip.create(
        id: tripId,
        ownerId: ownerId,
        title: 'Trip de $ownerId',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ) as Ok<Trip>)
          .value,
    );
  }

  group('Seguridad y Aislamiento de Datos', () {
    test('Un usuario SOLO ve sus viajes (Owner) y donde participa', () async {
      // 1. PREPARACIÓN: Crear 2 usuarios (Alice y Bob)
      const aliceId = 'alice';
      const bobId = 'bob';
      await seedUser(aliceId);
      await seedUser(bobId);

      // 2. CREAR ESCENARIO DE DATOS
      // Viaje A: Dueño Alice
      await seedTrip('trip_alice_only', aliceId);

      // Viaje B: Dueño Bob (Alice NO debería verlo)
      await seedTrip('trip_bob_only', bobId);

      // Viaje C: Dueño Bob, pero invita a Alice (Alice SÍ debería verlo)
      await seedTrip('trip_shared', bobId);
      await repo.addParticipant('trip_shared', aliceId, TripRole.viewer);

      // 3. EJECUCIÓN: Alice pide su lista
      final resAlice = await repo.list(aliceId);

      // 4. VERIFICACIÓN (La prueba de fuego)
      expect(resAlice, isA<Ok<List<Trip>>>());
      final tripsAlice = (resAlice as Ok<List<Trip>>).value;

      // Alice debe ver 2 viajes: El suyo y el compartido
      expect(tripsAlice.length, 2);

      final ids = tripsAlice.map((t) => t.id).toList();
      expect(ids, contains('trip_alice_only')); // Es dueña
      expect(ids, contains('trip_shared')); // Es participante
      expect(ids,
          isNot(contains('trip_bob_only'))); // ⛔️ NO debe ver el privado de Bob

      // 5. Verificación cruzada: Bob pide su lista
      final resBob = await repo.list(bobId);
      final tripsBob = (resBob as Ok<List<Trip>>).value;

      // Bob ve sus 2 viajes (el privado y el compartido). NO ve el de Alice.
      final idsBob = tripsBob.map((t) => t.id).toList();
      expect(idsBob, contains('trip_bob_only'));
      expect(idsBob, contains('trip_shared'));
      expect(idsBob, isNot(contains('trip_alice_only')));
    });
  });
}
