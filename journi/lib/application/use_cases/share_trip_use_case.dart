import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';
import 'package:journi/domain/trip.dart'; // Para acceder a TripRole
import 'package:journi/domain/user.dart';

class ShareTripUseCase {
  final TripRepository tripRepo;
  final UserRepository userRepo;

  ShareTripUseCase(this.tripRepo, this.userRepo);

  // Añadimos argumento opcional role, por defecto 'viewer'
  Future<Result<Unit>> call(String tripId, String email,
      {TripRole role = TripRole.viewer}) async {
    if (email.trim().isEmpty) {
      return const Err([ValidationError('El email no puede estar vacío')]);
    }

    final userRes = await userRepo.findByEmail(email);
    if (userRes is Err<User?>) return Err(userRes.errorsOrEmpty);

    final user = (userRes as Ok<User?>).value;
    if (user == null) {
      return const Err([ValidationError('Usuario no encontrado')]);
    }

    // Delegamos al repo pasando el rol específico
    return tripRepo.addParticipant(tripId, user.id, role);
  }
}
