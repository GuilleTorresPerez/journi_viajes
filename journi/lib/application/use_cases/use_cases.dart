import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_extensions.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/trip_queries.dart';

/// Patch<T> permite tri-estado en commands de actualización:
/// - Patch.absent()  -> no tocar
/// - Patch.value(x)  -> establecer a x
/// - Patch.value(null) -> establecer a null (si el campo lo permite)
class Patch<T> {
  final bool isSet;
  final T? value;
  const Patch._(this.isSet, this.value);
  const Patch.absent() : this._(false, null);
  const Patch.value(T? v) : this._(true, v);
}

class CreateTripCommand {
  final String id;
  final String title;
  final String? description;
  final String? coverImage;
  final DateTime? startDate;
  final DateTime? endDate;

  CreateTripCommand({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    this.startDate,
    this.endDate,
  });
}

class UpdateTripCommand {
  final String id;
  final Patch<String> title;
  final Patch<String?> description;
  final Patch<String?> coverImage;
  final Patch<DateTime?> startDate;
  final Patch<DateTime?> endDate;

  const UpdateTripCommand({
    required this.id,
    this.title = const Patch.absent(),
    this.description = const Patch.absent(),
    this.coverImage = const Patch.absent(),
    this.startDate = const Patch.absent(),
    this.endDate = const Patch.absent(),
  });
}

class CreateTripUseCase {
  final TripRepository repo;
  CreateTripUseCase(this.repo);

  Future<Result<Trip>> call(CreateTripCommand cmd) async {
    final now = DateTime.now().toUtc();
    final res = Trip.create(
      id: cmd.id,
      title: cmd.title,
      description: cmd.description,
      coverImage: cmd.coverImage,
      startDate: cmd.startDate,
      endDate: cmd.endDate,
      createdAt: now,
      updatedAt: now,
    );
    if (res is Err<Trip>) return res;
    return repo.upsert((res as Ok<Trip>).value);
  }
}

/// Use case: actualización parcial validada (patch).
class UpdateTripUseCase {
  final TripRepository repo;
  UpdateTripUseCase(this.repo);

  Future<Result<Trip>> call(UpdateTripCommand cmd) async {
    final currentRes = await repo.findById(cmd.id);
    if (currentRes is Err<Trip?>) {
      return Err<Trip>((currentRes).errors);
    }
    final current = (currentRes as Ok<Trip?>).value;
    if (current == null) {
      return Err<Trip>([ValidationError('Trip con id ${cmd.id} no existe')]);
    }
    if (cmd.title.isSet && cmd.title.value == null) {
      return Err<Trip>([
        ValidationError('title no puede ser null; usa un string no vacío'),
      ]);
    }

    // Calcula nuevos valores (permitiendo null si el patch lo fija a null)
    final newTitle = cmd.title.isSet
        ? (cmd.title.value ?? current.title)
        : current.title;
    final newDescription = cmd.description.isSet
        ? cmd.description.value
        : current.description;
    final newCoverImage = cmd.coverImage.isSet
        ? cmd.coverImage.value
        : current.coverImage;
    final newStart = cmd.startDate.isSet
        ? cmd.startDate.value
        : current.startDate;
    final newEnd = cmd.endDate.isSet ? cmd.endDate.value : current.endDate;

    final nowUtc = DateTime.now().toUtc();
    final validated = Trip.create(
      id: current.id,
      title: newTitle,
      description: newDescription,
      coverImage: newCoverImage,
      startDate: newStart,
      endDate: newEnd,
      createdAt: current.createdAt,
      updatedAt: nowUtc,
    );
    if (validated is Err<Trip>) return validated;
    return repo.upsert((validated as Ok<Trip>).value);
  }
}

/// Use case: eliminar por id (idempotente según la implementación del repo).
class DeleteTripUseCase {
  final TripRepository repo;
  DeleteTripUseCase(this.repo);

  Future<Result<Unit>> call(String id) {
    return repo.deleteById(id);
  }
}

class UpdateTripTitleUseCase {
  final TripRepository repo;
  UpdateTripTitleUseCase(this.repo);

  Future<Result<Trip>> call(Trip current, String newTitle) async {
    final res = current.withTitle(newTitle);
    if (res is Err<Trip>) return res;

    final ok = res as Ok<Trip>;
    final updatedRes = ok.value.copyValidated(
      updatedAt: DateTime.now().toUtc(),
    );
    if (updatedRes is Err<Trip>) return updatedRes;

    final updated = (updatedRes as Ok<Trip>).value;
    return repo.upsert(updated);
  }
}

/// Lista trips (opcionalmente filtrados por fase).
class ListTripsUseCase {
  final TripRepository repo;
  ListTripsUseCase(this.repo);

  /// Devuelve todos los trips, o solo los de una fase concreta.
  /// Delegamos el orden a la implementación del repo (en memoria: createdAt DESC).
  Future<Result<List<Trip>>> call({TripPhase? phase}) {
    return repo.list(phase: phase);
  }
}

/// Observa trips en tiempo real (ideal para usar con StreamBuilder en Flutter).
class WatchTripsUseCase {
  final TripRepository repo;
  WatchTripsUseCase(this.repo);

  /// Emite cambios en la colección (filtrable por fase).
  Stream<List<Trip>> call({TripPhase? phase}) => repo.watchAll(phase: phase);
}

/// Listado por día concreto (UTC). Útil para vistas de calendario.
/// Usa Trip.occursOn(dayUtc) definido en trip_queries.dart.
class ListTripsForDayUseCase {
  final TripRepository repo;
  ListTripsForDayUseCase(this.repo);

  Future<Result<List<Trip>>> call(DateTime dayUtc) async {
    final res = await repo.list();
    if (res is Err<List<Trip>>) return res;
    final items = (res as Ok<List<Trip>>).value
        .where((t) => t.occursOn(dayUtc.toUtc()))
        .toList();
    return Ok(items);
  }
}
