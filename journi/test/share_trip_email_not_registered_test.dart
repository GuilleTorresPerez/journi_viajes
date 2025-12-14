import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/use_cases/share_trip_use_case.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/user.dart';

// FakeUserRepository COPIADO (no modificado)
class FakeUserRepository implements UserRepository {
  final Map<String, User> _users = {};

  @override
  Future<Result<User?>> findByEmail(String email) async {
    try {
      final user =
          _users.values.firstWhere((u) => u.email == email.toLowerCase());
      return Ok(user);
    } catch (_) {
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
  group('Uso colaborativo - email no registrado (test adicional)', () {
    late InMemoryTripRepository tripRepo;
    late FakeUserRepository userRepo;
    late ShareTripUseCase useCase;

    setUp(() {
      tripRepo = InMemoryTripRepository();
      userRepo = FakeUserRepository();
      useCase = ShareTripUseCase(tripRepo, userRepo);
    });

    test('❌ Compartir viaje con email no registrado devuelve error', () async {
      // Arrange
      final trip = (Trip.create(
        id: 't_no_user',
        ownerId: 'owner_1',
        title: 'Viaje',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ) as Ok<Trip>)
          .value;

      await tripRepo.upsert(trip);

      // Act
      final result = await useCase.call('t_no_user', 'noexiste@correo.com');

      // Assert
      expect(result, isA<Err<Unit>>(),
          reason: 'No se debe permitir compartir con un email no registrado');
    });
  });
}
