import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';

void main() {
  group('Trip.create - validaciones y normalización', () {
    test('trimea el título y devuelve Ok', () {
      final res = Trip.create(
        id: 't1',
        ownerId: 'u1', // 👈 CORREGIDO
        title: '  Mi viaje  ',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Ok<Trip>>());
      final trip = (res as Ok<Trip>).value;
      expect(trip.title, 'Mi viaje');
    });

    test('title vacío -> Err', () {
      final res = Trip.create(
        id: 't2',
        ownerId: 'u1', // 👈 CORREGIDO
        title: '   ',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
    });

    test('title supera max', () {
      final longTitle = List.filled(Trip.titleMax + 1, 'a').join();
      final res = Trip.create(
        id: 't3',
        ownerId: 'u1', // 👈 CORREGIDO
        title: longTitle,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
    });

    test('description supera max', () {
      final longDesc = List.filled(Trip.descriptionMax + 1, 'x').join();
      final res = Trip.create(
        id: 't4',
        ownerId: 'u1', // 👈 CORREGIDO
        title: 'Ok',
        description: longDesc,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
    });

    test('startDate > endDate -> Err', () {
      final start = DateTime.utc(2025, 1, 2, 12);
      final end = DateTime.utc(2025, 1, 2, 11, 59);
      final res = Trip.create(
        id: 't5',
        ownerId: 'u1', // 👈 CORREGIDO
        title: 'Fechas',
        startDate: start,
        endDate: end,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
    });

    test('normaliza start/end/createdAt/updatedAt a UTC', () {
      final localStart = DateTime(2025, 1, 1, 10, 0);
      final localEnd = DateTime(2025, 1, 2, 12, 0);
      final ca = DateTime(2025, 1, 1, 8, 0);
      final ua = DateTime(2025, 1, 1, 9, 0);
      final res = Trip.create(
        id: 't6',
        ownerId: 'u1', // 👈 CORREGIDO
        title: 'UTC',
        startDate: localStart,
        endDate: localEnd,
        createdAt: ca,
        updatedAt: ua,
      );
      final trip = (res as Ok<Trip>).value;
      expect(trip.startDate!.isUtc, isTrue);
      // ...
    });

    test('admite fechas nulas (sin rango) y devuelve Ok', () {
      final res = Trip.create(
        id: 't7',
        ownerId: 'u1', // 👈 CORREGIDO
        title: 'Sin fechas',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Ok<Trip>>());
    });
  });
}
