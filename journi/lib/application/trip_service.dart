import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/application/use_cases/use_cases.dart';
import 'package:journi/application/use_cases/get_trip_country_use_case.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';
import 'package:journi/application/use_cases/share_trip_use_case.dart';

/// Puerto de servicio (fachada de aplicación).
abstract class TripService {
  Future<Result<Trip>> create(CreateTripCommand cmd);
  Future<Result<Trip>> patch(UpdateTripCommand cmd);
  Future<Result<Unit>> deleteById(String id); // 👈 Unit unificado

  /// Helper que resuelve el `current` por id y delega en UpdateTripTitleUseCase.
  Future<Result<Trip>> updateTitleById(String id, String newTitle);

  /// Lectura/consulta
  Future<Result<Trip?>> getById(String id);
  Future<Result<List<Trip>>> list({TripPhase? phase});
  Stream<List<Trip>> watch({TripPhase? phase});

  /// Consultas específicas
  Future<Result<List<Trip>>> listForDayUtc(DateTime dayUtc);

  /// Obtiene el país del viaje basado en sus entradas.
  Future<Result<String?>> getCountry(String tripId);

  /// Comparte el viaje con otro usuario por email.
  Future<Result<Unit>> shareTrip(String tripId, String email);
}

/// Implementación por defecto del servicio.
class DefaultTripService implements TripService {
  final CreateTripUseCase _createUC;
  final UpdateTripUseCase _updateUC;
  final DeleteTripUseCase _deleteUC;
  final UpdateTripTitleUseCase _updateTitleUC;
  final ListTripsUseCase _listUC;
  final WatchTripsUseCase _watchUC;
  final ListTripsForDayUseCase _listDayUC;
  final TripRepository _repo;
  final GetTripCountryUseCase _getCountryUC; // Nueva dependencia
  final ShareTripUseCase _shareTripUC;

  DefaultTripService({
    required TripRepository repo,
    required UserRepository userRepo,
    required GetTripCountryUseCase getCountryUC,
    CreateTripUseCase? createUC,
    UpdateTripUseCase? updateUC,
    DeleteTripUseCase? deleteUC,
    UpdateTripTitleUseCase? updateTitleUC,
    ListTripsUseCase? listUC,
    WatchTripsUseCase? watchUC,
    ListTripsForDayUseCase? listDayUC,
  })  : _repo = repo,
        _createUC = createUC ?? CreateTripUseCase(repo),
        _updateUC = updateUC ?? UpdateTripUseCase(repo),
        _deleteUC = deleteUC ?? DeleteTripUseCase(repo),
        _updateTitleUC = updateTitleUC ?? UpdateTripTitleUseCase(repo),
        _listUC = listUC ?? ListTripsUseCase(repo),
        _watchUC = watchUC ?? WatchTripsUseCase(repo),
        _listDayUC = listDayUC ?? ListTripsForDayUseCase(repo),
        _getCountryUC = getCountryUC,
        _shareTripUC = ShareTripUseCase(repo, userRepo);

  @override
  Future<Result<Trip>> create(CreateTripCommand cmd) {
    return _createUC(cmd);
  }

  @override
  Future<Result<Trip>> patch(UpdateTripCommand cmd) {
    return _updateUC(cmd);
  }

  @override
  Future<Result<Unit>> deleteById(String id) {
    // 👈 Unit unificado
    return _deleteUC(id);
  }

  @override
  Future<Result<Trip?>> getById(String id) {
    return _repo.findById(id);
  }

  @override
  Future<Result<List<Trip>>> list({TripPhase? phase}) {
    return _listUC(phase: phase);
  }

  @override
  Stream<List<Trip>> watch({TripPhase? phase}) {
    return _watchUC(phase: phase);
  }

  @override
  Future<Result<List<Trip>>> listForDayUtc(DateTime dayUtc) {
    return _listDayUC(dayUtc);
  }

  @override
  Future<Result<Trip>> updateTitleById(String id, String newTitle) async {
    final currentRes = await _repo.findById(id);
    if (currentRes is Err<Trip?>) {
      return Err<Trip>(currentRes.errors);
    }
    final current = (currentRes as Ok<Trip?>).value;
    if (current == null) {
      return Err<Trip>([ValidationError('Trip con id $id no existe')]);
    }
    return _updateTitleUC.call(current, newTitle);
  }

  @override
  Future<Result<String?>> getCountry(String tripId) {
    return _getCountryUC(tripId);
  }

  @override
  Future<Result<Unit>> shareTrip(String tripId, String email) {
    return _shareTripUC(tripId, email);
  }
}

//// Factory cómoda para DI manual:
DefaultTripService makeTripService(
  TripRepository tripRepo,
  UserRepository userRepo, // 1. Añadir argumento aquí
  EntryRepository entryRepo,
  GeocodingRepository geoRepo,
) {
  return DefaultTripService(
    repo: tripRepo,
    userRepo: userRepo, // 2. Pasarlo al constructor aquí
    getCountryUC: GetTripCountryUseCase(entryRepo, geoRepo),
  );
}
