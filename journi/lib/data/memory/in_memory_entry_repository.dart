import 'dart:async';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/application/shared/result.dart';

/// Implementación en memoria, ordenando por createdAt DESC.
class InMemoryEntryRepository implements EntryRepository {
  final Map<String, Entry> _db = {};
  final StreamController<void> _changes = StreamController.broadcast();

  InMemoryEntryRepository();

  List<Entry> _snapshot({String? tripId, EntryType? type}) {
    final items = _db.values.where((e) {
      final okTrip = tripId == null || e.tripId == tripId;
      final okType = type == null || e.type == type;
      return okTrip && okType;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  Future<Result<Entry>> upsert(Entry entry) async {
    _db[entry.id] = entry;
    _emit();
    return Ok(entry);
  }

  @override
  Future<Result<Unit>> deleteById(String id) async {
    _db.remove(id);
    _emit();
    return Ok(unit);
  }

  @override
  Future<Result<Entry?>> findById(String id) async {
    return Ok(_db[id]);
  }

  @override
  Future<Result<List<Entry>>> list({String? tripId, EntryType? type}) async {
    return Ok(_snapshot(tripId: tripId, type: type));
  }

  // lib/data/memory/in_memory_entry_repository.dart
  @override
  Stream<List<Entry>> watchAll({String? tripId, EntryType? type}) {
    // Stream que expondremos a los clientes
    final out = StreamController<List<Entry>>.broadcast();

    StreamSubscription<void>? sub;

    void emitSnapshot() {
      out.add(_snapshot(tripId: tripId, type: type));
    }

    out.onListen = () {
      // 1) Empuja el snapshot inicial ANTES de escuchar cambios
      emitSnapshot();

      // 2) Ahora sí, suscríbete a _changes y emite snapshot en cada cambio
      sub = _changes.stream.listen((_) => emitSnapshot());
    };

    out.onCancel = () async {
      await sub?.cancel();
      sub = null;
    };

    return out.stream;
  }

  void dispose() {
    _changes.close();
  }
}
