import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_extensions.dart';

// Helper para extraer Ok<Trip> de forma segura
Trip _unwrap(Result<Trip> r) {
  expect(r, isA<Ok<Trip>>(), reason: 'Se esperaba Ok<Trip>');
  return (r as Ok<Trip>).value;
}

void main() {
  group('Uso colaborativo - permisos y roles (Trip)', () {
    test('✅ El owner siempre es Admin (getRole/isAdmin/canEdit)', () {
      final now = DateTime.utc(2025, 1, 1);

      final trip = _unwrap(Trip.create(
        id: 't1',
        ownerId: 'owner',
        title: 'Viaje',
        createdAt: now,
        updatedAt: now,
      ));

      // Owner siempre admin
      expect(trip.getRole('owner'), TripRole.admin);
      expect(trip.isAdmin('owner'), isTrue);
      expect(trip.canEdit('owner'), isTrue);

      // y además se inserta en participants como admin
      expect(trip.participants.containsKey('owner'), isTrue);
      expect(trip.participants['owner'], TripRole.admin);
    });

    test('✅ Un admin (no owner) puede editar y no es viewer', () {
      final now = DateTime.utc(2025, 1, 1);

      final trip = _unwrap(Trip.create(
        id: 't2',
        ownerId: 'owner',
        title: 'Viaje',
        createdAt: now,
        updatedAt: now,
        participants: {
          'admin1': TripRole.admin,
        },
      ));

      expect(trip.getRole('admin1'), TripRole.admin);
      expect(trip.isAdmin('admin1'), isTrue);
      expect(trip.canEdit('admin1'), isTrue);
      expect(trip.isViewer('admin1'), isFalse);
    });

    test('✅ Un viewer no puede editar y sí es viewer', () {
      final now = DateTime.utc(2025, 1, 1);

      final trip = _unwrap(Trip.create(
        id: 't3',
        ownerId: 'owner',
        title: 'Viaje',
        createdAt: now,
        updatedAt: now,
        participants: {
          'viewer1': TripRole.viewer,
        },
      ));

      expect(trip.getRole('viewer1'), TripRole.viewer);
      expect(trip.isViewer('viewer1'), isTrue);
      expect(trip.isAdmin('viewer1'), isFalse);
      expect(trip.canEdit('viewer1'), isFalse);
    });

    test('✅ Un usuario que no participa devuelve null en getRole y no tiene permisos', () {
      final now = DateTime.utc(2025, 1, 1);

      final trip = _unwrap(Trip.create(
        id: 't4',
        ownerId: 'owner',
        title: 'Viaje',
        createdAt: now,
        updatedAt: now,
        participants: {
          'viewer1': TripRole.viewer,
          'admin1': TripRole.admin,
        },
      ));

      expect(trip.getRole('random'), isNull);
      expect(trip.isViewer('random'), isFalse);
      expect(trip.isAdmin('random'), isFalse);
      expect(trip.canEdit('random'), isFalse);
    });

    test('✅ Si en participants intentan poner al owner como viewer, se fuerza a admin', () {
      final now = DateTime.utc(2025, 1, 1);

      final trip = _unwrap(Trip.create(
        id: 't5',
        ownerId: 'owner',
        title: 'Viaje',
        createdAt: now,
        updatedAt: now,
        participants: {
          'owner': TripRole.viewer, // intento de colar viewer
          'viewer1': TripRole.viewer,
        },
      ));

      // Regla: el owner es admin siempre
      expect(trip.getRole('owner'), TripRole.admin);
      expect(trip.participants['owner'], TripRole.admin,
          reason: 'Trip.create debe sobrescribir el rol del owner a admin');
    });
  });
}
