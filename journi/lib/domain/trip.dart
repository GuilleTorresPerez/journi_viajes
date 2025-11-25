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

class Trip {
  static const int titleMax = 100;
  static const int descriptionMax = 2000;

  final String id;
  final String title;
  final String? description;
  final String? coverImage;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> participantIds;

  const Trip({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.participantIds = const [],
  });

  static Result<Trip> create({
    required String id,
    required String title,
    String? description,
    String? coverImage,
    DateTime? startDate,
    DateTime? endDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<String> participantIds = const [],
  }) {
    final errs = <ValidationError>[];

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

    return Ok<Trip>(
      Trip(
        id: id,
        title: t,
        description: description,
        coverImage: coverImage,
        startDate: sUtc,
        endDate: eUtc,
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
        participantIds: participantIds,
      ),
    );
  }
}
