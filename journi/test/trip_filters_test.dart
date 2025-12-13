import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';

// ✅ Helper para extraer Ok<Trip>
Trip _unwrap(Result<Trip> r) {
  expect(r, isA<Ok<Trip>>(), reason: 'Se esperaba un Ok<Trip>');
  return (r as Ok<Trip>).value;
}

/// ------------------------------------------------------------
/// Helpers de filtro (si ya tenéis algo parecido en trip_queries.dart
/// o trip_extensions.dart, usa lo vuestro y borra esto).
/// ------------------------------------------------------------

bool _matchesLocation(Trip trip, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  // ✅ CAMBIA AQUÍ si tenéis un campo real de ubicación:
  // Ejemplos: trip.city, trip.country, trip.locationName, trip.placeName...
  //
  // Plan B: por ahora buscamos en el título (rápido y funciona).
  final text = trip.title.toLowerCase();

  return text.contains(q);
}

bool _overlapsDates({
  required DateTime? tripStart,
  required DateTime? tripEnd,
  required DateTime? filterStart,
  required DateTime? filterEnd,
}) {
  // Si no hay filtro de fechas => siempre pasa
  if (filterStart == null && filterEnd == null) return true;

  // Interpretación típica:
  // - Si el trip no tiene fechas, no lo incluimos cuando hay filtro.
  if (tripStart == null && tripEnd == null) return false;

  // Normalizamos: si falta start o end en el trip, lo tratamos como un "punto"
  final s = (tripStart ?? tripEnd)!.toUtc();
  final e = (tripEnd ?? tripStart)!.toUtc();

  final fs = filterStart?.toUtc();
  final fe = filterEnd?.toUtc();

  // Rango del filtro
  final rangeStart = fs ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final rangeEnd = fe ?? DateTime.utc(9999, 12, 31);

  // Solape de intervalos [s,e] con [rangeStart, rangeEnd]
  return !(e.isBefore(rangeStart) || s.isAfter(rangeEnd));
}

List<Trip> filterTrips({
  required List<Trip> trips,
  DateTime? start,
  DateTime? end,
  String locationQuery = '',
}) {
  return trips.where((t) {
    return _overlapsDates(
          tripStart: t.startDate,
          tripEnd: t.endDate,
          filterStart: start,
          filterEnd: end,
        ) &&
        _matchesLocation(t, locationQuery);
  }).toList();
}

void main() {
  group('Filtros de viajes - fecha y ubicación', () {
    late List<Trip> trips;

    setUp(() {
      final created = DateTime.utc(2025, 1, 1);
      trips = [
        _unwrap(Trip.create(
          id: 't1',
          ownerId: 'u1',
          title: 'Japón - Tokio',
          startDate: DateTime.utc(2025, 2, 1),
          endDate: DateTime.utc(2025, 2, 10),
          createdAt: created,
          updatedAt: created,
        )),
        _unwrap(Trip.create(
          id: 't2',
          ownerId: 'u1',
          title: 'España - Zaragoza',
          startDate: DateTime.utc(2025, 3, 5),
          endDate: DateTime.utc(2025, 3, 12),
          createdAt: created,
          updatedAt: created,
        )),
        _unwrap(Trip.create(
          id: 't3',
          ownerId: 'u1',
          title: 'Italia - Roma',
          startDate: DateTime.utc(2024, 12, 20),
          endDate: DateTime.utc(2024, 12, 28),
          createdAt: created,
          updatedAt: created,
        )),
        _unwrap(Trip.create(
          id: 't4',
          ownerId: 'u1',
          title: 'Viaje sin fechas (placeholder)',
          createdAt: created,
          updatedAt: created,
        )),
      ];
    });

    test('✅ Sin filtros devuelve todos', () {
      final res = filterTrips(trips: trips);
      expect(res.length, 4);
    });

    test('✅ Filtro por ubicación (case-insensitive) devuelve los correctos',
        () {
      final res = filterTrips(trips: trips, locationQuery: 'japón');
      expect(res.map((t) => t.id).toList(), ['t1']);
    });

    test('✅ Filtro por fechas devuelve los que solapan el rango', () {
      // Rango que solo toca marzo 2025 -> debería devolver Zaragoza
      final res = filterTrips(
        trips: trips,
        start: DateTime.utc(2025, 3, 1),
        end: DateTime.utc(2025, 3, 31),
      );

      expect(res.map((t) => t.id).toList(), ['t2']);
    });

    test('✅ Filtro por fechas excluye viajes sin fechas', () {
      final res = filterTrips(
        trips: trips,
        start: DateTime.utc(2025, 1, 1),
        end: DateTime.utc(2025, 12, 31),
      );

      expect(res.any((t) => t.id == 't4'), isFalse,
          reason:
              'Si hay filtro de fechas, un trip sin fechas no debería salir');
    });

    test('✅ Combinado: ubicación + rango fechas', () {
      // Marzo 2025 + "España" -> t2
      final res = filterTrips(
        trips: trips,
        start: DateTime.utc(2025, 3, 1),
        end: DateTime.utc(2025, 3, 31),
        locationQuery: 'españa',
      );

      expect(res.length, 1);
      expect(res.first.id, 't2');
    });

    test('✅ Si locationQuery está vacío, no filtra por ubicación', () {
      final res = filterTrips(trips: trips, locationQuery: '   ');
      expect(res.length, 4);
    });
  });
}
