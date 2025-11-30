import 'dart:async';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/ports/trip_repository.dart';

/// Repositorio en memoria actualizado para soportar Roles y OwnerId.
class InMemoryTripRepository implements TripRepository {
  final Map<String, Trip> _store;
  final _controller = StreamController<List<Trip>>.broadcast();

  InMemoryTripRepository({Iterable<Trip>? seed})
      : _store = {for (final t in (seed ?? const <Trip>[])) t.id: t} {
    _emit();
  }

  void _emit() {
    final items = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(items);
  }

  List<Trip> _filtered(TripPhase? phase) {
    var items = _store.values.toList();
    if (phase != null) {
      items = items.where((t) => t.phase == phase).toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<Result<Trip>> upsert(Trip trip) async {
    // 1. Corrección: Añadimos ownerId y usamos el mapa 'participants'
    final res = Trip.create(
      id: trip.id,
      ownerId: trip.ownerId, // 👈 Obligatorio ahora
      title: trip.title,
      description: trip.description,
      coverImage: trip.coverImage,
      startDate: trip.startDate,
      endDate: trip.endDate,
      createdAt: trip.createdAt,
      updatedAt: trip.updatedAt,
      participants: trip.participants, // 👈 Pasamos el mapa, no una lista
    );

    if (res is Err<Trip>) return res;
    final ok = res as Ok<Trip>;
    _store[ok.value.id] = ok.value;
    _emit();
    return ok;
  }

  @override
  Future<Result<Trip?>> findById(String id) async => Ok(_store[id]);

  @override
  Future<Result<List<Trip>>> list({TripPhase? phase}) async =>
      Ok(_filtered(phase));

  @override
  Stream<List<Trip>> watchAll({TripPhase? phase}) {
    final base = _controller.stream;
    if (phase == null) return base;
    return base.map((items) => items.where((t) => t.phase == phase).toList());
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    _store.remove(id);
    _emit();
    return const Ok(unit);
  }

  // 👇 Corrección: Firma actualizada con 'TripRole'
  @override
  Future<Result<Unit>> addParticipant(
      String tripId, String userId, TripRole role) async {
    final currentTrip = _store[tripId];

    if (currentTrip == null) {
      return Err([ValidationError('Trip con id $tripId no encontrado')]);
    }

    // 2. Lógica actualizada para Map<String, TripRole>
    // Creamos una copia mutable del mapa actual
    final newParticipants =
        Map<String, TripRole>.from(currentTrip.participants);

    // Insertamos o actualizamos el rol del usuario
    newParticipants[userId] = role;

    // Reconstruimos el Trip
    final updatedRes = Trip.create(
      id: currentTrip.id,
      ownerId: currentTrip.ownerId, // 👈 No olvidar mantener el owner
      title: currentTrip.title,
      description: currentTrip.description,
      coverImage: currentTrip.coverImage,
      startDate: currentTrip.startDate,
      endDate: currentTrip.endDate,
      createdAt: currentTrip.createdAt,
      updatedAt: DateTime.now().toUtc(),
      participants: newParticipants, // 👈 Pasamos el nuevo mapa
    );

    if (updatedRes is Err<Trip>) {
      return Err(updatedRes.errors);
    }

    _store[tripId] = (updatedRes as Ok<Trip>).value;
    _emit();

    return const Ok(unit);
  }

  // 👇 Corrección: Implementación del método faltante
  @override
  Future<Result<Unit>> removeParticipant(String tripId, String userId) async {
    final currentTrip = _store[tripId];
    if (currentTrip == null) {
      return Err([ValidationError('Trip con id $tripId no encontrado')]);
    }

    // Si es el dueño, no deberíamos permitir borrarlo (regla de negocio opcional, pero recomendada)
    if (currentTrip.ownerId == userId) {
      return Err(
          [ValidationError('No se puede eliminar al propietario del viaje')]);
    }

    if (!currentTrip.participants.containsKey(userId)) {
      return const Ok(unit); // No estaba, operación idempotente
    }

    final newParticipants =
        Map<String, TripRole>.from(currentTrip.participants);
    newParticipants.remove(userId);

    final updatedRes = Trip.create(
      id: currentTrip.id,
      ownerId: currentTrip.ownerId,
      title: currentTrip.title,
      description: currentTrip.description,
      coverImage: currentTrip.coverImage,
      startDate: currentTrip.startDate,
      endDate: currentTrip.endDate,
      createdAt: currentTrip.createdAt,
      updatedAt: DateTime.now().toUtc(),
      participants: newParticipants,
    );

    if (updatedRes is Err<Trip>) return Err(updatedRes.errors);

    _store[tripId] = (updatedRes as Ok<Trip>).value;
    _emit();

    return const Ok(unit);
  }

  Future<void> dispose() async => _controller.close();
}
