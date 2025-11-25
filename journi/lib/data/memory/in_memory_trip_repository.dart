import 'dart:async';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart';
import 'package:journi/domain/trip_queries.dart';
import 'package:journi/domain/ports/trip_repository.dart';

/// Repositorio en memoria (mínimo viable) para desarrollo sin BD.
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
    final res = Trip.create(
      id: trip.id,
      title: trip.title,
      description: trip.description,
      coverImage: trip.coverImage,
      startDate: trip.startDate,
      endDate: trip.endDate,
      createdAt: trip.createdAt,
      updatedAt: trip.updatedAt,
      // IMPORTANTE: Aseguramos pasar los participantes al recrear/validar
      participantIds: trip.participantIds,
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
    // ❗️Sin snapshot inicial: solo reemitimos lo que publique _controller.
    final base = _controller.stream; // broadcast; múltiples listeners
    if (phase == null) return base;
    // Filtramos manteniendo el orden por createdAt (ya viene ordenado).
    return base.map((items) => items.where((t) => t.phase == phase).toList());
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    _store.remove(id);
    _emit();
    return const Ok(unit);
  }

  // 👇 IMPLEMENTACIÓN AÑADIDA PARA CORREGIR EL ERROR
  @override
  Future<Result<Unit>> addParticipant(String tripId, String userId) async {
    final currentTrip = _store[tripId];

    if (currentTrip == null) {
      return Err([ValidationError('Trip con id $tripId no encontrado')]);
    }

    // Evitamos duplicados si el usuario ya está en la lista
    if (currentTrip.participantIds.contains(userId)) {
      return const Ok(unit);
    }

    // Creamos la nueva lista de participantes
    final newParticipants = List<String>.from(currentTrip.participantIds)
      ..add(userId);

    // Reconstruimos el Trip (Inmutabilidad) actualizando la fecha
    final updatedRes = Trip.create(
      id: currentTrip.id,
      title: currentTrip.title,
      description: currentTrip.description,
      coverImage: currentTrip.coverImage,
      startDate: currentTrip.startDate,
      endDate: currentTrip.endDate,
      createdAt: currentTrip.createdAt,
      updatedAt: DateTime.now().toUtc(), // Actualizamos timestamp
      participantIds: newParticipants,
    );

    if (updatedRes is Err<Trip>) {
      return Err(updatedRes.errors);
    }

    // Guardamos y notificamos
    _store[tripId] = (updatedRes as Ok<Trip>).value;
    _emit();

    return const Ok(unit);
  }

  Future<void> dispose() async => _controller.close(); // emite done a listeners
}
