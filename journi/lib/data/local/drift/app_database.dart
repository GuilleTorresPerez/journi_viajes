import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// El enum y tipos de dominio que referencian los converters/tabl
import 'package:journi/domain/entry.dart';

part 'app_database.g.dart';
part 'converters.dart';
part 'tables.dart';

@DriftDatabase(tables: [Trips, Entries, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openLazy());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3; // ⬆️ bump a v3

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(users);
      }
      if (from < 3) {
        // añadimos columnas de password
        await m.addColumn(users, users.passwordHash);
        await m.addColumn(users, users.passwordSalt);
      }
    },
  );
}

LazyDatabase _openLazy() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'journi.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
