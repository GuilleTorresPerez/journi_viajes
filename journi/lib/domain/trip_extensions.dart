import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/trip.dart'; // Asegúrate de importar Trip

extension TripMutators on Trip {
  /// Cambia título y revalida.
  Result<Trip> withTitle(String newTitle) => Trip.create(
        id: id,
        ownerId: ownerId, // ✅ Requerido
        title: newTitle,
        description: description,
        coverImage: coverImage,
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        participants: participants, // ✅ Importante para no perder participantes
      );

  /// Cambia descripción y revalida.
  Result<Trip> withDescription(String? newDescription) => Trip.create(
        id: id,
        ownerId: ownerId, // ✅ Requerido
        title: title,
        description: newDescription,
        coverImage: coverImage,
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        participants: participants, // ✅ Importante
      );

  /// Cambia fechas (normaliza a UTC y valida rango).
  Result<Trip> withDates({DateTime? start, DateTime? end}) => Trip.create(
        id: id,
        ownerId: ownerId, // 👈 FALTABA AQUÍ
        title: title,
        description: description,
        coverImage: coverImage,
        startDate: start ?? startDate,
        endDate: end ?? endDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        participants: participants, // 👈 FALTABA AQUÍ (vital para integridad)
      );

  /// Versión genérica tipo copyWith pero validada
  Result<Trip> copyValidated({
    String? title,
    String? description,
    String? coverImage,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
  }) =>
      Trip.create(
        id: id,
        ownerId: ownerId, // 👈 FALTABA AQUÍ
        title: title ?? this.title,
        description: description ?? this.description,
        coverImage: coverImage ?? this.coverImage,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt,
        updatedAt: (updatedAt ?? this.updatedAt),
        participants: participants, // 👈 FALTABA AQUÍ
      );
}
