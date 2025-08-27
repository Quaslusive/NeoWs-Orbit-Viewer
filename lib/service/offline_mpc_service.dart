/*
// lib/service/offline_mpc_service.dart
import 'dart:io';
import 'dart:convert';

class OfflineMpcService {
  List<Map<String, dynamic>> _rows = [];

  Future<void> loadFromPath(String path) async {
    final raw = await File(path).readAsString();
    _rows = _parseCsv(raw);
  }

  Future<void> loadFromAssets(String assetPath) async {
    // existing assets loader (rootBundle.loadString) -> _parseCsv(...)
  }

  // very simple CSV parser (header: readable_des,des,H,a,e,i,moid)
  List<Map<String, dynamic>> _parseCsv(String raw) {
    final lines = const LineSplitter().convert(raw);
    if (lines.isEmpty) return [];
    final headers = lines.first.split(',');
    return [
      for (int i = 1; i < lines.length; i++)
        _row(headers, lines[i]),
    ];
  }

  Map<String, dynamic> _row(List<String> headers, String line) {
    final cols = _splitCsv(line);
    final m = <String, dynamic>{};
    for (int i = 0; i < headers.length && i < cols.length; i++) {
      final key = headers[i].trim();
      final v = cols[i];
      switch (key) {
        case 'H':
        case 'a':
        case 'e':
        case 'i':
        case 'moid':
          m[key] = double.tryParse(v);
          break;
        default:
          m[key] = v;
      }
    }
    return m;
  }

  // naive CSV split (handles simple quoted values)
  List<String> _splitCsv(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    bool quoted = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        quoted = !quoted;
      } else if (c == ',' && !quoted) {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    out.add(buf.toString());
    return out.map((s) => s.trim()).toList();
  }

  // basic search by term (readable_des/des), with limit
  Future<List<Map<String, dynamic>>> search({
    required String term,
    int limit = 50,
  }) async {
    final q = term.trim().toLowerCase();
    if (q.isEmpty) {
      return _rows.take(limit).toList();
    }
    final res = _rows.where((r) {
      final rd = (r['readable_des'] ?? '').toString().toLowerCase();
      final des = (r['des'] ?? '').toString().toLowerCase();
      return rd.contains(q) || des.contains(q);
    }).take(limit).toList();
    return res;
  }
}
*/
