import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/entry.dart';
import 'dart:math';

// ----------------- helpers unwrap -----------------
Trip _unwrapTrip(Result<Trip> r) {
  expect(r, isA<Ok<Trip>>(), reason: 'Se esperaba Ok<Trip>');
  return (r as Ok<Trip>).value;
}

Entry _unwrapEntry(Result<Entry> r) {
  expect(r, isA<Ok<Entry>>(), reason: 'Se esperaba Ok<Entry>');
  return (r as Ok<Entry>).value;
}

// ----------------- filtro por fechas (solape) -----------------
bool _overlapsDates({
  required DateTime? tripStart,
  required DateTime? tripEnd,
  required DateTime? filterStart,
  required DateTime? filterEnd,
}) {
  if (filterStart == null && filterEnd == null) return true;

  // Si hay filtro y el trip no tiene fechas, lo excluimos
  if (tripStart == null && tripEnd == null) return false;

  final s = (tripStart ?? tripEnd)!.toUtc();
  final e = (tripEnd ?? tripStart)!.toUtc();

  final fs = filterStart?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final fe = filterEnd?.toUtc() ?? DateTime.utc(9999, 12, 31);

  return !(e.isBefore(fs) || s.isAfter(fe));
}

// ----------------- distancia (haversine) -----------------
double _deg2rad(double deg) => deg * 3.141592653589793 / 180.0;

double _haversineKm(EntryLocation a, EntryLocation b) {
  const r = 6371.0; // km
  final dLat = _deg2rad(b.lat - a.lat);
  final dLon = _deg2rad(b.lon - a.lon);
  final lat1 = _deg2rad(a.lat);
  final lat2 = _deg2rad(b.lat);

  final h = (sin(dLat / 2) * sin(dLat / 2)) +
      (cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2));
  final c = 2 * atan2(sqrt(h), sqrt(1 - h));
  return r * c;
}

bool _matchesLocationByEntries({
  required String tripId,
  required List<Entry> entries,
  String query = '',
  EntryLocation? near,
  double radiusKm = 10,
}) {
  final q = query.trim().toLowerCase();

  // Si no hay filtro de ubicación, pasa
  final hasTextFilter = q.isNotEmpty;
  final hasNearFilter = near != null;

  if (!hasTextFilter && !hasNearFilter) return true;

  final tripEntries = entries.where((e) => e.tripId == tripId);

  for (final e in tripEntries) {
    // 1) match por texto (si existe)
    if (hasTextFilter) {
      final t = (e.text ?? '').toLowerCase();
      if (t.contains(q)) return true;
    }

    // 2) match por proximidad de coordenadas
    if (hasNearFilter && e.location != null) {
      final d = _haversineKm(e.location!, near!);
      if (d <= radiusKm) return true;
    }
  }
  return false;
}

List<Trip> filterTrips({
  required List<Trip> trips,
  required List<Entry> entries,
  DateTime? start,
  DateTime? end,
  String locationTextQuery = '',
  EntryLocation? near,
  double radiusKm = 10,
}) {
  return trips.where((t) {
    final dateOk = _overlapsDates(
      tripStart: t.startDate,
      tripEnd: t.endDate,
      filterStart: start,
      filterEnd: end,
    );

    final locOk = _matchesLocationByEntries(
      tripId: t.id,
      entries: entries,
      query: locationTextQuery,
      near: near,
      radiusKm: radiusKm,
    );

    return dateOk && locOk;
  }).toList();
}

void main() {
  group('Filtros de viajes por fecha y ubicación (via Entries)', () {
    late List<Trip> trips;
    late List<Entry> entries;

    setUp(() {
      final created = DateTime.utc(2025, 1, 1);

      trips = [
        _unwrapTrip(Trip.create(
          id: 't_japon',
          ownerId: 'u1',
          title: 'Japón',
          startDate: DateTime.utc(2025, 2, 1),
          endDate: DateTime.utc(2025, 2, 10),
          createdAt: created,
          updatedAt: created,
        )),
        _unwrapTrip(Trip.create(
          id: 't_zgz',
          ownerId: 'u1',
          title: 'Zaragoza',
          startDate: DateTime.utc(2025, 3, 5),
          endDate: DateTime.utc(2025, 3, 12),
          createdAt: created,
          updatedAt: created,
        )),
        _unwrapTrip(Trip.create(
          id: 't_sin_fechas',
          ownerId: 'u1',
          title: 'Sin fechas',
          createdAt: created,
          updatedAt: created,
        )),
      ];

      entries = [
        // Entrada en Japón (texto + coordenadas Tokio aprox)
        _unwrapEntry(Entry.create(
          id: 'e1',
          tripId: 't_japon',
          type: EntryType.location,
          text: 'Tokio - Shibuya',
          location: const EntryLocation(lat: 35.6895, lon: 139.6917),
          createdAt: created,
          updatedAt: created,
        )),

        // Entrada en Zaragoza (texto + coordenadas Zaragoza aprox)
        _unwrapEntry(Entry.create(
          id: 'e2',
          tripId: 't_zgz',
          type: EntryType.location,
          text: 'Zaragoza centro',
          location: const EntryLocation(lat: 41.6488, lon: -0.8891),
          createdAt: created,
          updatedAt: created,
        )),

        // Entrada sin ubicación pero con texto útil
        _unwrapEntry(Entry.create(
          id: 'e3',
          tripId: 't_zgz',
          type: EntryType.note,
          text: 'Calle Alfonso, Zaragoza',
          createdAt: created,
          updatedAt: created,
        )),
      ];
    });

    test('✅ Sin filtros devuelve todos los trips', () {
      final res = filterTrips(trips: trips, entries: entries);
      expect(res.length, 3);
    });

    test('✅ Filtro por fechas (marzo 2025) devuelve solo Zaragoza', () {
      final res = filterTrips(
        trips: trips,
        entries: entries,
        start: DateTime.utc(2025, 3, 1),
        end: DateTime.utc(2025, 3, 31),
      );
      expect(res.map((t) => t.id).toList(), ['t_zgz']);
    });

    test('✅ Si hay filtro de fechas, excluye trips sin fechas', () {
      final res = filterTrips(
        trips: trips,
        entries: entries,
        start: DateTime.utc(2025, 1, 1),
        end: DateTime.utc(2025, 12, 31),
      );
      expect(res.any((t) => t.id == 't_sin_fechas'), isFalse);
    });

    test('✅ Filtro por ubicación (texto) devuelve el trip que tenga una Entry que lo mencione', () {
      final res = filterTrips(
        trips: trips,
        entries: entries,
        locationTextQuery: 'zaragoza',
      );
      expect(res.map((t) => t.id).toList(), ['t_zgz']);
    });

    test('✅ Filtro por ubicación (cercanía coords) devuelve el trip cercano', () {
      // Punto cerca de Zaragoza
      const nearZgz = EntryLocation(lat: 41.65, lon: -0.88);

      final res = filterTrips(
        trips: trips,
        entries: entries,
        near: nearZgz,
        radiusKm: 20, // 20km para hacerlo estable
      );

      expect(res.map((t) => t.id).toList(), ['t_zgz']);
    });

    test('✅ Combinado: marzo 2025 + "zaragoza" devuelve Zaragoza', () {
      final res = filterTrips(
        trips: trips,
        entries: entries,
        start: DateTime.utc(2025, 3, 1),
        end: DateTime.utc(2025, 3, 31),
        locationTextQuery: 'zaragoza',
      );
      expect(res.length, 1);
      expect(res.first.id, 't_zgz');
    });
  });
}
