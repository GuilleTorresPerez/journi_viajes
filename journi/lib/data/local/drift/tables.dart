part of 'app_database.dart';

// Forzamos nombres de data class para evitar choques con tu dominio
@DataClassName('DbTrip')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbEntry')
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get tripId =>
      text().references(Trips, #id, onDelete: KeyAction.cascade)();

  // MUY IMPORTANTE: aplicar el converter del enum
  TextColumn get type => text().map(const EntryTypeConverter())();

  TextColumn get textContent => text().nullable()();
  TextColumn get mediaUri => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();

  // Converter para List<String>
  TextColumn get tagsJson => text().map(const StringListConverter())();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DbUser')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get lastName => text()();
  TextColumn get email => text()(); // guarda lowercase SIEMPRE
  TextColumn get passwordHash => text()(); // hex
  TextColumn get passwordSalt => text()(); // base64
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE(email)']; // email único
}

@DataClassName('DbTripParticipant')
class TripParticipants extends Table {
  TextColumn get tripId =>
      text().references(Trips, #id, onDelete: KeyAction.cascade)();

  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();

  // 2. NUEVO: Rol del participante (Admin/Viewer)
  TextColumn get role => text().map(const TripRoleConverter())();

  @override
  Set<Column> get primaryKey => {tripId, userId};
}
