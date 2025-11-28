import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/use_cases/share_trip_use_case.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';

// --- Fakes necesarios para el test ---

/// Fake simple para simular búsqueda de usuarios
class FakeUserRepository implements UserRepository {
  final Map<String, User> _users = {};

  void seed(User u) => _users[u.id] = u;

  @override
  Future<Result<User?>> findByEmail(String email) async {
    try {
      final user = _users.values.firstWhere(
        (u) => u.email == email.toLowerCase(),
      );
      return Ok(user);
    } catch (e) {
      return const Ok(null); // No encontrado
    }
  }

  // Métodos no usados en este test
  @override
  Future<Result<User>> upsert(User user) async => Ok(user);
  @override
  Future<Result<User?>> findById(String id) async => const Ok(null);
  @override
  Future<Result<Unit>> deleteById(String id) async => const Ok(unit);
  @override
  Stream<List<User>> watchAll() => const Stream.empty();
}

void main() {
  group('ShareTripUseCase (Unit Test)', () {
    late InMemoryTripRepository tripRepo;
    late FakeUserRepository userRepo;
    late ShareTripUseCase useCase;

    setUp(() {
      tripRepo = InMemoryTripRepository();
      userRepo = FakeUserRepository();
      useCase = ShareTripUseCase(tripRepo, userRepo);
    });

    test('Falla si el email está vacío', () async {
      final res = await useCase.call('trip1', '');
      expect(res, isA<Err<Unit>>());
      expect(
          res.asErr().errors.first.message, contains('no puede estar vacío'));
    });

    test('Falla si el usuario no existe en el sistema', () async {
      final res = await useCase.call('trip1', 'fantasma@email.com');

      expect(res, isA<Err<Unit>>());
      final msg = res.asErr().errors.first.message;
      expect(msg, contains('no encontrado'));
    });

    test('Éxito: Si el usuario existe, se añade al viaje', () async {
      // 1. Arrange: Crear viaje y usuario
      final trip = (Trip.create(
        id: 't1',
        title: 'Viaje Solo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ) as Ok<Trip>)
          .value;

      final user = (User.create(
        id: 'u2',
        name: 'Amigo',
        lastName: 'Viajero',
        email: 'amigo@test.com',
        passwordHash: 'x',
        passwordSalt: 'y',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ) as Ok<User>)
          .value;

      await tripRepo.upsert(trip);
      userRepo.seed(user);

      // 2. Act: Compartir
      final res = await useCase.call(
          't1', 'AMIGO@test.com'); // Probamos case-insensitive

      // 3. Assert: Resultado OK
      expect(res, isA<Ok<Unit>>());

      // 4. Assert: Verificar persistencia en el repo
      final tripUpdated = (await tripRepo.findById('t1') as Ok<Trip?>).value;
      expect(tripUpdated!.participantIds, contains('u2'));
    });
  });
}
