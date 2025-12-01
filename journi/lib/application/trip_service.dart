import 'package:journi/domain/trip.dart'; // 👈 Aquí está TripRole
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
  Future<Result<Unit>> deleteById(String id);

  Future<Result<Trip>> updateTitleById(String id, String newTitle);

  Future<Result<Trip?>> getById(String id);
  Future<Result<List<Trip>>> list(String userId, {TripPhase? phase});
  Stream<List<Trip>> watch(String userId, {TripPhase? phase});

  Future<Result<List<Trip>>> listForDayUtc(String userId, DateTime dayUtc);

  Future<Result<String?>> getCountry(String tripId);

  /// Comparte el viaje con otro usuario por email.
  /// ⚠️ CAMBIO: Ahora aceptamos un rol opcional (por defecto viewer)
  Future<Result<Unit>> shareTrip(String tripId, String email,
      {TripRole role = TripRole.viewer});
  
  /// Obtiene el rol de un usuario en un viaje específico.
  /// Devuelve Ok(null) si el usuario no participa en el viaje.
  Future<Result<TripRole?>> getUserRole(String tripId, String userId);
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
  final GetTripCountryUseCase _getCountryUC;
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
    // Nota: El 'cmd' ahora incluye ownerId, el servicio solo lo pasa.
    return _createUC(cmd);
  }

  @override
  Future<Result<Trip>> patch(UpdateTripCommand cmd) {
    return _updateUC(cmd);
  }

  @override
  Future<Result<Unit>> deleteById(String id) {
    return _deleteUC(id);
  }

  @override
  Future<Result<Trip?>> getById(String id) {
    return _repo.findById(id);
  }

  @override
  Future<Result<List<Trip>>> list(String userId, {TripPhase? phase}) {
    // Pasamos el userId al caso de uso o directamente al repo
    // (Idealmente actualizarías ListTripsUseCase también)
    return _repo.list(userId, phase: phase);
  }

  @override
  Stream<List<Trip>> watch(String userId, {TripPhase? phase}) {
    return _repo.watchAll(userId, phase: phase);
  }

  @override
  Future<Result<List<Trip>>> listForDayUtc(String userId, DateTime dayUtc) {
    return _listDayUC(userId, dayUtc);
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
  Future<Result<Unit>> shareTrip(String tripId, String email,
      {TripRole role = TripRole.viewer}) {
    // ⚠️ CAMBIO: Pasamos el argumento 'role' al caso de uso
    return _shareTripUC(tripId, email, role: role);
  }

  @override
  Future<Result<TripRole?>> getUserRole(String tripId, String userId) async {
    // 1. Recuperamos el viaje del repositorio
    final result = await _repo.findById(tripId);

    // 2. Manejo de errores usando programación funcional (Result monad)
    if (result is Err<Trip?>) {
      return Err<TripRole?>(result.errors);
    }

    final trip = (result as Ok<Trip?>).value;

    // 3. Validamos existencia
    if (trip == null) {
      return Err<TripRole?>([
        const ValidationError('El viaje solicitado no existe.')
      ]);
    }

    // 4. Delegamos la lógica al Dominio (la extensión que creamos arriba)
    final role = trip.getRole(userId);

    return Ok<TripRole?>(role);
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
