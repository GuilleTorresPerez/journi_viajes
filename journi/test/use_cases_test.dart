import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/application/use_cases/use_cases.dart';
import 'package:journi/domain/trip_queries.dart';

/// In-memory repo completo para tests.
class InMemoryTripRepo implements TripRepository {
  final Map<String, Trip> _store = {};
  final _controller = StreamController<List<Trip>>.broadcast();

  int upsertCalls = 0;
  Trip? lastUpserted;
  Result<Trip>? upsertResultOverride;

  void seed(Trip t) {
    _store[t.id] = t;
    _emit();
  }

  void resetCounters() {
    upsertCalls = 0;
    lastUpserted = null;
  }

  void _emit() {
    _controller.add(
      _store.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<Result<Trip>> upsert(Trip trip) async {
    upsertCalls++;
    lastUpserted = trip;
    if (upsertResultOverride != null) {
      return upsertResultOverride!;
    }
    _store[trip.id] = trip;
    _emit();
    return Ok(trip);
  }

  @override
  Future<Result<Trip?>> findById(String id) async {
    return Ok(_store[id]);
  }

  @override
  Future<Result<List<Trip>>> list({TripPhase? phase}) async {
    var items = _store.values.toList();
    if (phase != null) {
      items = items.where((t) => t.phase == phase).toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Ok(items);
  }

  @override
  Stream<List<Trip>> watchAll({TripPhase? phase}) {
    if (phase == null) return _controller.stream;
    return _controller.stream.map(
      (all) => all.where((t) => t.phase == phase).toList(),
    );
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    _store.remove(id);
    _emit();
    return const Ok(unit);
  }

  // 👇 CORRECCIÓN: Firma exacta a la interfaz (TripRole role es posicional obligatorio)
  @override
  Future<Result<Unit>> addParticipant(
      String tripId, String userId, TripRole role) async {
    final t = _store[tripId];
    if (t == null) {
      return Err([ValidationError('Trip not found')]);
    }

    // Si ya existe y tiene el mismo rol, ignoramos.
    // Si queremos actualizar el rol, deberíamos permitirlo, pero para este mock simple:
    if (t.participants.containsKey(userId) && t.participants[userId] == role) {
      return const Ok(unit);
    }

    final newParticipants = Map<String, TripRole>.from(t.participants);
    newParticipants[userId] = role; // Asignamos el rol pasado por parámetro

    final updated = Trip.create(
      id: t.id,
      ownerId: t.ownerId,
      title: t.title,
      description: t.description,
      coverImage: t.coverImage,
      startDate: t.startDate,
      endDate: t.endDate,
      createdAt: t.createdAt,
      updatedAt: DateTime.now().toUtc(),
      participants: newParticipants,
    );

    _store[tripId] = (updated as Ok<Trip>).value;
    _emit();
    return const Ok(unit);
  }

  @override
  Future<Result<Unit>> removeParticipant(String tripId, String userId) async {
    final t = _store[tripId];
    if (t == null) return const Ok(unit);

    final newParticipants = Map<String, TripRole>.from(t.participants);
    newParticipants.remove(userId);

    final updated = (Trip.create(
      id: t.id,
      ownerId: t.ownerId,
      title: t.title,
      description: t.description,
      coverImage: t.coverImage,
      startDate: t.startDate,
      endDate: t.endDate,
      createdAt: t.createdAt,
      updatedAt: DateTime.now().toUtc(),
      participants: newParticipants,
    ) as Ok<Trip>)
        .value;

    _store[tripId] = updated;
    _emit();
    return const Ok(unit);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('CreateTripUseCase', () {
    late InMemoryTripRepo repo;
    late CreateTripUseCase useCase;

    setUp(() {
      repo = InMemoryTripRepo();
      useCase = CreateTripUseCase(repo);
    });

    tearDown(() => repo.dispose());

    test('falla si el título está vacío (no llama al repo)', () async {
      final cmd = CreateTripCommand(id: 't1', ownerId: 'u1', title: '   ');
      final res = await useCase.call(cmd);
      expect(res, isA<Err<Trip>>());
      expect(repo.upsertCalls, 0);
    });

    test('crea y persiste un Trip válido, normalizando fechas a UTC', () async {
      final nowBefore = DateTime.now().toUtc();

      final localStart = DateTime(2024, 5, 1, 12, 0);
      final localEnd = DateTime(2024, 5, 10, 18, 30);

      final cmd = CreateTripCommand(
        id: 't2',
        ownerId: 'u1',
        title: '  Eurotrip  ',
        description: 'desc',
        coverImage: 'img.png',
        startDate: localStart,
        endDate: localEnd,
      );

      final res = await useCase.call(cmd);
      final nowAfter = DateTime.now().toUtc();

      expect(res, isA<Ok<Trip>>());
      final trip = (res as Ok<Trip>).value;

      expect(repo.upsertCalls, 1);
      expect(repo.lastUpserted, isNotNull);
      expect(trip.title, 'Eurotrip');
      expect(trip.ownerId, 'u1');

      bool inWindow(DateTime d) =>
          !d.isBefore(nowBefore) && !d.isAfter(nowAfter);
      expect(inWindow(trip.createdAt), isTrue);
      expect(inWindow(trip.updatedAt), isTrue);
      expect(trip.updatedAt.isAtSameMomentAs(trip.createdAt), isTrue);
      expect(trip.startDate!.isUtc, isTrue);
      expect(trip.endDate!.isUtc, isTrue);
    });

    test('propaga un Err del repositorio en la persistencia', () async {
      repo.upsertResultOverride = Err<Trip>([
        ValidationError('fallo persistencia'),
      ]);

      final cmd =
          CreateTripCommand(id: 't3', ownerId: 'u1', title: 'Título válido');
      final res = await useCase.call(cmd);

      expect(res, isA<Err<Trip>>());
      expect(repo.upsertCalls, 1);
    });
  });

  group('UpdateTripTitleUseCase', () {
    late InMemoryTripRepo repo;
    late UpdateTripTitleUseCase useCase;
    late Trip baseTrip;

    setUp(() {
      repo = InMemoryTripRepo();
      useCase = UpdateTripTitleUseCase(repo);

      final created = Trip.create(
        id: 'b1',
        ownerId: 'u1',
        title: 'Base',
        description: 'd',
        coverImage: 'c.png',
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 1, 3),
        createdAt: DateTime.utc(2024, 1, 1, 8, 0),
        updatedAt: DateTime.utc(2024, 1, 1, 8, 0),
      );
      baseTrip = (created as Ok<Trip>).value;
    });

    tearDown(() => repo.dispose());

    test('falla si el nuevo título es inválido (no llama al repo)', () async {
      final res = await useCase.call(baseTrip, '   ');
      expect(res, isA<Err<Trip>>());
      expect(repo.upsertCalls, 0);
    });

    test('actualiza título y updatedAt, preserva id/createdAt', () async {
      final prevUpdated = baseTrip.updatedAt;

      final res = await useCase.call(baseTrip, 'Road Trip');

      expect(res, isA<Ok<Trip>>());
      final updated = (res as Ok<Trip>).value;

      expect(repo.upsertCalls, 1);
      expect(repo.lastUpserted!.title, 'Road Trip');

      expect(updated.id, baseTrip.id);
      expect(updated.ownerId, baseTrip.ownerId);
      expect(updated.createdAt.isAtSameMomentAs(baseTrip.createdAt), isTrue);

      expect(updated.updatedAt.isAfter(prevUpdated), isTrue);
    });

    test('propaga Err del repositorio al persistir', () async {
      repo.upsertResultOverride = Err<Trip>([ValidationError('db caído')]);

      final res = await useCase.call(baseTrip, 'Nuevo título');
      expect(res, isA<Err<Trip>>());
      expect(repo.upsertCalls, 1);
    });
  });

  group('UpdateTripUseCase (Patch tri-estado)', () {
    late InMemoryTripRepo repo;
    late UpdateTripUseCase useCase;
    late Trip baseTrip;

    setUp(() async {
      repo = InMemoryTripRepo();
      useCase = UpdateTripUseCase(repo);

      final created = Trip.create(
        id: 'u1',
        ownerId: 'user1',
        title: 'Vacaciones en Italia',
        description: 'Roma, Florencia y Venecia',
        coverImage: 'italia.jpg',
        startDate: DateTime.utc(2025, 7, 1),
        endDate: DateTime.utc(2025, 7, 10),
        createdAt: DateTime.utc(2025, 1, 1, 10, 0),
        updatedAt: DateTime.utc(2025, 1, 1, 10, 0),
      ) as Ok<Trip>;
      baseTrip = created.value;
      repo.seed(baseTrip);
      repo.resetCounters();
    });

    tearDown(() => repo.dispose());

    test(
      'no tocar campos (todo Patch.absent) solo actualiza updatedAt',
      () async {
        final prev = baseTrip;

        final res = await useCase.call(const UpdateTripCommand(id: 'u1'));

        expect(res, isA<Ok<Trip>>());
        final updated = (res as Ok<Trip>).value;
        expect(repo.upsertCalls, 1);

        expect(updated.id, prev.id);
        expect(updated.ownerId, prev.ownerId);
        expect(updated.title, prev.title);
        expect(updated.updatedAt.isAfter(prev.updatedAt), isTrue);
      },
    );

    test(
      'Patch.value(null) limpia descripción; Patch.absent no toca portada',
      () async {
        final res = await useCase.call(
          const UpdateTripCommand(
            id: 'u1',
            description: Patch.value(null),
            coverImage: Patch.absent(),
          ),
        );

        expect(res, isA<Ok<Trip>>());
        final t = (res as Ok<Trip>).value;

        expect(t.description, isNull);
        expect(t.coverImage, baseTrip.coverImage);
      },
    );

    test('Patch.value(x) cambia título y fechas (UTC), respeta validaciones',
        () async {
      final res = await useCase.call(
        UpdateTripCommand(
          id: 'u1',
          title: const Patch.value(' Italia 2025  '),
          startDate: Patch.value(DateTime(2025, 7, 2, 8)),
          endDate: Patch.value(DateTime(2025, 7, 12, 18)),
        ),
      );

      expect(res, isA<Ok<Trip>>());
      final t = (res as Ok<Trip>).value;
      expect(t.title, 'Italia 2025');
      expect(t.startDate!.isUtc, isTrue);
    });

    test('startDate > endDate -> Err y no llama a upsert', () async {
      repo.resetCounters();
      final res = await useCase.call(
        UpdateTripCommand(
          id: 'u1',
          startDate: Patch.value(DateTime.utc(2025, 7, 20)),
          endDate: Patch.value(DateTime.utc(2025, 7, 10)),
        ),
      );
      expect(res, isA<Err<Trip>>());
      expect(repo.upsertCalls, 0);
    });

    test('title: Patch.value(null) -> Err (modo estricto)', () async {
      repo.resetCounters();
      final res = await useCase.call(
        const UpdateTripCommand(id: 'u1', title: Patch.value(null)),
      );
      expect(res, isA<Err<Trip>>());
      expect(repo.upsertCalls, 0);
    });

    test('id inexistente -> Err', () async {
      final res = await useCase.call(const UpdateTripCommand(id: 'nope'));
      expect(res, isA<Err<Trip>>());
    });
  });

  group('DeleteTripUseCase', () {
    late InMemoryTripRepo repo;
    late DeleteTripUseCase useCase;
    late Trip t;

    setUp(() {
      repo = InMemoryTripRepo();
      useCase = DeleteTripUseCase(repo);
      t = (Trip.create(
        id: 'd1',
        ownerId: 'u1',
        title: 'Borrar-me',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      ) as Ok<Trip>)
          .value;
      repo.seed(t);
    });

    tearDown(() => repo.dispose());

    test('elimina y es idempotente', () async {
      final r1 = await useCase.call('d1');
      expect(r1, isA<Ok<void>>());

      final after1 = await repo.findById('d1');
      expect(after1, isA<Ok<Trip?>>());
      expect((after1 as Ok<Trip?>).value, isNull);

      final r2 = await useCase.call('d1');
      expect(r2, isA<Ok<void>>());
    });
  });

  group('ListTripsForDayUseCase', () {
    late InMemoryTripRepo repo;
    late ListTripsForDayUseCase useCase;

    setUp(() {
      repo = InMemoryTripRepo();
      useCase = ListTripsForDayUseCase(repo);

      final a = (Trip.create(
        id: 'a',
        ownerId: 'u1',
        title: 'A',
        startDate: DateTime.utc(2025, 6, 1),
        endDate: DateTime.utc(2025, 6, 3),
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      ) as Ok<Trip>)
          .value;

      final b = (Trip.create(
        id: 'b',
        ownerId: 'u1',
        title: 'B',
        startDate: DateTime.utc(2025, 6, 3),
        endDate: DateTime.utc(2025, 6, 5),
        createdAt: DateTime.utc(2025, 1, 2),
        updatedAt: DateTime.utc(2025, 1, 2),
      ) as Ok<Trip>)
          .value;

      final c = (Trip.create(
        id: 'c',
        ownerId: 'u1',
        title: 'C',
        createdAt: DateTime.utc(2025, 1, 3),
        updatedAt: DateTime.utc(2025, 1, 3),
      ) as Ok<Trip>)
          .value;

      repo.seed(a);
      repo.seed(b);
      repo.seed(c);
    });

    tearDown(() => repo.dispose());

    test('filtra por día UTC usando occursOn', () async {
      final res = await useCase.call(DateTime.utc(2025, 6, 3));
      expect(res, isA<Ok<List<Trip>>>());
      final list = (res as Ok<List<Trip>>).value;

      final ids = list.map((t) => t.id).toSet();
      expect(ids, {'a', 'b'});
    });
  });
}
