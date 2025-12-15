import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_extensions.dart';
import 'package:journi/application/shared/result.dart';

Trip _unwrap(Result<Trip> r) {
  expect(r, isA<Ok<Trip>>());
  return (r as Ok<Trip>).value;
}

void main() {
  group('Trip collaboration (unit tests)', () {
    test('Owner is always admin', () {
      final trip = _unwrap(
        Trip.create(
          id: 't1',
          ownerId: 'owner_1',
          title: 'Viaje',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(trip.isAdmin('owner_1'), isTrue);
      expect(trip.getRole('owner_1'), TripRole.admin);
    });

    test('Registered user added as viewer has viewer role', () {
      final trip = _unwrap(
        Trip.create(
          id: 't1',
          ownerId: 'owner_1',
          title: 'Viaje',
          participants: {
            'user_2': TripRole.viewer,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(trip.getRole('user_2'), TripRole.viewer);
      expect(trip.isViewer('user_2'), isTrue);
      expect(trip.isAdmin('user_2'), isFalse);
    });

    test('User not in participants has no role (email not registered case)',
        () {
      final trip = _unwrap(
        Trip.create(
          id: 't1',
          ownerId: 'owner_1',
          title: 'Viaje',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(trip.getRole('ghost_user'), isNull);
      expect(trip.isAdmin('ghost_user'), isFalse);
      expect(trip.isViewer('ghost_user'), isFalse);
    });

    test('Owner remains admin even if explicitly added as viewer', () {
      final trip = _unwrap(
        Trip.create(
          id: 't1',
          ownerId: 'owner_1',
          title: 'Viaje',
          participants: {
            'owner_1': TripRole.viewer, // intento incorrecto
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(trip.getRole('owner_1'), TripRole.admin);
      expect(trip.isAdmin('owner_1'), isTrue);
    });
  });
}
