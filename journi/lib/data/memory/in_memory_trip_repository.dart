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

  /// Helper interno para filtrar por fase y ordenar.
  List<Trip> _filtered(TripPhase? phase) {
    var items = _store.values.toList();
    if (phase != null) {
      items = items.where((t) => t.phase == phase).toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Helper de seguridad: ¿El usuario puede ver este viaje?
  bool _hasAccess(Trip t, String userId) {
    return t.ownerId == userId || t.participants.containsKey(userId);
  }

  @override
  Future<Result<Trip>> upsert(Trip trip) async {
    final res = Trip.create(
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

    if (res is Err<Trip>) return res;
    final ok = res as Ok<Trip>;
    _store[ok.value.id] = ok.value;
    _emit();
    return ok;
  }

  @override
  Future<Result<Trip?>> findById(String id) async => Ok(_store[id]);

  // 👇 CORREGIDO: Aceptamos userId y filtramos
  @override
  Future<Result<List<Trip>>> list(String userId, {TripPhase? phase}) async {
    // 1. Obtenemos lista base (filtrada por fase y ordenada)
    final baseList = _filtered(phase);

    // 2. Filtramos por seguridad (Solo mis viajes o compartidos conmigo)
    final userTrips = baseList.where((t) => _hasAccess(t, userId)).toList();

    return Ok(userTrips);
  }

  // 👇 CORREGIDO: Aceptamos userId y filtramos
  @override
  Stream<List<Trip>> watchAll(String userId, {TripPhase? phase}) {
    final base = _controller.stream;

    return base.map((items) {
      // 1. Filtrar por fase si es necesario
      var filtered =
          phase != null ? items.where((t) => t.phase == phase) : items;

      // 2. Filtrar por seguridad (userId)
      // Convertimos a lista para materializar el iterable
      return filtered.where((t) => _hasAccess(t, userId)).toList();
    });
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    _store.remove(id);
    _emit();
    return const Ok(unit);
  }

  @override
  Future<Result<Unit>> addParticipant(
      String tripId, String userId, TripRole role) async {
    final currentTrip = _store[tripId];

    if (currentTrip == null) {
      return Err([ValidationError('Trip con id $tripId no encontrado')]);
    }

    final newParticipants =
        Map<String, TripRole>.from(currentTrip.participants);

    newParticipants[userId] = role;

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

    if (updatedRes is Err<Trip>) {
      return Err(updatedRes.errors);
    }

    _store[tripId] = (updatedRes as Ok<Trip>).value;
    _emit();

    return const Ok(unit);
  }

  @override
  Future<Result<Unit>> removeParticipant(String tripId, String userId) async {
    final currentTrip = _store[tripId];
    if (currentTrip == null) {
      return Err([ValidationError('Trip con id $tripId no encontrado')]);
    }

    if (currentTrip.ownerId == userId) {
      return Err(
          [ValidationError('No se puede eliminar al propietario del viaje')]);
    }

    if (!currentTrip.participants.containsKey(userId)) {
      return const Ok(unit);
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
