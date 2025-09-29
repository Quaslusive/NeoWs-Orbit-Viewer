import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:neows_app/service/http_client.dart';

/// Minimal DTO for Asterank "objects" endpoint.
class AsterankObject {
  final String id;          // best-effort stable id (pdes or full_name)
  final String title;       // full_name (e.g., "1 Ceres")
  final double? H;
  final double? a;
  final double? e;
  final double? i;
  final double? diameter;   // km (if present)
  final double? albedo;     // (if present)
  final bool? neo;          // not NEOWS; Asterank has a bool "neo"
  final num? score;         // Asterank score (optional)
  final num? price;         // Asterank "value" (optional)

  AsterankObject({
    required this.id,
    required this.title,
    this.H, this.a, this.e, this.i,
    this.diameter, this.albedo,
    this.neo, this.score, this.price,
  });

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory AsterankObject.fromJson(Map<String, dynamic> j) {
    final pdes = (j['pdes'] ?? '').toString();
    final full = (j['full_name'] ?? '').toString();
    final id = pdes.isNotEmpty ? pdes : (full.isNotEmpty ? full : 'unknown');
    final title = full.isNotEmpty ? full : (pdes.isNotEmpty ? pdes : 'Unknown object');
    return AsterankObject(
      id: id,
      title: title,
      H: _d(j['H']), a: _d(j['a']), e: _d(j['e']), i: _d(j['i']),
      diameter: _d(j['diameter']),
      albedo: _d(j['albedo']),
      neo: j['neo'] is bool ? j['neo'] as bool : null,
      score: j['score'] as num?,
      price: j['price'] as num?,
    );
  }
}

class AsterankApiService {
  static const _base = 'https://www.asterank.com/api/asterank';
  final bool enableLogs;
  AsterankApiService({this.enableLogs = true});

  void _log(String m) {
    if (enableLogs)
    { /* debugPrint ok */ } }

  static List<Map<String, dynamic>> _decodeList(String s) {
    final o = jsonDecode(s);
    if (o is List) {
      return o.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> _queryRaw(
      Map<String, dynamic> query, {int limit = 50}
      ) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'query': jsonEncode(query),
      'limit': '$limit',
    });
    final res = await Httpx.client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Asterank API ${res.statusCode}');
    }
    return compute(_decodeList, res.body);
  }

  Future<List<AsterankObject>> fetchTop({int limit = 50}) async {
    final rows = await _queryRaw({'e': {r'$lt': 0.5}}, limit: limit);
    return rows.map(AsterankObject.fromJson).toList();
  }

  Future<List<AsterankObject>> search(String term, {int limit = 50}) async {
    final safe = term.trim().replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');
    final rows = await _queryRaw({
      r'$or': [
        {'full_name': {r'$regex': safe, r'$options': 'i'}},
        {'pdes': {r'$regex': safe, r'$options': 'i'}},
      ]
    }, limit: limit);
    return rows.map(AsterankObject.fromJson).toList();
  }
  Future<AsterankObject?> fetchByFullName(String fullName) async {
    final rows = await _queryRaw({'full_name': fullName}, limit: 1);
    return rows.isEmpty ? null : AsterankObject.fromJson(rows.first);
  }

  // Optional compatibility shim for old MPC-style call sites:
  Future<AsterankObject?> fetchByDesignation(String key) async {
    final k = key.trim();
    if (k.isEmpty) return null;

    // numeric → pdes match or "(123) Name"
    if (RegExp(r'^\d+$').hasMatch(k)) {
      var r = await _queryRaw({'pdes': k}, limit: 1);
      if (r.isNotEmpty) return AsterankObject.fromJson(r.first);
      r = await _queryRaw({'full_name': {r'$regex': '^\\(?$k\\)?\\s', r'$options': 'i'}}, limit: 1);
      if (r.isNotEmpty) return AsterankObject.fromJson(r.first);
    }

    // full_name exact, then regex
    final exact = await _queryRaw({'full_name': k}, limit: 1);
    if (exact.isNotEmpty) return AsterankObject.fromJson(exact.first);

    final fuzzy = await _queryRaw({'full_name': {r'$regex': k, r'$options': 'i'}}, limit: 1);
    return fuzzy.isEmpty ? null : AsterankObject.fromJson(fuzzy.first);
  }
}