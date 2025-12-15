import 'package:flutter_test/flutter_test.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/application/shared/result.dart';

Trip _unwrapTrip(Result<Trip> r) {
  expect(r, isA<Ok<Trip>>());
  return (r as Ok<Trip>).value;
}

Entry _unwrapEntry(Result<Entry> r) {
  expect(r, isA<Ok<Entry>>());
  return (r as Ok<Entry>).value;
}

void main() {
  group('Trip filters by date (unit tests)', () {
    test('Trip occurs on a given day inside its date range', () {
      final trip = _unwrapTrip(
        Trip.create(
          id: 't1',
          ownerId: 'u1',
          title: 'Viaje',
          startDate: DateTime.utc(2025, 1, 10),
          endDate: DateTime.utc(2025, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(trip.occursOn(DateTime.utc(2025, 1, 12)), isTrue);
      expect(trip.occursOn(DateTime.utc(2025, 1, 9)), isFalse);
      expect(trip.occursOn(DateTime.utc(2025, 1, 16)), isFalse);
    });

    test('Two trips overlap in dates', () {
      final t1 = _unwrapTrip(
        Trip.create(
          id: 't1',
          ownerId: 'u1',
          title: 'Viaje 1',
          startDate: DateTime.utc(2025, 1, 10),
          endDate: DateTime.utc(2025, 1, 20),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final t2 = _unwrapTrip(
        Trip.create(
          id: 't2',
          ownerId: 'u2',
          title: 'Viaje 2',
          startDate: DateTime.utc(2025, 1, 15),
          endDate: DateTime.utc(2025, 1, 25),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(t1.overlapsWith(t2), isTrue);
    });

    test('Trips without dates never match date filters', () {
      final trip = _unwrapTrip(
        Trip.create(
          id: 't1',
          ownerId: 'u1',
          title: 'Sin fechas',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(trip.occursOn(DateTime.utc(2025, 1, 10)), isFalse);
    });
  });

  group('Trip filters by location (unit tests)', () {
    test('Entry with valid location is accepted', () {
      final entry = _unwrapEntry(
        Entry.create(
          id: 'e1',
          tripId: 't1',
          type: EntryType.location,
          text: 'Roma',
          location: const EntryLocation(lat: 41.9028, lon: 12.4964),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(entry.location, isNotNull);
      expect(entry.location!.lat, closeTo(41.9, 0.1));
      expect(entry.location!.lon, closeTo(12.4, 0.1));
    });

    test('Entry without location does not match location filter', () {
      final entry = _unwrapEntry(
        Entry.create(
          id: 'e1',
          tripId: 't1',
          type: EntryType.note,
          text: 'Nota sin ubicación',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(entry.location, isNull);
    });

    test('Invalid coordinates are rejected', () {
      final res = Entry.create(
        id: 'e1',
        tripId: 't1',
        type: EntryType.location,
        text: 'Lugar inválido',
        location: const EntryLocation(lat: 200, lon: 300),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(res, isA<Err<Entry>>());
    });
  });
}
