import 'trip.dart';

enum TripPhase { planned, ongoing, finished, undated }

// ❌ BORRADA la extensión TripPermissions de aquí.
// Ya existe en trip_extensions.dart

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

  int? get durationDays {
    final s = startDate?.toUtc();
    final e = endDate?.toUtc();
    if (s == null || e == null) return null;
    final diff = e.difference(s);
    final days = diff.inDays;
    return diff.inHours % 24 == 0 ? days : days + 1;
  }

  bool overlapsWith(Trip other) {
    final aStart = startDate?.toUtc();
    final aEnd = endDate?.toUtc();
    final bStart = other.startDate?.toUtc();
    final bEnd = other.endDate?.toUtc();
    if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
      return false;
    }
    return !aStart.isAfter(bEnd) && !bStart.isAfter(aEnd);
  }

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
