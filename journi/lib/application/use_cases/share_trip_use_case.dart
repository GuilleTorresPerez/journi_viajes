import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';

class ShareTripUseCase {
  final TripRepository _tripRepository;
  final UserRepository _userRepository;

  ShareTripUseCase(this._tripRepository, this._userRepository);

  Future<Result<Unit>> call(String tripId, String email) async {
    // 1. Validar formato de email (Fail fast)
    final emailClean = email.trim().toLowerCase();
    if (emailClean.isEmpty) {
      return Err([const ValidationError('El email no puede estar vacío')]);
    }

    // 2. Comprobar si el usuario existe
    final userResult = await _userRepository.findByEmail(emailClean);

    // CORRECCIÓN AQUÍ: Usamos .asErr().errors
    if (userResult.isErr) {
      return Err(userResult.asErr().errors);
    }

    final user = userResult.asOk().value;

    if (user == null) {
      return Err(
          [ValidationError('Usuario con email $emailClean no encontrado')]);
    }

    // 3. Persistir la relación
    return _tripRepository.addParticipant(tripId, user.id);
  }
}
