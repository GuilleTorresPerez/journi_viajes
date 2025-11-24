import 'package:journi/application/shared/result.dart';

/// Puerto para servicios de geocodificación inversa.
/// Sigue el principio de Inversión de Dependencia.
abstract class GeocodingRepository {
  /// Devuelve el código ISO o nombre del país dado una latitud y longitud.
  Future<Result<String?>> getCountryFromCoordinates(double lat, double lon);
}
