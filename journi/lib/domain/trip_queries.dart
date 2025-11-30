import 'trip.dart';

enum TripPhase { planned, ongoing, finished, undated }

extension TripPermissions on Trip {
  bool isViewer(String userId) => participants[userId] == TripRole.viewer;

  bool isAdmin(String userId) =>
      participants[userId] == TripRole.admin || userId == ownerId;

  /// Determina si un usuario puede editar el viaje
  bool canEdit(String userId) => isAdmin(userId);
}

extension TripQueries on Trip {
  bool get hasDates => startDate != null || endDate != null;

  TripPhase get phase {
    final now = DateTime.now().toUtc();
    final s = startDate?.toUtc();
    final e = endDate?.toUtc();

    if (s == null && e == null) return TripPhase.undated;
    if (s != null && now.isBefore(s)) return TripPhase.planned;
    if (e != null && now.isAfter(e)) return TripPhase.finished;
    return TripPhase.ongoing;
  }

  /// Duración en días (ceil), o null si falta alguna de las fechas.
  int? get durationDays {
    final s = startDate?.toUtc();
    final e = endDate?.toUtc();
    if (s == null || e == null) return null;
    final diff = e.difference(s);
    final days = diff.inDays;
    return diff.inHours % 24 == 0 ? days : days + 1;
  }

  /// ¿Se solapa con otro trip? (solo si ambos tienen rango completo)
  bool overlapsWith(Trip other) {
    final aStart = startDate?.toUtc();
    final aEnd = endDate?.toUtc();
    final bStart = other.startDate?.toUtc();
    final bEnd = other.endDate?.toUtc();
    if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
      return false;
    }
    // [aStart, aEnd] solapa [bStart, bEnd] si aStart <= bEnd && bStart <= aEnd
    return !aStart.isAfter(bEnd) && !bStart.isAfter(aEnd);
  }

  /// ¿Ocurre en una fecha (UTC) concreta?
  bool occursOn(DateTime dayUtc) {
    final s = startDate?.toUtc();
    final e = endDate?.toUtc();
    if (s == null || e == null) return false;
    final d = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    final dEnd = d
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
    return !s.isAfter(dEnd) && !e.isBefore(d);
  }
}
