import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/use_cases/use_cases.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/data/memory/in_memory_trip_repository.dart';
import 'package:journi/data/memory/in_memory_entry_repository.dart';
import 'fake_geocoding_repository.dart';

void main() {
  group('Trip.delete', () {
    test('create + deleteById -> Ok<Unit>', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final userRepo = DriftUserRepository(db);

      final repo = InMemoryTripRepository();
      final entryRepo = InMemoryEntryRepository();
      final geoRepo = FakeGeocodingRepository();

      final tripService = makeTripService(
        repo,
        userRepo,
        entryRepo,
        geoRepo,
      );

      final cmd = CreateTripCommand(
        id: 'id0',
        ownerId: 'u1', // 👈 CORREGIDO: Requerido
        title: 'El Nano',
        description: 'Description',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );

      await tripService.create(cmd);
      final res = await repo.deleteById('id0');

      expect(res, isA<Ok<Unit>>());

      await db.close();
    });
  });
}
