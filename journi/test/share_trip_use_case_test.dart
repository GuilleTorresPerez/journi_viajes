import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/use_cases/share_trip_use_case.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';

// ... (FakeUserRepository se mantiene igual) ...
class FakeUserRepository implements UserRepository {
  final Map<String, User> _users = {};
  void seed(User u) => _users[u.id] = u;
  @override
  Future<Result<User?>> findByEmail(String email) async {
    try {
      final user =
          _users.values.firstWhere((u) => u.email == email.toLowerCase());
      return Ok(user);
    } catch (e) {
      return const Ok(null);
    }
  }

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
    });

    test('Falla si el usuario no existe en el sistema', () async {
      final res = await useCase.call('trip1', 'fantasma@email.com');
      expect(res, isA<Err<Unit>>());
    });

    test('Éxito: Si el usuario existe, se añade al viaje', () async {
      // 1. Arrange
      final trip = (Trip.create(
        id: 't1',
        ownerId: 'u1_owner', // 👈 CORREGIDO: ownerId
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

      // 2. Act
      final res = await useCase.call('t1', 'AMIGO@test.com');

      // 3. Assert
      expect(res, isA<Ok<Unit>>());

      // 4. Assert: Verificar persistencia
      final tripUpdated = (await tripRepo.findById('t1') as Ok<Trip?>).value;

      // 👈 CORREGIDO: Usar el mapa 'participants' en lugar de 'participantIds'
      expect(tripUpdated!.participants.containsKey('u2'), isTrue);
      // Opcional: Verificar rol
      // expect(tripUpdated.participants['u2'], TripRole.viewer);
    });
  });
}
