import 'package:geocoding/geocoding.dart' as geo;
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';

class PlatformGeocodingRepository implements GeocodingRepository {
  @override
  Future<Result<String?>> getCountryFromCoordinates(
      double lat, double lon) async {
    try {
      // Documentación oficial: https://pub.dev/packages/geocoding
      // placemarkFromCoordinates puede lanzar excepciones si no hay red o servicio.
      final placemarks = await geo.placemarkFromCoordinates(lat, lon);

      if (placemarks.isEmpty) {
        return const Ok(null);
      }

      // Retornamos el país del primer resultado relevante.
      // country devuelve el nombre completo, isoCountryCode devuelve el código (ej: ES).
      return Ok(placemarks.first.country);
    } catch (e) {
      // En clean arch, capturamos errores de infra y los devolvemos como AppError o null controlado
      // Para simplificar, si falla la geocodificación, devolvemos error.
      return Err([UnexpectedError('Error en geocodificación: $e')]);
    }
  }
}
