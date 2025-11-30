import 'package:drift/drift.dart' as d;
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart'; // Asegúrate que Trip tenga ownerId y participants
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'app_database.dart' as db;

// -------- Mapper actualizado --------
// Ahora requiere el mapa de participantes para reconstruir el dominio
Trip _toDomain(db.DbTrip row, Map<String, TripRole> participants) {
  // Nota: row.ownerId podría venir nulo si la migración dejó datos antiguos incompletos.
  // Usamos una cadena vacía o manejamos el error según política de negocio.
  final safeOwnerId = row.ownerId ?? '';

  final res = Trip.create(
    id: row.id,
    ownerId: safeOwnerId,
    title: row.title,
    description: row.description,
    coverImage: row.coverImage,
    startDate: row.startDate,
    endDate: row.endDate,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    participants: participants,
  );

  return res.isOk
      ? res.asOk().value
      : Trip(
          // Fallback crudo si la validación falla por datos corruptos en DB
          id: row.id,
          ownerId: safeOwnerId,
          title: row.title,
          description: row.description,
          coverImage: row.coverImage,
          startDate: row.startDate,
          endDate: row.endDate,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
          participants: participants,
        );
}

db.TripsCompanion _toCompanion(Trip t) => db.TripsCompanion(
      id: d.Value(t.id),
      ownerId: d.Value(t.ownerId), // 👈 Guardamos ownerId
      title: d.Value(t.title),
      description: d.Value(t.description),
      coverImage: d.Value(t.coverImage),
      startDate: d.Value(t.startDate?.toUtc()),
      endDate: d.Value(t.endDate?.toUtc()),
      createdAt: d.Value(t.createdAt.toUtc()),
      updatedAt: d.Value(t.updatedAt.toUtc()),
    );

class DriftTripRepository implements TripRepository {
  final db.AppDatabase _db;
  DriftTripRepository(this._db);

  /// Helper privado para obtener los participantes de un viaje.
  Future<Map<String, TripRole>> _getParticipants(String tripId) async {
    final rows = await (_db.select(_db.tripParticipants)
          ..where((tbl) => tbl.tripId.equals(tripId)))
        .get();

    return {
      for (final r in rows) r.userId: r.role,
    };
  }

  @override
  Future<Result<Trip>> upsert(Trip trip) async {
    // 1. Validar dominio
    final validated = Trip.create(
      id: trip.id,
      ownerId: trip.ownerId,
      title: trip.title,
      description: trip.description,
      coverImage: trip.coverImage,
      startDate: trip.startDate,
      endDate: trip.endDate,
      createdAt: trip.createdAt,
      updatedAt: trip.updatedAt,
      participants: trip.participants,
    );
    if (validated is Err<Trip>) return Err<Trip>(validated.errorsOrEmpty);

    final t = validated.asOk().value;

    // 2. Transacción para asegurar consistencia (Header + Participantes)
    await _db.transaction(() async {
      // A. Insertar/Actualizar Trip Header
      await _db.into(_db.trips).insertOnConflictUpdate(_toCompanion(t));

      // B. Sincronizar participantes
      // Estrategia simple: El dominio manda. Si el dominio tiene participantes,
      // nos aseguramos que estén en la DB.
      // NOTA: 'addParticipant' se usa para añadir uno a uno, pero 'upsert' debe
      // garantizar que la metadata del trip sea correcta.
      // Para este ejemplo, upsert NO modifica la lista de participantes existente
      // masivamente, asumimos que se gestionan vía addParticipant.
      // Sin embargo, aseguramos que el Owner esté en la tabla de participantes.

      await _db.into(_db.tripParticipants).insert(
            db.TripParticipantsCompanion(
              tripId: d.Value(t.id),
              userId: d.Value(t.ownerId),
              role: d.Value(TripRole.admin),
            ),
            mode: d.InsertMode.insertOrIgnore,
          );
    });

    // 3. Devolver dato fresco
    return findById(t.id).then((res) => res.isOk
        ? Ok((res as Ok<Trip?>).value!)
        : Err([const UnexpectedError('Error recuperando trip guardado')]));
  }

  @override
  Future<Result<Trip?>> findById(String id) async {
    // 1. Obtener fila del Trip
    final row = await (_db.select(_db.trips)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (row == null) return const Ok(null);

    // 2. Obtener participantes (Query separada para simplificar, o JOIN)
    final participants = await _getParticipants(id);

    return Ok(_toDomain(row, participants));
  }

  @override
  Future<Result<List<Trip>>> list({TripPhase? phase}) async {
    // 1. Obtener todos los trips
    final rows = await (_db.select(_db.trips)
          ..orderBy([(t) => d.OrderingTerm.desc(t.createdAt)]))
        .get();

    // 2. Hidratar con participantes (Cuidado con N+1 queries si son muchos datos.
    // Para una app personal es aceptable. Para optimizar, hacer un JOIN global y agrupar en memoria).
    final List<Trip> results = [];

    for (final row in rows) {
      final participants = await _getParticipants(row.id);
      final trip = _toDomain(row, participants);

      if (phase != null && trip.phase != phase) continue;
      results.add(trip);
    }

    return Ok(List.unmodifiable(results));
  }

  @override
  Stream<List<Trip>> watchAll({TripPhase? phase}) {
    final q = (_db.select(_db.trips)
      ..orderBy([(t) => d.OrderingTerm.desc(t.createdAt)]));

    // Usamos asyncMap para poder hacer queries asíncronas (fetch participants) dentro del stream
    return q.watch().asyncMap((rows) async {
      final List<Trip> items = [];
      for (final row in rows) {
        final participants = await _getParticipants(row.id);
        final trip = _toDomain(row, participants);

        if (phase != null && trip.phase != phase) continue;
        items.add(trip);
      }
      return items;
    });
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    await (_db.delete(_db.trips)..where((t) => t.id.equals(id))).go();
    return const Ok(unit);
  }

  @override
  Future<Result<Unit>> addParticipant(
      String tripId, String userId, TripRole role) async {
    try {
      await _db.into(_db.tripParticipants).insertOnConflictUpdate(
            db.TripParticipantsCompanion(
              tripId: d.Value(tripId),
              userId: d.Value(userId),
              role: d.Value(role),
            ),
          );
      return const Ok(unit);
    } catch (e) {
      return Err([RepoError('Error añadiendo participante: $e')]);
    }
  }

  @override
  Future<Result<Unit>> removeParticipant(String tripId, String userId) async {
    await (_db.delete(_db.tripParticipants)
          ..where((t) => t.tripId.equals(tripId) & t.userId.equals(userId)))
        .go();
    return const Ok(unit);
  }
}
