import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';       // native sqlite
import 'package:drift/web.dart';          // web
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'asteroid_table.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Asteroids])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // DAO-ish helpers
  Future<int> countAll() => (select(astroids)..limit(1)).get().then((_) async {
    final c = await customSelect('SELECT COUNT(*) AS c FROM asteroids').getSingle();
    return c.data['c'] as int;
  });

  Future<void> insertMany(List<AsteroidsCompanion> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(asteroids, rows));
  }

  // Paged query with optional search
  Future<List<Asteroid>> searchPaged({
    required int limit,
    required int offset,
    String query = '',
  }) {
    final q = select(asteroids)
      ..orderBy([(t) => OrderingTerm(expression: t.id)])
      ..limit(limit, offset: offset);

    if (query.isNotEmpty) {
      final like = '%${query.toLowerCase()}%';
      q.where((t) =>
      t.name.lower().like(like) | t.fullName.lower().like(like));
    }
    return q.get();
  }
}

// Choose backend depending on platform
LazyDatabase _openConnection() {
  if (identical(0, 0.0)) {
    // Trick to allow both imports; at runtime we check platform
  }
  return LazyDatabase(() async {
    if (_isWeb) {
      return WebDatabase('asteroids_db');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'asteroids.sqlite'));
      return NativeDatabase.createInBackground(file);
    }
  });
}

bool get _isWeb => identical(0, 0.0) == false; // cheap dart2js heuristic
