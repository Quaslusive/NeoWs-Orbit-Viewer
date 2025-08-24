// lib/service/asterank_mpc_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:http/http.dart' as http;

/// Minimal MPC model (you already have an Asteroid model; this is just a DTO)
class MpcRow {
  final String? des;            // numeric/packed designation
  final String? readableDes;    // human-readable designation
  final double? H;              // absolute magnitude
  final double? a;              // semi-major axis (au)
  final double? e;              // eccentricity
  final double? i;              // inclination (deg)
  final double? moid;           // minimum orbit intersection distance (au)

  MpcRow({
    this.des,
    this.readableDes,
    this.H,
    this.a,
    this.e,
    this.i,
    this.moid,
  });

  factory MpcRow.fromJson(Map<String, dynamic> j) => MpcRow(
    des: j['des'] as String?,
    readableDes: j['readable_des'] as String?,
    H: _toDouble(j['H']),
    a: _toDouble(j['a']),
    e: _toDouble(j['e']),
    i: _toDouble(j['i']),
    moid: _toDouble(j['moid']),
  );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class AsterankApiService {
  static const _httpsBase = 'https://www.asterank.com/api/mpc';
  static const _httpBase  = 'http://asterank.com/api/mpc';

  /// Toggle to print dev logs (only prints in debug/profile; not in release).
  final bool enableLogs;

  AsterankApiService({this.enableLogs = true});

  void _log(String msg) {
    if (enableLogs && kDebugMode) {
      // ignore: avoid_print
      print('[MPC] $msg');
    }
  }

  Future<http.Response> _getWithFallback(Uri httpsUrl, Uri httpUrl) async {
    final sw = Stopwatch()..start();
    _log('GET ${httpsUrl.toString()}');
    try {
      final r = await http.get(httpsUrl);
      _log('HTTPS status=${r.statusCode} (${sw.elapsedMilliseconds} ms)');
      if (r.statusCode == 200) return r;
    } catch (e) {
      _log('HTTPS error: $e');
    }

    _log('FALLBACK -> GET ${httpUrl.toString()}');
    final r2 = await http.get(httpUrl);
    _log('HTTP status=${r2.statusCode} (${sw.elapsedMilliseconds} ms total)');
    return r2;
  }

  Future<List<Map<String, dynamic>>> _queryMany(
      Map<String, dynamic> query, {
        int limit = 50,
      }) async {
    final q = jsonEncode(query);
    final https = Uri.parse(_httpsBase)
        .replace(queryParameters: {'query': q, 'limit': '$limit'});
    final httpu = Uri.parse(_httpBase)
        .replace(queryParameters: {'query': q, 'limit': '$limit'});

    _log('query=${q} limit=$limit');
    final res = await _getWithFallback(https, httpu);

    if (res.statusCode != 200) {
      _log('ERROR body: ${res.body}');
      throw Exception('MPC API ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    if (data is! List) {
      _log('Non-list payload received');
      return const [];
    }
    _log('received ${data.length} rows');
    return data.whereType<Map<String, dynamic>>().toList();
  }

  /// Search by partial match across readable_des and des.
  Future<List<MpcRow>> searchMany(String term, {int limit = 50}) async {
    final safe = _escapeRegex(term.trim());
    final rows = await _queryMany({
      r'$or': [
        {'readable_des': {r'$regex': safe, r'$options': 'i'}},
        {'des': {r'$regex': safe, r'$options': 'i'}},
      ]
    }, limit: limit);
    return rows.map(MpcRow.fromJson).toList();
  }

  /// Seed list for initial view. You can tweak filters if desired.
  Future<List<MpcRow>> fetchTop({int limit = 50}) async {
    // Example filter: modest eccentricity to avoid super oddballs
    final rows = await _queryMany({'e': {r'$lt': 0.5}}, limit: limit);
    return rows.map(MpcRow.fromJson).toList();
  }

  Future<MpcRow?> fetchByDesignation(String designation) async {
    final rows = await _queryMany({
      r'$or': [
        {'readable_des': designation}, // exact
        {'des': designation},          // exact
      ]
    }, limit: 1);

    if (rows.isEmpty) return null;
    return MpcRow.fromJson(rows.first);
  }

  String _escapeRegex(String s) =>
      s.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');
}
