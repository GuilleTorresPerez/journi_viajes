import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';

/// Repositorio de dominio para `Trip` siguiendo Clean Architecture.
abstract class TripRepository {
  /// Crea o actualiza (idempotente por `id`). Devuelve el `Trip` validado persistido.
  Future<Result<Trip>> upsert(Trip trip);

  /// Recupera un `Trip` por id (o `Ok(null)` si no existe).
  Future<Result<Trip?>> findById(String id);

  /// Lista todos los `Trip` (opcionalmente filtrados en memoria por `phase`).
  Future<Result<List<Trip>>> list(String userId, {TripPhase? phase});

  /// Observa todos los trips en tiempo real (si el backend lo soporta).
  Stream<List<Trip>> watchAll(String userId, {TripPhase? phase});

  /// Elimina por id.
  Future<Result<Unit>> deleteById(String id); // <- Unit unificado

  /// Añade o actualiza un participante con un rol específico.
  Future<Result<Unit>> addParticipant(
      String tripId, String userId, TripRole role);

  /// (Opcional) Método para eliminar participante
  Future<Result<Unit>> removeParticipant(String tripId, String userId);
}
