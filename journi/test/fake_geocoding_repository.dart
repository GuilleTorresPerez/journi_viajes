import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';
import 'package:latlong2/latlong.dart';

/// Fake para pruebas que simula la geocodificación sin llamar a la API real.
class FakeGeocodingRepository implements GeocodingRepository {
  final String? response;

  // Nuevo atributo para mapear búsquedas de nombre a coordenadas
  final Map<String, LatLng?> _mockSearches = {};

  FakeGeocodingRepository({this.response = 'País de Prueba'});

  @override
  Future<Result<String?>> getCountryFromCoordinates(
      double lat, double lon) async {
    return Ok(response);
  }

  /// Añadir un resultado simulado para una búsqueda por nombre
  void addSearchResult(String name, LatLng? location) {
    _mockSearches[name] = location;
  }

  /// Simular búsqueda por nombre
  Future<Result<LatLng?>> searchLocation(String name) async {
    if (_mockSearches.containsKey(name)) {
      return Ok(_mockSearches[name]);
    }
    return Ok(null); // ubicación inexistente
  }
}
