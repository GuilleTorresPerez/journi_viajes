import 'package:journi/domain/entry.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/application/shared/result.dart';

/// Fachada de aplicación para Entries (paralela a TripService).
abstract class EntryService {
  Future<Result<Entry>> create(CreateEntryCommand cmd);
  Future<Result<Unit>> deleteById(String id);
  Future<Result<Entry?>> getById(String id);
  Future<Result<List<Entry>>> listByTrip(String tripId, {EntryType? type});
  Stream<List<Entry>> watchByTrip(String tripId, {EntryType? type});
}

class DefaultEntryService implements EntryService {
  final CreateEntryUseCase _createUC;
  final GetEntryByIdUseCase _getUC;
  final DeleteEntryUseCase _deleteUC;
  final ListEntriesUseCase _listUC;
  final WatchEntriesUseCase _watchUC;

  DefaultEntryService({
    required EntryRepository repo,
    CreateEntryUseCase? createUC,
    GetEntryByIdUseCase? getUC,
    DeleteEntryUseCase? deleteUC,
    ListEntriesUseCase? listUC,
    WatchEntriesUseCase? watchUC,
  })  : _createUC = createUC ?? CreateEntryUseCase(repo),
        _getUC = getUC ?? GetEntryByIdUseCase(repo),
        _deleteUC = deleteUC ?? DeleteEntryUseCase(repo),
        _listUC = listUC ?? ListEntriesUseCase(repo),
        _watchUC = watchUC ?? WatchEntriesUseCase(repo);

  @override
  Future<Result<Entry>> create(CreateEntryCommand cmd) => _createUC(cmd);

  @override
  Future<Result<Unit>> deleteById(String id) => _deleteUC(id);

  @override
  Future<Result<Entry?>> getById(String id) => _getUC(id);

  @override
  Future<Result<List<Entry>>> listByTrip(String tripId, {EntryType? type}) {
    return _listUC(tripId: tripId, type: type);
  }

  @override
  Stream<List<Entry>> watchByTrip(String tripId, {EntryType? type}) {
    return _watchUC(tripId: tripId, type: type);
  }
}

DefaultEntryService makeEntryService(EntryRepository repo) =>
    DefaultEntryService(repo: repo);
