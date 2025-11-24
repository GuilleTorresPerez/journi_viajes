import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';

/// Un doble de prueba para simular la geocodificación sin llamar a la API real.
class FakeGeocodingRepository implements GeocodingRepository {
  final String? response;

  // Podemos pasarle qué queremos que responda en el constructor
  FakeGeocodingRepository({this.response = 'País de Prueba'});

  @override
  Future<Result<String?>> getCountryFromCoordinates(
      double lat, double lon) async {
    return Ok(response);
  }
}
