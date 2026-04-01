import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// El enum y tipos de dominio que referencian los converters/tabl
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/trip.dart';

part 'app_database.g.dart';
part 'converters.dart';
part 'tables.dart';

@DriftDatabase(tables: [Trips, Entries, Users, TripParticipants])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openLazy());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(users);
          }
          if (from < 3) {
            await m.addColumn(users, users.passwordHash);
            await m.addColumn(users, users.passwordSalt);
          }

          // 👈 NUEVA MIGRACIÓN (v3 -> v4)
          if (from < 4) {
            // Añadimos ownerId. Nota: Si ya tienes datos, esto fallará si no es nullable
            // o tiene default. Aquí lo añadimos nullable para que la migración pase,
            // pero el código de aplicación (Repositorio) debe garantizar que se llene.
            await m.addColumn(trips, trips.ownerId);

            // Añadimos la columna role a TripParticipants
            await m.addColumn(tripParticipants, tripParticipants.role);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
  @override
  Future<void> beforeClose() async {
    await streamQueries.close(); // 👈 cierra los streams y elimina timers
  }
}

LazyDatabase _openLazy() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'journi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
