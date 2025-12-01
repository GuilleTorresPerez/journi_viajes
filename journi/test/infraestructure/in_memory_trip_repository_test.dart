import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';

Trip _trip({
  required String id,
  required String title,
  String ownerId = 'u1',
  String? description,
  String? coverImage,
  DateTime? startDate,
  DateTime? endDate,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return Trip(
    id: id,
    ownerId: ownerId,
    title: title,
    description: description,
    coverImage: coverImage,
    startDate: startDate,
    endDate: endDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('InMemoryTripRepository', () {
    late InMemoryTripRepository repo;

    tearDown(() async {
      await repo.dispose();
    });

    test(
      'list() devuelve todos ordenados por createdAt desc (semilla)',
      () async {
        final now = DateTime.now().toUtc();
        final a = _trip(
          id: 'a',
          title: 'A',
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now,
        );
        final b = _trip(
          id: 'b',
          title: 'B',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
        );
        final c = _trip(id: 'c', title: 'C', createdAt: now, updatedAt: now);

        repo = InMemoryTripRepository(seed: [a, b, c]);

        // 👈 CORREGIDO: Pasamos 'u1' (el ownerId por defecto del helper)
        final res = await repo.list('u1');

        expect(res, isA<Ok<List<Trip>>>());
        final list = (res as Ok<List<Trip>>).value;
        // Debe venir c, b, a (desc por createdAt)
        expect(list.map((t) => t.id).toList(), ['c', 'b', 'a']);
      },
    );

    test('findById() devuelve Ok(null) si no existe', () async {
      repo = InMemoryTripRepository();
      final res = await repo.findById('missing');
      expect(res, isA<Ok<Trip?>>());
      expect((res as Ok<Trip?>).value, isNull);
    });

    test(
      'upsert() valida con Trip.create: Err si título vacío y no emite',
      () async {
        repo = InMemoryTripRepository();

        // 👈 CORREGIDO: Pasamos 'u1'
        final s = repo.watchAll('u1');

        var emissions = 0;
        final sub = s.listen((_) {
          emissions++;
        });

        final now = DateTime.now().toUtc();
        final bad = _trip(
          id: 'x',
          title: '   ',
          createdAt: now,
          updatedAt: now,
        );

        final res = await repo.upsert(bad);
        expect(res, isA<Err<Trip>>());

        await Future<void>.delayed(Duration.zero);
        expect(emissions, 0);
        await sub.cancel();
      },
    );

    test('upsert() persiste y normaliza (trim + UTC) y watchAll emite',
        () async {
      repo = InMemoryTripRepository();
      final nowLocal = DateTime.now();

      // 👈 CORREGIDO: Pasamos 'u1'
      final stream = repo.watchAll('u1');

      final future = expectLater(
        stream,
        emits(
          isA<List<Trip>>().having(
            (l) => l.map((t) => t.id).toList(),
            'ids',
            contains('ok1'),
          ),
        ),
      );

      final res = await repo.upsert(
        _trip(
          id: 'ok1',
          ownerId: 'u1',
          title: '   Paris 2026   ',
          startDate: nowLocal,
          endDate: nowLocal.add(const Duration(days: 5)),
          createdAt: nowLocal,
          updatedAt: nowLocal,
        ),
      );

      expect(res, isA<Ok<Trip>>());
      final saved = (res as Ok<Trip>).value;
      expect(saved.title, 'Paris 2026');
      expect(saved.ownerId, 'u1');

      await future;
    });

    test(
      'list({phase}) filtra correctamente y mantiene orden por createdAt desc',
      () async {
        final now = DateTime.now().toUtc();
        final plannedStart = now.add(const Duration(days: 10));
        final plannedEnd = plannedStart.add(const Duration(days: 3));
        final finishedEnd = now.subtract(const Duration(days: 5));
        final finishedStart = finishedEnd.subtract(const Duration(days: 3));
        final ongoingStart = now.subtract(const Duration(days: 1));
        final ongoingEnd = now.add(const Duration(days: 1));

        final trips = [
          _trip(
            id: 'p1',
            title: 'Planned 1',
            startDate: plannedStart,
            endDate: plannedEnd,
            createdAt: now,
            updatedAt: now,
          ),
          _trip(
            id: 'p2',
            title: 'Planned 2',
            startDate: plannedStart,
            endDate: plannedEnd,
            createdAt: now.add(const Duration(seconds: 1)),
            updatedAt: now,
          ),
          _trip(
            id: 'f1',
            title: 'Finished',
            startDate: finishedStart,
            endDate: finishedEnd,
            createdAt: now,
            updatedAt: now,
          ),
          _trip(
            id: 'o1',
            title: 'Ongoing',
            startDate: ongoingStart,
            endDate: ongoingEnd,
            createdAt: now.add(const Duration(minutes: 1)),
            updatedAt: now,
          ),
          _trip(
            id: 'u1',
            title: 'Undated',
            createdAt: now.subtract(const Duration(minutes: 1)),
            updatedAt: now,
          ),
        ];
        repo = InMemoryTripRepository(seed: trips);

        Future<List<String>> ids(TripPhase ph) async {
          // 👈 CORREGIDO: Pasamos 'u1'
          final res = await repo.list('u1', phase: ph);
          return ((res as Ok<List<Trip>>).value).map((t) => t.id).toList();
        }

        expect(await ids(TripPhase.planned), [
          'p2',
          'p1',
        ]);
        expect(await ids(TripPhase.finished), ['f1']);
        expect(await ids(TripPhase.ongoing), ['o1']);
        expect(await ids(TripPhase.undated), ['u1']);
      },
    );

    test('watchAll() emite listas ordenadas en cada upsert/delete', () async {
      final now = DateTime.now().toUtc();
      final a = _trip(id: 'a', title: 'A', createdAt: now, updatedAt: now);
      final b = _trip(
        id: 'b',
        title: 'B',
        createdAt: now.add(const Duration(seconds: 1)),
        updatedAt: now,
      );

      repo = InMemoryTripRepository(seed: [a]);

      // 👈 CORREGIDO: Pasamos 'u1'
      final stream = repo.watchAll('u1');

      final seq = expectLater(
        stream,
        emitsInOrder([
          isA<List<Trip>>().having(
            (l) => l.map((t) => t.id).toList(),
            'ids',
            equals(['b', 'a']),
          ),
          isA<List<Trip>>().having(
            (l) => l.map((t) => t.id).toList(),
            'ids',
            equals(['b']),
          ),
        ]),
      );

      await repo.upsert(b);
      await repo.deleteById('a');

      await seq;
    });

    test(
      'watchAll({phase}) aplica map sobre el stream y solo emite la fase pedida',
      () async {
        final now = DateTime.now().toUtc();
        final planned = _trip(
          id: 'p',
          title: 'Planned',
          createdAt: now,
          updatedAt: now,
          startDate: now.add(const Duration(days: 3)),
          endDate: now.add(const Duration(days: 5)),
        );
        final finished = _trip(
          id: 'f',
          title: 'Finished',
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now,
          startDate: now.subtract(const Duration(days: 3)),
          endDate: now.subtract(const Duration(days: 1)),
        );

        repo = InMemoryTripRepository();

        // 👈 CORREGIDO: Pasamos 'u1'
        final plannedStream = repo.watchAll('u1', phase: TripPhase.planned);

        final ex = expectLater(
          plannedStream,
          emitsInOrder([
            isA<List<Trip>>().having(
              (l) => l.map((t) => t.id).toList(),
              'ids',
              equals(['p']),
            ),
            isA<List<Trip>>().having(
              (l) => l.map((t) => t.id).toList(),
              'ids',
              equals(['p']),
            ),
          ]),
        );

        await repo.upsert(planned);
        await repo.upsert(finished);

        await ex;
      },
    );

    test(
      'watchAll() es broadcast: múltiples listeners reciben las emisiones',
      () async {
        final now = DateTime.now().toUtc();
        repo = InMemoryTripRepository();

        // 👈 CORREGIDO: Pasamos 'u1'
        final s = repo.watchAll('u1');

        final wait1 = expectLater(
          s,
          emits(
            isA<List<Trip>>().having(
              (l) => l.any((t) => t.id == 'x'),
              'contiene x',
              isTrue,
            ),
          ),
        );
        final wait2 = expectLater(
          s,
          emits(
            isA<List<Trip>>().having(
              (l) => l.length,
              'len',
              greaterThanOrEqualTo(1),
            ),
          ),
        );

        await repo.upsert(
          _trip(id: 'x', title: 'X', createdAt: now, updatedAt: now),
        );

        await Future.wait([wait1, wait2]);
      },
    );

    test('dispose() cierra el stream (emite done)', () async {
      repo = InMemoryTripRepository();

      // 👈 CORREGIDO: Pasamos 'u1'
      final s = repo.watchAll('u1');

      final done = expectLater(
        s,
        emitsDone,
      );
      await repo.dispose();
      await done;
    });
  });
}
