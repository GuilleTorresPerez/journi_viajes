import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/application/use_cases/use_cases.dart';
import 'package:flutter/foundation.dart';

/// ---------------------------
/// FakeTripRepository (in-memory)
/// ---------------------------
class FakeTripRepository implements TripRepository {
  final _store = <String, Trip>{};
  late final StreamController<List<Trip>> _ctrl;

  FakeTripRepository() {
    _ctrl = StreamController<List<Trip>>.broadcast(
      onListen: () {
        _emit(); // estado inicial
      },
    );
  }

  List<Trip> _snapshot({TripPhase? phase}) {
    var items = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // createdAt DESC
    if (phase != null) {
      items = items.where((t) => t.phase == phase).toList();
    }
    return items;
  }

  void _emit() {
    // emite lista completa; watchers con phase aplican map()
    _ctrl.add(_snapshot());
  }

  @override
  Future<Result<Trip>> upsert(Trip trip) async {
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
    return Ok(_snapshot(phase: phase));
  }

  @override
  Stream<List<Trip>> watchAll({TripPhase? phase}) {
    if (phase == null) return _ctrl.stream;
    return _ctrl.stream.map((_) => _snapshot(phase: phase));
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    // 👈 Unit unificado
    _store.remove(id);
    _emit();
    return const Ok(unit); // 👈 Ok<Unit>
  }

  void dispose() {
    _ctrl.close();
  }
}

/// ---------------------------
/// Helpers para tests
/// ---------------------------
T expectOk<T>(Result<T> r) {
  expect(r, isA<Ok<T>>());
  return (r as Ok<T>).value;
}

List<AppError> expectErrList<T>(Result<T> r) {
  expect(r, isA<Err<T>>());
  return (r as Err<T>).errors;
}

CreateTripCommand makeCmd({
  required String id,
  required String title,
  String? description,
  String? cover,
  DateTime? start,
  DateTime? end,
}) {
  return CreateTripCommand(
    id: id,
    title: title,
    description: description,
    coverImage: cover,
    startDate: start,
    endDate: end,
  );
}

