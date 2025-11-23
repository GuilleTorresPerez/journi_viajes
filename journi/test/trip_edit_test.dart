// Ajusta imports según tu estructura. Si el código está en lib/, usa:
// import 'package:tu_paquete/trip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/application/shared/result.dart'; // <- añade el Result oficial

void main() {
  group('Trip.create - validaciones y normalización', () {
    test('trimea el título y devuelve Ok', () {
      final res = Trip.create(
        id: 't1',
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
        title: '   ',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
      final errors = (res as Err<Trip>).errors.map((e) => e.message).toList();
      expect(errors.any((m) => m.contains('title no puede')), isTrue);
    });

    test('title supera max', () {
      final longTitle = List.filled(Trip.titleMax + 1, 'a').join();
      final res = Trip.create(
        id: 't3',
        title: longTitle,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
      final msgs = (res as Err<Trip>).errors.map((e) => e.message).join(' | ');
      expect(msgs.contains('title supera ${Trip.titleMax}'), isTrue);
    });

    test('description supera max', () {
      final longDesc = List.filled(Trip.descriptionMax + 1, 'x').join();
      final res = Trip.create(
        id: 't4',
        title: 'Ok',
        description: longDesc,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
      final msgs = (res as Err<Trip>).errors.map((e) => e.message).join(' | ');
      expect(
        msgs.contains('description supera ${Trip.descriptionMax}'),
        isTrue,
      );
    });

    test('startDate > endDate -> Err', () {
      final start = DateTime.utc(2025, 1, 2, 12);
      final end = DateTime.utc(2025, 1, 2, 11, 59);
      final res = Trip.create(
        id: 't5',
        title: 'Fechas',
        startDate: start,
        endDate: end,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Err<Trip>>());
      final msgs = (res as Err<Trip>).errors.map((e) => e.message).join(' | ');
      expect(msgs.contains('startDate debe ser <= endDate'), isTrue);
    });

    test('normaliza start/end/createdAt/updatedAt a UTC', () {
      final localStart = DateTime(2025, 1, 1, 10, 0); // local time
      final localEnd = DateTime(2025, 1, 2, 12, 0); // local time
      final ca = DateTime(2025, 1, 1, 8, 0); // local
      final ua = DateTime(2025, 1, 1, 9, 0); // local
      final res = Trip.create(
        id: 't6',
        title: 'UTC',
        startDate: localStart,
        endDate: localEnd,
        createdAt: ca,
        updatedAt: ua,
      );
      final trip = (res as Ok<Trip>).value;
      expect(trip.startDate!.isUtc, isTrue);
      expect(trip.endDate!.isUtc, isTrue);
      expect(trip.createdAt.isUtc, isTrue);
      expect(trip.updatedAt.isUtc, isTrue);
      expect(trip.startDate!.isBefore(trip.endDate!), isTrue);
    });

    test('admite fechas nulas (sin rango) y devuelve Ok', () {
      final res = Trip.create(
        id: 't7',
        title: 'Sin fechas',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(res, isA<Ok<Trip>>());
    });
  });
}
