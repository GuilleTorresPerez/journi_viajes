import 'package:flutter_test/flutter_test.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/use_cases/get_trip_country_use_case.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';

// ----------------------------------------------------------------------
// 1. Mocks / Fakes específicos para este test
//    (Los definimos aquí para tener control total sobre lo que devuelven)
// ----------------------------------------------------------------------

class MockEntryRepository implements EntryRepository {
  final List<Entry> _entries;

  MockEntryRepository(this._entries);

  @override
  Future<Result<List<Entry>>> list({String? tripId, EntryType? type}) async {
    // Simulamos que devolvemos la lista que nos pasen en el constructor
    return Ok(_entries);
  }

  // Métodos no usados en este test (pueden tirar error o no hacer nada)
  @override
  Future<Result<Unit>> deleteById(String id) async => const Ok(unit);
  @override
  Future<Result<Entry?>> findById(String id) async => const Ok(null);
  @override
  Future<Result<Entry>> upsert(Entry entry) async => Ok(entry);
  @override
  Stream<List<Entry>> watchAll({String? tripId, EntryType? type}) =>
      const Stream.empty();
}

class MockGeocodingRepository implements GeocodingRepository {
  // Simulamos la respuesta de la API
  @override
  Future<Result<String?>> getCountryFromCoordinates(
      double lat, double lon) async {
    if (lat == 40.416 && lon == -3.703) {
      return const Ok('España');
    }
    return const Ok('País Desconocido');
  }
}

// ----------------------------------------------------------------------
// 2. El Test Suite
// ----------------------------------------------------------------------

void main() {
  group('GetTripCountryUseCase', () {
    test('Devuelve null si el viaje no tiene entradas', () async {
      // Arrange (Preparación)
      final emptyRepo = MockEntryRepository([]); // Lista vacía
      final geoRepo = MockGeocodingRepository();
      final useCase = GetTripCountryUseCase(emptyRepo, geoRepo);

      // Act (Ejecución)
      final result = await useCase('trip1');

      // Assert (Verificación)
      expect(result, isA<Ok<String?>>());
      expect((result as Ok<String?>).value, isNull);
    });

    test('Devuelve null si hay entradas pero ninguna tiene ubicación',
        () async {
      // Arrange
      final entryNoLoc = Entry.create(
        id: 'e1',
        tripId: 'trip1',
        type: EntryType.note,
        text: 'Nota sin gps',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).asOk().value;

      final repo = MockEntryRepository([entryNoLoc]);
      final geoRepo = MockGeocodingRepository();
      final useCase = GetTripCountryUseCase(repo, geoRepo);

      // Act
      final result = await useCase('trip1');

      // Assert
      expect((result as Ok<String?>).value, isNull);
    });

    test('Devuelve el país ("España") si encuentra una entrada con coordenadas',
        () async {
      // Arrange
      final entryWithLoc = Entry.create(
        id: 'e2',
        tripId: 'trip1',
        type: EntryType.location,
        text: 'Plaza Mayor',
        location: const EntryLocation(lat: 40.416, lon: -3.703), // Madrid
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).asOk().value;

      final repo = MockEntryRepository([entryWithLoc]);
      final geoRepo = MockGeocodingRepository();
      final useCase = GetTripCountryUseCase(repo, geoRepo);

      // Act
      final result = await useCase('trip1');

      // Assert
      expect(result, isA<Ok<String?>>());
      expect((result as Ok<String?>).value, 'España');
    });
  });
}
