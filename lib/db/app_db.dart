/*
import 'dart:io' show File;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/web.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'asteroid_table.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Asteroids])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  if (kIsWeb) {
    // No sql.js / wasm file needed; this writes to IndexedDB
    return LazyDatabase(() async => WebDatabase('asteroids_db'));
  } else {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'asteroids.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
*/
