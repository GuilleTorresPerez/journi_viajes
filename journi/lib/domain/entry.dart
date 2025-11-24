import 'package:journi/application/shared/result.dart';

/// Tipos de entrada soportados.
enum EntryType { note, photo, video, location }

/// Ubicación opcional asociada a la entrada.
class EntryLocation {
  final double lat; // [-90, 90]
  final double lon; // [-180, 180]
  const EntryLocation({required this.lat, required this.lon});
}

/// Entidad de dominio: Entry (inmutable).
class Entry {
  final String id;
  final String tripId;
  final EntryType type;
  final String? text; // Para notas o pie de foto
  final String? mediaUri; // Para foto/vídeo (URI local por ahora)
  final EntryLocation? location;
  final List<String> tags; // Etiquetas/categorías opcionales
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC

  const Entry._({
    required this.id,
    required this.tripId,
    required this.type,
    required this.text,
    required this.mediaUri,
    required this.location,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Fábrica validada.
  static Result<Entry> create({
    required String id,
    required String tripId,
    required EntryType type,
    String? text,
    String? mediaUri,
    EntryLocation? location,
    List<String> tags = const [],
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final errors = <ValidationError>[];

    if (id.trim().isEmpty) {
      errors.add(ValidationError('id no puede ser vacío'));
    }
    if (tripId.trim().isEmpty) {
      errors.add(ValidationError('tripId no puede ser vacío'));
    }
    if (updatedAt.isBefore(createdAt)) {
      errors.add(ValidationError('updatedAt no puede ser < createdAt'));
    }

    // Reglas según tipo

    switch (type) {
      case EntryType.note:
        if (text == null || text.trim().isEmpty) {
          errors.add(ValidationError('Una nota debe tener texto'));
        }
        break;

      case EntryType.photo:
      case EntryType.video:
        if (mediaUri == null || mediaUri.trim().isEmpty) {
          errors.add(ValidationError('mediaUri requerido para foto/vídeo'));
        }
        break;

      case EntryType.location:
        if (text == null || text.trim().isEmpty) {
          errors.add(
            ValidationError('Una ubicación debe tener texto o coordenadas'),
          );
        }
        break;
    }
    // Validación de ubicación
    if (location != null) {
      final lat = location.lat;
      final lon = location.lon;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        errors.add(ValidationError('Coordenadas fuera de rango'));
      }
    }

    // Normaliza etiquetas (trim + dedup + sin vacíos)
    final normTags = {for (final t in tags) t.trim()}
      ..removeWhere((t) => t.isEmpty);

    if (errors.isNotEmpty) return Err<Entry>(errors);

    return Ok(
      Entry._(
        id: id.trim(),
        tripId: tripId.trim(),
        type: type,
        text: text?.trim(),
        mediaUri: mediaUri?.trim(),
        location: location,
        tags: List.unmodifiable(normTags),
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
      ),
    );
  }

  /// Copia con updatedAt revalidado (para futuras mutaciones controladas si las necesitáis).
  Result<Entry> copyValidated({
    String? text,
    String? mediaUri,
    EntryLocation? location,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return Entry.create(
      id: id,
      tripId: tripId,
      type: type,
      text: text ?? this.text,
      mediaUri: mediaUri ?? this.mediaUri,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }
}
