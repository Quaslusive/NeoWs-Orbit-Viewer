import 'dart:convert';
import 'package:http/http.dart' as http;

/// Minimal subset of fields we’ll use. Asterank returns many more.
class AsterankInfo {
  final String? name;           // usually primary designation
  final String? fullName;       // sometimes more friendly name
  final double? price;          // estimated value in USD
  final double? pv;             // geometric albedo
  final double? diameter;       // km
  final double? density;        // g/cm^3 (if present)
  final String? spec;           // spectral type / composition (if present)

  AsterankInfo({
    this.name,
    this.fullName,
    this.price,
    this.pv,
    this.diameter,
    this.density,
    this.spec,
  });

  factory AsterankInfo.fromJson(Map<String, dynamic> j) {
    // fields vary per record; be defensive
    return AsterankInfo(
      name: j['name'] as String?,
      fullName: j['full_name'] as String?,
      price: _toDouble(j['price']),
      pv: _toDouble(j['albedo']) ?? _toDouble(j['pV']), // albedo appears as albedo/pV
      diameter: _toDouble(j['diameter']),
      density: _toDouble(j['density']),
      spec: j['spec'] as String? ?? j['class'] as String?,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}


class AsterankApiService {
  static const _base = 'https://www.asterank.com/api/asterank';

  Future<AsterankInfo?> fetchByDesignation(String designation) async {
    // 1) exact name
    final exactQ = jsonEncode({'name': designation});
    final exact = await _queryOne(exactQ);
    if (exact != null) return exact;

    // 2) full_name regex (case-insensitive)
    final likeQ = jsonEncode({
      'full_name': {
        r'$regex': '.*${_escapeRegex(designation)}.*',
        r'$options': 'i',
      }
    });
    return _queryOne(likeQ);
  }

  Future<AsterankInfo?> _queryOne(String queryJson, {int limit = 1}) async {
    final url = Uri.parse('$_base?query=${Uri.encodeQueryComponent(queryJson)}&limit=$limit');
    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final parsed = jsonDecode(res.body);
    if (parsed is List && parsed.isNotEmpty) {
      return AsterankInfo.fromJson(parsed.first as Map<String, dynamic>);
    }
    return null;
  }
// pull top N Asterank rows first,
  Future<List<AsterankInfo>> fetchTop({int limit = 50}) async {
    final queryJson = jsonEncode({}); // no filter
    final url = Uri.parse('$_base?query=${Uri.encodeQueryComponent(queryJson)}&limit=$limit');
    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final parsed = jsonDecode(res.body);
    if (parsed is! List) return [];
    return parsed
        .whereType<Map<String, dynamic>>()
        .map(AsterankInfo.fromJson)
        .toList();
  }


  String _escapeRegex(String s) =>
      s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');
}
