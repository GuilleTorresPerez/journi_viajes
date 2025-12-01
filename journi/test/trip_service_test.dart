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

  /// Método auxiliar para filtrar en memoria igual que haría la DB
  List<Trip> _filterForUser(String userId, {TripPhase? phase}) {
    var items = _store.values.toList();

    // 1. Filtro de Seguridad: Soy dueño O soy participante
    items = items.where((t) {
      final isOwner = t.ownerId == userId;
      final isParticipant = t.participants.containsKey(userId);
      return isOwner || isParticipant;
    }).toList();

    // 2. Filtro de Fase
    if (phase != null) {
      items = items.where((t) => t.phase == phase).toList();
    }

    // 3. Orden
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  void _emit() {
    // Emitimos la lista completa cruda al stream.
    // Los listeners filtrarán según su userId.
    _ctrl.add(_store.values.toList());
  }

  @override
  Future<Result<Trip>> upsert(Trip trip) async {
    _store[trip.id] = trip;
    _emit();
    return Ok(trip);
  }

  @override
  Future<Result<Trip?>> findById(String id) async => Ok(_store[id]);

  // 👇 CORREGIDO: Añadido argumento userId
  @override
  Future<Result<List<Trip>>> list(String userId, {TripPhase? phase}) async {
    return Ok(_filterForUser(userId, phase: phase));
  }

  // 👇 CORREGIDO: Añadido argumento userId y lógica de map
  @override
  Stream<List<Trip>> watchAll(String userId, {TripPhase? phase}) {
    // Si el stream base no ha emitido nada, emitimos vacío o esperamos.
    // Usamos map para transformar cada evento (lista completa) en una lista filtrada para ESTE usuario.
    return _ctrl.stream.map((allTrips) {
      var items = allTrips.where((t) {
        final isOwner = t.ownerId == userId;
        final isParticipant = t.participants.containsKey(userId);
        return isOwner || isParticipant;
      }).toList();

      if (phase != null) {
        items = items.where((t) => t.phase == phase).toList();
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    _store.remove(id);
    _emit();
    return const Ok(unit);
  }

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

    test(
        'getUserRole: Devuelve el rol correcto cuando el trip y usuario existen',
        () async {
      // ARRANGE: Preparamos un trip con participantes en el repositorio
      final tripConParticipantes = Trip.create(
        id: 't_roles',
        ownerId: 'u_owner',
        title: 'Trip con Roles',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        participants: {
          'u_admin': TripRole.admin,
          'u_viewer': TripRole.viewer,
        },
      ).asOk().value;

      // Inyectamos directo al repo (bypaseando el comando create simple)
      await repo.upsert(tripConParticipantes);

      // ACT & ASSERT

      // 1. Caso Owner
      final resOwner = await service.getUserRole('t_roles', 'u_owner');
      expect(expectOk(resOwner), TripRole.admin);

      // 2. Caso Viewer
      final resViewer = await service.getUserRole('t_roles', 'u_viewer');
      expect(expectOk(resViewer), TripRole.viewer);

      // 3. Caso No Participante
      final resAjeno = await service.getUserRole('t_roles', 'u_desconocido');
      expect(expectOk(resAjeno), isNull);
    });

    test('getUserRole: Devuelve error si el trip no existe', () async {
      // ACT
      final res = await service.getUserRole('id_inexistente', 'u1');

      // ASSERT
      expect(res, isA<Err<TripRole?>>());
      expect(
          (res as Err<TripRole?>).errors.first.message, contains('no existe'),
          reason:
              'Debe fallar con mensaje claro si el ID del trip es inválido');
    });
  });
}
