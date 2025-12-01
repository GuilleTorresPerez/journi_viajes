part of 'app_database.dart';

class EntryTypeConverter extends TypeConverter<EntryType, String> {
  const EntryTypeConverter();
  @override
  EntryType fromSql(String fromDb) =>
      EntryType.values.firstWhere((e) => e.name == fromDb);
  @override
  String toSql(EntryType value) => value.name;
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) =>
      (JsonDecoder().convert(fromDb) as List).map((e) => e.toString()).toList();

  @override
  String toSql(List<String> value) => const JsonEncoder().convert(value);
}

class TripRoleConverter extends TypeConverter<TripRole, String> {
  const TripRoleConverter();

  @override
  TripRole fromSql(String fromDb) {
    try {
      return TripRole.values.firstWhere((e) => e.name == fromDb);
    } catch (_) {
      // Fallback seguro: si el rol no existe o es antiguo, lo tratamos como viewer
      return TripRole.viewer;
    }
  }

  @override
  String toSql(TripRole value) => value.name;
}
