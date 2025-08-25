import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class OfflineMpcService {
  List<Map<String, dynamic>>? _rows; // cached in memory
  Map<String, int>? _idx;

  Future<void> loadFromAssets(String assetPath) async {
    if (_rows != null) return; // already loaded
    final raw = await rootBundle.loadString(assetPath);
    final table = const CsvToListConverter().convert(raw);

    if (table.isEmpty) {
      _rows = const [];
      _idx = const {};
      return;
    }

    // header row
    final header = table.first.map((e) => e.toString()).toList();
    _idx = { for (var i = 0; i < header.length; i++) header[i] : i };

    final r = <Map<String, dynamic>>[];
    for (int k = 1; k < table.length; k++) {
      final row = table[k];
      T? at<T>(String col) {
        final i = _idx![col];
        if (i == null || i >= row.length) return null;
        final v = row[i];
        if (v == null) return null;
        if (T == double) return (v is num ? v.toDouble() : double.tryParse(v.toString())) as T?;
        if (T == String) return v.toString() as T?;
        if (T == int) return (v is num ? v.toInt() : int.tryParse(v.toString())) as T?;
        return v as T?;
      }

      r.add({
        'readable_des': at<String>('readable_des') ?? at<String>('name') ?? '',
        'des':          at<String>('des') ?? '',
        'H':            at<double>('H'),
        'a':            at<double>('a'),
        'e':            at<double>('e'),
        'i':            at<double>('i'),
        'moid':         at<double>('moid'),
      });
    }

    _rows = r;
  }

  /// Local search with same shape as the online MPC map.
  Future<List<Map<String, dynamic>>> search({
    String? term,
    required int limit,
    double? minA, double? maxA,
    double? minE, double? maxE,
    double? minI, double? maxI,
    double? minH, double? maxH,
    double? minMoid, double? maxMoid,
  }) async {
    final rows = _rows ?? const <Map<String, dynamic>>[];
    final needle = term?.toLowerCase().trim();

    bool inRange(String k, double? lo, double? hi, Map<String, dynamic> m) {
      final v = (m[k] as num?)?.toDouble();
      if (v == null) return false;
      if (lo != null && v < lo) return false;
      if (hi != null && v > hi) return false;
      return true;
    }

    final filtered = rows.where((m) {
      if (needle != null && needle.isNotEmpty) {
        final d1 = (m['readable_des'] ?? '').toString().toLowerCase();
        final d2 = (m['des'] ?? '').toString().toLowerCase();
        if (!d1.contains(needle) && !d2.contains(needle)) return false;
      }
      if ((minA != null || maxA != null) && !inRange('a', minA, maxA, m)) return false;
      if ((minE != null || maxE != null) && !inRange('e', minE, maxE, m)) return false;
      if ((minI != null || maxI != null) && !inRange('i', minI, maxI, m)) return false;
      if ((minH != null || maxH != null) && !inRange('H', minH, maxH, m)) return false;
      if ((minMoid != null || maxMoid != null) && !inRange('moid', minMoid, maxMoid, m)) return false;
      return true;
    });

    return filtered.take(limit.clamp(10, 1000)).toList();
  }
}
