import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';

class GetTripCountryUseCase {
  final EntryRepository _entryRepo;
  final GeocodingRepository _geoRepo;

  GetTripCountryUseCase(this._entryRepo, this._geoRepo);

  Future<Result<String?>> call(String tripId) async {
    // 1. Obtenemos las entradas del viaje
    final entriesRes = await _entryRepo.list(tripId: tripId);

    if (entriesRes is Err<List<Entry>>) {
      return Err(entriesRes.errors);
    }

    final entries = (entriesRes as Ok<List<Entry>>).value;

    // 2. Buscamos la primera entrada que tenga ubicación definida (lat/lon no nulos)
    // Podríamos hacer lógicas más complejas (país más frecuente), pero KISS (Keep It Simple)
    final entryWithLocation = entries.cast<Entry?>().firstWhere(
          (e) => e?.location != null,
          orElse: () => null,
        );

    if (entryWithLocation == null) {
      // No hay entradas con ubicación, por tanto no hay país deducible.
      return const Ok(null);
    }

    final loc = entryWithLocation.location!;

    // 3. Delegamos al repositorio de geocodificación
    return _geoRepo.getCountryFromCoordinates(loc.lat, loc.lon);
  }
}
