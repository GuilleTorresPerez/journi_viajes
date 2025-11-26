import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';

class CreateEntryCommand {
  final String id;
  final String tripId;
  final EntryType type;
  final String? text;
  final String? mediaUri;
  final EntryLocation? location;
  final List<String> tags;

  const CreateEntryCommand({
    required this.id,
    required this.tripId,
    required this.type,
    this.text,
    this.mediaUri,
    this.location,
    this.tags = const [],
  });
}

class UpdateEntryCommand {
  final String id;
  final String? text;
  final String? mediaUri;
  final EntryLocation? location;
  final List<String>? tags;
  final DateTime?
      updatedAt; // Opcional, si se quiere forzar una fecha específica

  const UpdateEntryCommand({
    required this.id,
    this.text,
    this.mediaUri,
    this.location,
    this.tags,
    this.updatedAt,
  });
}

class CreateEntryUseCase {
  final EntryRepository repo;
  CreateEntryUseCase(this.repo);

  Future<Result<Entry>> call(CreateEntryCommand cmd) async {
    final now = DateTime.now().toUtc();
    final res = Entry.create(
      id: cmd.id,
      tripId: cmd.tripId,
      type: cmd.type,
      text: cmd.text,
      mediaUri: cmd.mediaUri,
      location: cmd.location,
      tags: cmd.tags,
      createdAt: now,
      updatedAt: now,
    );
    if (res is Err<Entry>) return res;
    return repo.upsert((res as Ok<Entry>).value);
  }
}

class GetEntryByIdUseCase {
  final EntryRepository repo;
  GetEntryByIdUseCase(this.repo);
  Future<Result<Entry?>> call(String id) => repo.findById(id);
}

class DeleteEntryUseCase {
  final EntryRepository repo;
  DeleteEntryUseCase(this.repo);
  Future<Result<Unit>> call(String id) => repo.deleteById(id);
}

class ListEntriesUseCase {
  final EntryRepository repo;
  ListEntriesUseCase(this.repo);
  Future<Result<List<Entry>>> call({required String tripId, EntryType? type}) {
    return repo.list(tripId: tripId, type: type);
  }
}

class WatchEntriesUseCase {
  final EntryRepository repo;
  WatchEntriesUseCase(this.repo);
  Stream<List<Entry>> call({required String tripId, EntryType? type}) {
    return repo.watchAll(tripId: tripId, type: type);
  }
}

/// Caso de uso: Actualizar Entrada
class UpdateEntryUseCase {
  final EntryRepository repo;

  UpdateEntryUseCase(this.repo);

  Future<Result<Entry>> call(UpdateEntryCommand cmd) async {
    // 1. Recuperar la entrada existente
    final fetchResult = await repo.findById(cmd.id);

    // Manejo de errores en la recuperación
    if (fetchResult is Err<Entry?>) {
      return Err(fetchResult.asErr().errors);
    }

    final currentEntry = fetchResult.asOk().value;

    // 2. Validar existencia
    if (currentEntry == null) {
      return Err(
          [RepoError('Entry con id ${cmd.id} no encontrada para actualizar')]);
    }

    // 3. Aplicar cambios sobre la entidad inmutable usando lógica de dominio
    // copyValidated se encarga de re-validar las reglas de negocio (e.g. coordenadas)
    final updateResult = currentEntry.copyValidated(
      text: cmd.text,
      mediaUri: cmd.mediaUri,
      location: cmd.location,
      tags: cmd.tags,
      updatedAt: cmd.updatedAt ?? DateTime.now().toUtc(),
    );

    // Si la validación de dominio falla, retornamos los errores
    if (updateResult is Err<Entry>) {
      return updateResult;
    }

    // 4. Persistir cambios (Upsert maneja la actualización al existir el ID)
    return repo.upsert(updateResult.asOk().value);
  }
}
