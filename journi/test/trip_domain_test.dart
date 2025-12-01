import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/trip_extensions.dart';

// Helper para extraer el valor Ok de forma segura en los tests
Trip _unwrap(Result<Trip> r) {
  expect(r, isA<Ok<Trip>>(), reason: 'Se esperaba un Ok<Trip>');
  return (r as Ok<Trip>).value;
}

void main() {
  group('Trip - Factory & Validations', () {
    test('Crea un Trip válido y asigna automáticamente al Owner como Admin',
        () {
      final now = DateTime.now();
      const ownerId = 'u1';

      final res = Trip.create(
        id: 't1',
        ownerId: ownerId, // ✅ Requerido
        title: 'Viaje a Japón',
        createdAt: now,
        updatedAt: now,
      );

      expect(res, isA<Ok<Trip>>());
      final trip = (res as Ok<Trip>).value;

      // Verificaciones básicas
      expect(trip.title, 'Viaje a Japón');
      expect(trip.ownerId, ownerId);

      // 🔐 Verificación de Regla de Negocio: Owner es participante Admin
      expect(trip.participants.containsKey(ownerId), isTrue,
          reason: 'El owner debe estar en la lista de participantes');
      expect(trip.participants[ownerId], TripRole.admin,
          reason: 'El owner debe tener rol de Admin');
    });

    test('Falla si ownerId está vacío o es espacios en blanco', () {
      final res = Trip.create(
        id: 't2',
        ownerId: '   ', // ❌ Inválido
        title: 'Viaje',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(res, isA<Err<Trip>>());
      final msg = (res as Err<Trip>).errors.first.message;
      expect(msg, contains('ownerId'));
    });

    test('Falla si title está vacío', () {
      final res = Trip.create(
        id: 't3',
        ownerId: 'u1',
        title: '   ', // ❌ Inválido
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
    });

    test('Falla si las fechas son incoherentes (Start > End)', () {
      final start = DateTime.utc(2025, 2, 1);
      final end = DateTime.utc(2025, 1, 1); // Anterior al inicio

      final res = Trip.create(
        id: 't4',
        ownerId: 'u1',
        title: 'Fechas Mal',
        startDate: start,
        endDate: end,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(res, isA<Err<Trip>>());
      final msg = (res as Err<Trip>).errors.first.message;
      expect(msg, contains('startDate debe ser <= endDate'));
    });

    test('Normaliza fechas a UTC', () {
      final localStart = DateTime(2025, 1, 1, 10, 0); // Hora local
      final res = Trip.create(
        id: 't5',
        ownerId: 'u1',
        title: 'Test UTC',
        startDate: localStart,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final trip = _unwrap(res);
      expect(trip.startDate!.isUtc, isTrue);
    });

    test('Permite crear Trip con participantes iniciales adicionales', () {
      final res = Trip.create(
        id: 't6',
        ownerId: 'owner_user',
        title: 'Viaje Grupal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: {
          'friend_1': TripRole.viewer,
          'friend_2': TripRole.admin,
        },
      );

      final trip = _unwrap(res);

      // Debe contener al owner (agregado automáticamente) + los 2 amigos
      expect(trip.participants.length, 3);
      expect(trip.participants['owner_user'], TripRole.admin);
      expect(trip.participants['friend_1'], TripRole.viewer);
      expect(trip.participants['friend_2'], TripRole.admin);
    });
  });

  group('Trip - Permissions Logic', () {
    late Trip trip;

    setUp(() {
      trip = _unwrap(Trip.create(
        id: 't_perm',
        ownerId: 'owner',
        title: 'Permisos',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: {
          'admin_amigo': TripRole.admin,
          'viewer_amigo': TripRole.viewer,
        },
      ));
    });

    test('getRole resuelve la jerarquía de roles correctamente', () {
      // 1. Owner es siempre Admin (incluso si no está en el mapa explícitamente, o si lo está)
      expect(trip.getRole('owner'), TripRole.admin,
          reason: 'El ownerId siempre debe resolver a TripRole.admin');

      // 2. Participante Admin explícito
      expect(trip.getRole('admin_amigo'), TripRole.admin,
          reason:
              'Participante listado como admin debe devolver TripRole.admin');

      // 3. Participante Viewer explícito
      expect(trip.getRole('viewer_amigo'), TripRole.viewer,
          reason:
              'Participante listado como viewer debe devolver TripRole.viewer');

      // 4. Usuario no relacionado
      expect(trip.getRole('usuario_random'), isNull,
          reason: 'Usuario ajeno al trip debe devolver null');
    });

    test('isAdmin devuelve true para Owner y Admins', () {
      expect(trip.isAdmin('owner'), isTrue);
      expect(trip.isAdmin('admin_amigo'), isTrue);
      expect(trip.isAdmin('viewer_amigo'), isFalse);
      expect(trip.isAdmin('random_user'), isFalse);
    });

    test('canEdit es equivalente a isAdmin', () {
      expect(trip.canEdit('owner'), isTrue);
      expect(trip.canEdit('viewer_amigo'), isFalse);
    });

    test('isViewer detecta participantes de solo lectura', () {
      expect(trip.isViewer('viewer_amigo'), isTrue);
      expect(trip.isViewer('owner'), isFalse); // Owner es admin, no viewer
      expect(trip.isViewer('random'), isFalse);
    });
  });

  group('Trip - Queries (Phase & Dates)', () {
    test('Detecta correctamente TripPhase', () {
      final now = DateTime.now().toUtc();
      final created = now;

      // 1. Undated
      final undated = _unwrap(Trip.create(
          id: '1',
          ownerId: 'u',
          title: 'x',
          createdAt: created,
          updatedAt: created));
      expect(undated.phase, TripPhase.undated);

      // 2. Planned (Futuro)
      final planned = _unwrap(Trip.create(
        id: '2',
        ownerId: 'u',
        title: 'x',
        startDate: now.add(const Duration(days: 10)),
        createdAt: created,
        updatedAt: created,
      ));
      expect(planned.phase, TripPhase.planned);

      // 3. Ongoing (Ahora)
      final ongoing = _unwrap(Trip.create(
        id: '3',
        ownerId: 'u',
        title: 'x',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        createdAt: created,
        updatedAt: created,
      ));
      expect(ongoing.phase, TripPhase.ongoing);

      // 4. Finished (Pasado)
      final finished = _unwrap(Trip.create(
        id: '4',
        ownerId: 'u',
        title: 'x',
        endDate: now.subtract(const Duration(days: 1)),
        createdAt: created,
        updatedAt: created,
      ));
      expect(finished.phase, TripPhase.finished);
    });
  });
}
