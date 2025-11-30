import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/application/use_cases/use_cases.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/domain/user.dart';

class FakeTripRepository implements TripRepository {
  final _store = <String, Trip>{};
  late final StreamController<List<Trip>> _ctrl;

  FakeTripRepository() {
    _ctrl = StreamController<List<Trip>>.broadcast(
      onListen: () {
        _emit();
      },
    );
  }

  List<Trip> _snapshot({TripPhase? phase}) {
    var items = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (phase != null) items = items.where((t) => t.phase == phase).toList();
    return items;
  }

  void _emit() => _ctrl.add(_snapshot());
  @override
  Future<Result<Trip>> upsert(Trip trip) async {
    _store[trip.id] = trip;
    _emit();
    return Ok(trip);
  }

  @override
  Future<Result<Trip?>> findById(String id) async => Ok(_store[id]);
  @override
  Future<Result<List<Trip>>> list({TripPhase? phase}) async =>
      Ok(_snapshot(phase: phase));
  @override
  Stream<List<Trip>> watchAll({TripPhase? phase}) {
    if (phase == null) return _ctrl.stream;
    return _ctrl.stream.map((_) => _snapshot(phase: phase));
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    _store.remove(id);
    _emit();
    return const Ok(unit);
  }

  // 👇 CORRECCIÓN: Firma exacta a la interfaz (posicional, no named)
  @override
  Future<Result<Unit>> addParticipant(
          String t, String u, TripRole role) async =>
      const Ok(unit);

  @override
  Future<Result<Unit>> removeParticipant(String tripId, String userId) async =>
      const Ok(unit);

  void dispose() => _ctrl.close();
}

class FakeEntryRepository implements EntryRepository {
  @override
  Future<Result<Entry>> upsert(Entry entry) async => Ok(entry);
  @override
  Future<Result<Unit>> deleteById(String id) async => const Ok(unit);
  @override
  Future<Result<Entry?>> findById(String id) async => const Ok(null);
  @override
  Future<Result<List<Entry>>> list({String? tripId, EntryType? type}) async =>
      const Ok([]);
  @override
  Stream<List<Entry>> watchAll({String? tripId, EntryType? type}) =>
      const Stream.empty();
}

class FakeGeocodingRepository implements GeocodingRepository {
  @override
  Future<Result<String?>> getCountryFromCoordinates(
          double lat, double lon) async =>
      const Ok('Test Country');
}

class FakeUserRepository implements UserRepository {
  @override
  Future<Result<User>> upsert(User user) async => Ok(user);
  @override
  Future<Result<User?>> findById(String id) async => const Ok(null);
  @override
  Future<Result<User?>> findByEmail(String email) async => const Ok(null);
  @override
  Future<Result<Unit>> deleteById(String id) async => const Ok(unit);
  @override
  Stream<List<User>> watchAll() => const Stream.empty();
}

T expectOk<T>(Result<T> r) {
  expect(r, isA<Ok<T>>());
  return (r as Ok<T>).value;
}

CreateTripCommand makeCmd(
    {required String id,
    required String ownerId,
    required String title,
    String? description,
    String? cover,
    DateTime? start,
    DateTime? end}) {
  return CreateTripCommand(
      id: id,
      ownerId: ownerId,
      title: title,
      description: description,
      coverImage: cover,
      startDate: start,
      endDate: end);
}

void main() {
  group('DefaultTripService', () {
    late FakeTripRepository repo;
    late FakeEntryRepository entryRepo;
    late FakeGeocodingRepository geoRepo;
    late FakeUserRepository userRepo;
    late DefaultTripService service;

    setUp(() {
      repo = FakeTripRepository();
      entryRepo = FakeEntryRepository();
      geoRepo = FakeGeocodingRepository();
      userRepo = FakeUserRepository();

      service = makeTripService(repo, userRepo, entryRepo, geoRepo);
    });

    tearDown(() {
      repo.dispose();
    });

    test('create: Ok y persistencia básica', () async {
      final res = await service
          .create(makeCmd(id: 't1', ownerId: 'u1', title: 'Viaje A'));
      final trip = expectOk(res);
      expect(trip.id, 't1');
      expect(trip.ownerId, 'u1');
    });
  });
}
