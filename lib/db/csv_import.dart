import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show compute;
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'app_db.dart';

List<List<dynamic>> _parseCsv(String raw) =>
    const CsvToListConverter(eol: '\n').convert(raw);

Future<void> importCsvIfEmpty(AppDb db, {String assetPath = 'lib/assets/astroidReadTest.csv'}) async {
  final count = await db.customSelect('SELECT COUNT(*) AS c FROM asteroids').getSingle();
  if ((count.data['c'] as int) > 0) return;

  final raw = await rootBundle.loadString(assetPath);
  final rows = await compute(_parseCsv, raw);

  // Skip header row; insert in batches for speed
  const batchSize = 1000;
  List<AsteroidsCompanion> buffer = [];
  for (int i = 1; i < rows.length; i++) {
    final r = rows[i];

    buffer.add(AsteroidsCompanion.insert(
      id: (r[0] ?? '').toString(),
      name: Value((r[4] ?? '').toString()),
      fullName: Value((r[2] ?? '').toString()),
      diameter: Value(double.tryParse(r[15].toString()) ?? 0.0),
      albedo: Value(double.tryParse(r[17].toString()) ?? 0.0),
      neo: Value((r[6] ?? '').toString()),
      pha: Value((r[7] ?? '').toString()),
      rotationPeriod: Value(double.tryParse(r[18].toString()) ?? 0.0),
      classType: Value((r[60] ?? '').toString()),
      orbitId: Value(int.tryParse(r[27].toString()) ?? 0),
      moid: Value(double.tryParse(r[45].toString()) ?? 0.0),
      a: Value(double.tryParse(r[33].toString()) ?? 0.0),
      e: Value(double.tryParse(r[32].toString()) ?? 0.0),
    ));

    if (buffer.length >= batchSize) {
      await db.insertMany(buffer);
      buffer.clear();
    }
  }
  if (buffer.isNotEmpty) {
    await db.insertMany(buffer);
  }
}
