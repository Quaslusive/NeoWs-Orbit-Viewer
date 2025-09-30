import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:neows_app/service/http_client.dart';

class NeoWsService {
  final String apiKey;


  NeoWsService({required this.apiKey});

  int _clampLimit(int v) => v.clamp(10, 1000);

  // --- isolate helpers
  static Map<String, dynamic> _decodeMap(String s) =>
      (jsonDecode(s) as Map<String, dynamic>);
  static Map<String, dynamic> _decodeMapNoThrow(String s) {
    final o = jsonDecode(s);
    return o is Map<String, dynamic> ? o : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await Httpx.client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('NeoWs ${res.statusCode}: ${res.body}');
    }
    return compute(_decodeMap, res.body);
  }

  double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static const _base = 'https://api.nasa.gov/neo/rest/v1';

  Future<Map<String, dynamic>> _get(String url, [Map<String, String>? q]) async {
    final uri = Uri.parse(url).replace(queryParameters: {
      ...(q ?? {}), 'api_key': apiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('NeoWs error ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String _ymd(DateTime d) => d.toIso8601String().split('T').first;

  /// feed wrapper returning a flat list
  Future<List<Map<String, dynamic>>> feed(DateTimeRange range, int limit) async {
    final lim = _clampLimit(limit);
    final data = await _get('$_base/feed', {
      'start_date': _ymd(range.start),
      'end_date'  : _ymd(range.end),
      'detailed'  : 'false',
    });

    final neoByDate =
    (data['near_earth_objects'] as Map).cast<String, dynamic>();

    final out = <Map<String, dynamic>>[];
    for (final v in neoByDate.values) {
      final dayList = (v as List?) ?? const [];
      for (final row in dayList) {
        out.add((row as Map).cast<String, dynamic>());
        if (out.length >= lim) break;
      }
      if (out.length >= lim) break;
    }
    return out;
  }

  /// Today’s feed → returns a flat list of NEO summaries.
  Future<List<Map<String, dynamic>>> getTodayFeed() async {
    // (could call feed() with today..today, but keep as-is if you prefer)
    final data = await _get('$_base/feed/today');
    final neoByDate =
    (data['near_earth_objects'] as Map).cast<String, dynamic>();
    final out = <Map<String, dynamic>>[];
    for (final v in neoByDate.values) {
      for (final row in (v as List)) {
        out.add((row as Map).cast<String, dynamic>());
      }
    }
    return out;
  }

  /// Full object with orbital_data
  Future<Map<String, dynamic>> getNeoById(String neoId) async {
    return _get('$_base/neo/$neoId');
  }

  /// browse search
  Future<List<Map<String, dynamic>>> search(String term, {int limit = 50}) async {
    final q = term.trim();
    if (q.isEmpty) return <Map<String, dynamic>>[];

    final int target = _clampLimit(limit);
    const int pageSize = 200;
    const int maxPages = 8;

    final List<Map<String, dynamic>> out = [];
    for (int page = 0; page < maxPages && out.length < target; page++) {
      final uri = Uri.parse(
        'https://api.nasa.gov/neo/rest/v1/neo/browse'
            '?page=$page&size=$pageSize&api_key=$apiKey',
      );
      final json = await _getJson(uri);
      final list = (json['near_earth_objects'] as List?) ?? const [];
      if (list.isEmpty) break;

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] ?? '').toString();
        final id = (item['neo_reference_id'] ?? '').toString();
        if (name.toLowerCase().contains(q.toLowerCase()) || id.contains(q)) {
          out.add(item);
          if (out.length >= target) break;
        }
      }

      final pageInfo = json['page'] as Map<String, dynamic>?;
      final totalPages = pageInfo?['total_pages'] as int?;
      if (totalPages != null && page >= totalPages - 1) break;
    }
    return out;
  }

  /// orbit details
  Future<({double? a, double? e, double? i})> fetchDetailsByNameOrId(String key) async {
    final k = key.trim();
    if (k.isEmpty) return (a: null, e: null, i: null);

    final isNumeric = RegExp(r'^\d+$').hasMatch(k);
    if (isNumeric) {
      final uri = Uri.parse(
        'https://api.nasa.gov/neo/rest/v1/neo/$k?api_key=$apiKey',
      );
      try {
        final obj = await _getJson(uri);
        final o = (obj['orbital_data'] as Map<String, dynamic>?);
        return (a: _d(o?['semi_major_axis']), e: _d(o?['eccentricity']), i: _d(o?['inclination']));
      } catch (_) { /* fall through */ }
    }

    const int pageSize = 200;
    const int maxPages = 8;
    for (int page = 0; page < maxPages; page++) {
      final uri = Uri.parse(
        'https://api.nasa.gov/neo/rest/v1/neo/browse'
            '?page=$page&size=$pageSize&api_key=$apiKey',
      );
      final json = await _getJson(uri);
      final list = (json['near_earth_objects'] as List?) ?? const [];

      Map<String, dynamic>? best;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] ?? '').toString();
        if (name.toLowerCase() == k.toLowerCase()) { best = item; break; }
        if (best == null && name.toLowerCase().contains(k.toLowerCase())) best = item;
      }
      if (best != null) {
        final o = (best['orbital_data'] as Map<String, dynamic>?);
        return (a: _d(o?['semi_major_axis']), e: _d(o?['eccentricity']), i: _d(o?['inclination']));
      }

      final pageInfo = json['page'] as Map<String, dynamic>?;
      final totalPages = pageInfo?['total_pages'] as int?;
      if (totalPages != null && page >= totalPages - 1) break;
    }

    return (a: null, e: null, i: null);
  }
}
