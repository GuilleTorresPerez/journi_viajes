import 'package:journi/application/shared/result.dart';
export 'package:journi/application/shared/result.dart'
    show
        Result,
        Ok,
        Err,
        AppError,
        ValidationError,
        RepoError,
        UnexpectedError,
        Unit;

enum TripRole {
  admin, // Puede editar, borrar, añadir participantes
  viewer, // Solo lectura
}

class Trip {
  static const int titleMax = 100;
  static const int descriptionMax = 2000;

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? coverImage;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, TripRole> participants;

  const Trip({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.coverImage,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const {},
  });

  static Result<Trip> create(
      {required String id,
      required String ownerId,
      required String title,
      String? description,
      String? coverImage,
      DateTime? startDate,
      DateTime? endDate,
      required DateTime createdAt,
      required DateTime updatedAt,
      Map<String, TripRole>? participants}) {
    final errs = <ValidationError>[];

    if (ownerId.trim().isEmpty) {
      errs.add(const ValidationError(
          'El trip debe pertenecer a un usuario (ownerId vacío)'));
    }

    final t = title.trim();
    if (t.isEmpty) {
      errs.add(ValidationError('title no puede estar vacío'));
    }
    if (t.length > titleMax) {
      errs.add(ValidationError('title supera $titleMax caracteres'));
    }
    if (description != null && description.length > descriptionMax) {
      errs.add(
        ValidationError('description supera $descriptionMax caracteres'),
      );
    }

    // Normaliza antes de comparar (evita errores por zonas horarias)
    final sUtc = startDate?.toUtc();
    final eUtc = endDate?.toUtc();
    if (sUtc != null && eUtc != null && sUtc.isAfter(eUtc)) {
      errs.add(ValidationError('startDate debe ser <= endDate'));
    }

    if (errs.isNotEmpty) {
      return Err<Trip>(errs);
    }

    final finalParticipants = Map<String, TripRole>.from(participants ?? {});
    finalParticipants[ownerId] = TripRole.admin;

    return Ok<Trip>(
      Trip(
        id: id,
        ownerId: ownerId,
        title: t,
        description: description,
        coverImage: coverImage,
        startDate: startDate?.toUtc(),
        endDate: eUtc,
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
        participants: finalParticipants,
      ),
    );
  }
}