void main() {
  group('DefaultTripService', () {
    late FakeTripRepository repo;
    late DefaultTripService service;

    setUp(() {
      repo = FakeTripRepository();
      service = DefaultTripService(repo: repo);
    });

    tearDown(() {
      repo.dispose();
    });

    test('create: Ok y persistencia básica', () async {
      final res = await service.create(makeCmd(id: 't1', title: 'Viaje A'));
      final trip = expectOk(res);
      expect(trip.id, 't1');
      expect(trip.title, 'Viaje A');

      final read = await service.getById('t1');
      final stored = expectOk(read);
      expect(stored?.id, 't1');
      expect(stored?.title, 'Viaje A');
    });

    test('create: Err si title vacío', () async {
      final res = await service.create(makeCmd(id: 'bad', title: '   '));
      final errs = expectErrList(res);
      expect(
        errs.map((e) => e.message),
        contains('title no puede estar vacío'),
      );
    });

    test('getById: Ok(null) si no existe', () async {
      final res = await service.getById('nope');
      final val = expectOk(res);
      expect(val, isNull);
    });

    test('patch: actualización parcial y nulabilidad controlada', () async {
      // Arrange: crear
      final created = expectOk(
        await service.create(
          makeCmd(
            id: 't2',
            title: 'Origen',
            description: 'desc',
            cover: 'img.png',
          ),
        ),
      );

      // Act: Patch ausente en coverImage (no cambia), description -> null, title ausente
      final patched = await service.patch(
        UpdateTripCommand(id: created.id, description: const Patch.value(null)),
      );
      final after = expectOk(patched);

      // Assert
      expect(after.title, 'Origen'); // no cambió
      expect(after.description, isNull); // se puso a null
      expect(after.coverImage, 'img.png'); // ausente => se mantiene
    });

    test('patch: title = null -> Err de validación', () async {
      final created = expectOk(
        await service.create(makeCmd(id: 't3', title: 'Titulo')),
      );

      final res = await service.patch(
        UpdateTripCommand(id: created.id, title: const Patch.value(null)),
      );

      final errs = expectErrList(res);
      expect(
        errs.map((e) => e.message),
        contains('title no puede ser null; usa un string no vacío'),
      );
    });

    test('deleteById: elimina y watch emite [] -> [t4] -> []', () async {
      final streamIds = service
          .watch()
          .map((items) => items.map((t) => t.id).toList())
          .distinct(listEquals); // 👈 evita duplicados consecutivos

      final expectation = expectLater(
        streamIds,
        emitsInOrder([
          <String>[], // inicial
          ['t4'], // tras crear
          <String>[], // tras borrar
        ]),
      );

      await pumpEventQueue(); // 👈 entrega el inicial

      await service.create(makeCmd(id: 't4', title: 'Trip 4'));
      await service.deleteById('t4');

      await expectation;
    });

    test('updateTitleById: Ok actualiza título', () async {
      final created = expectOk(
        await service.create(makeCmd(id: 't5', title: 'Antes')),
      );
      final res = await service.updateTitleById(created.id, 'Después');
      final updated = expectOk(res);
      expect(updated.title, 'Después');
    });

    test('updateTitleById: Err si id no existe', () async {
      final res = await service.updateTitleById('missing', 'X');
      final errs = expectErrList(res);
      expect(errs.single.message, 'Trip con id missing no existe');
    });

    test('list: filtra por phase (planned/finished/ongoing/undated)', () async {
      // finished (pasado)
      await service.create(
        makeCmd(
          id: 'f',
          title: 'Pasado',
          start: DateTime.utc(2000, 1, 1),
          end: DateTime.utc(2000, 1, 10),
        ),
      );
      // planned (futuro)
      await service.create(
        makeCmd(
          id: 'p',
          title: 'Futuro',
          start: DateTime.utc(3000, 1, 1),
          end: DateTime.utc(3000, 1, 10),
        ),
      );
      // ongoing (cruza hoy)
      final now = DateTime.now().toUtc();
      await service.create(
        makeCmd(
          id: 'o',
          title: 'Ahora',
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)),
        ),
      );
      // undated
      await service.create(makeCmd(id: 'u', title: 'Sin fechas'));

      final finishedIds = (expectOk(
        await service.list(phase: TripPhase.finished),
      )).map((t) => t.id).toList();
      final plannedIds = (expectOk(
        await service.list(phase: TripPhase.planned),
      )).map((t) => t.id).toList();
      final ongoingIds = (expectOk(
        await service.list(phase: TripPhase.ongoing),
      )).map((t) => t.id).toList();
      final undatedIds = (expectOk(
        await service.list(phase: TripPhase.undated),
      )).map((t) => t.id).toList();

      expect(finishedIds, containsAll(['f']));
      expect(plannedIds, containsAll(['p']));
      expect(ongoingIds, containsAll(['o']));
      expect(undatedIds, containsAll(['u']));
    });

    test(
      'listForDayUtc: devuelve solo los que ocurren en ese día (UTC)',
      () async {
        await service.create(
          makeCmd(
            id: 'd1',
            title: 'Día exacto',
            start: DateTime.utc(2024, 1, 10),
            end: DateTime.utc(2024, 1, 10, 23, 59, 59),
          ),
        );
        await service.create(
          makeCmd(
            id: 'd2',
            title: 'Fuera de día',
            start: DateTime.utc(2024, 1, 11),
            end: DateTime.utc(2024, 1, 12),
          ),
        );

        final res = await service.listForDayUtc(DateTime.utc(2024, 1, 10));
        final items = expectOk(res);
        expect(items.map((t) => t.id), ['d1']);
      },
    );

    test('watch con phase: solo emite cambios de la fase solicitada', () async {
      final streamIds = service
          .watch(phase: TripPhase.undated)
          .map((items) => items.map((t) => t.id).toList())
          .distinct(listEquals); // 👈 evita ['x'] repetido

      final expectation = expectLater(
        streamIds,
        emitsInOrder([
          <String>[], // inicial
          ['x'], // creamos undated
          <String>[], // borramos undated
        ]),
      );

      await pumpEventQueue(); // 👈 entrega el inicial

      await service.create(makeCmd(id: 'x', title: 'Undated'));
      // Cambios en otras fases ya no reemiten 'x' por .distinct
      await service.create(
        makeCmd(
          id: 'y',
          title: 'Planned',
          start: DateTime.utc(3000, 1, 1),
          end: DateTime.utc(3000, 1, 2),
        ),
      );
      await service.deleteById('x');

      await expectation;
    });
  });
}
