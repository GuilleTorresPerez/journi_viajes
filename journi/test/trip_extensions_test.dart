import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_extensions.dart';

Trip _okTrip(Result<Trip> r) {
  expect(r, isA<Ok<Trip>>());
  return (r as Ok<Trip>).value;
}

Trip _baseTrip() => _okTrip(
      Trip.create(
        id: 'base',
        title: 'Base',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      ),
    );

void main() {
  group('TripMutators (extension methods)', () {
    // Las extension methods son parte del lenguaje y se usan como métodos de instancia. :contentReference[oaicite:5]{index=5}
    test('withTitle: cambia y revalida (ok)', () {
      final t = _baseTrip();
      final res = t.withTitle('  Nuevo título  ');
      final out = _okTrip(res);
      expect(out.title, 'Nuevo título');
      expect(out.id, t.id); // identidad se mantiene
    });

    test('withTitle: invalid -> Err', () {
      final t = _baseTrip();
      final res = t.withTitle('   ');
      expect(res, isA<Err<Trip>>());
      final msgs = (res as Err<Trip>).errors.map((e) => e.message).join();
      expect(msgs.contains('title no puede'), isTrue);
    });

    test('withDescription: cambia y respeta límites', () {
      final t = _baseTrip();
      final out = _okTrip(t.withDescription('Desc ok'));
      expect(out.description, 'Desc ok');

      final tooLong = List.filled(Trip.descriptionMax + 1, 'x').join();
      final err = t.withDescription(tooLong);
      expect(err, isA<Err<Trip>>());
    });

    test('withDates: aplica UTC y revalida rango', () {
      final t = _baseTrip();
      final startLocal = DateTime(2025, 1, 10, 10);
      final endLocal = DateTime(2025, 1, 12, 10);
      final out = _okTrip(t.withDates(start: startLocal, end: endLocal));
      expect(out.startDate!.isUtc, isTrue);
      expect(out.endDate!.isUtc, isTrue);
      expect(out.startDate!.isBefore(out.endDate!), isTrue);

      // rango inválido
      final bad = t.withDates(
        start: DateTime.utc(2025, 1, 12),
        end: DateTime.utc(2025, 1, 11),
      );
      expect(bad, isA<Err<Trip>>());
    });

    test('copyValidated: actualiza múltiples campos manteniendo id', () {
      final t = _baseTrip();
      final now = DateTime.utc(2025, 2, 1);
      final res = t.copyValidated(
        title: 'Cambiado',
        description: 'Nueva desc',
        coverImage: 'https://img/1.png',
        startDate: DateTime.utc(2025, 2, 10),
        endDate: DateTime.utc(2025, 2, 12),
        updatedAt: now,
      );
      final out = _okTrip(res);
      expect(out.id, t.id);
      expect(out.title, 'Cambiado');
      expect(out.description, 'Nueva desc');
      expect(out.coverImage, 'https://img/1.png');
      expect(out.startDate, isNotNull);
      expect(out.endDate, isNotNull);
      expect(out.updatedAt, now);
    });

    test('copyValidated: si un cambio invalida, devuelve Err', () {
      final t = _baseTrip();
      final res = t.copyValidated(title: ' '); // título inválido
      expect(res, isA<Err<Trip>>());
    });
  });
}
