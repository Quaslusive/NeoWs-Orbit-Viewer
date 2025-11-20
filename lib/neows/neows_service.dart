import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:http/http.dart' as http;
import 'package:neows_app/neows/asteroid_model.dart';
import 'package:neows_app/neows/asteroid_mappers.dart';

typedef JsonMap = Map<String, dynamic>;

class NeoWsService {
  static const _base = 'https://api.nasa.gov/neo/rest/v1';
  final String apiKey;
  final http.Client _client;

  NeoWsService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  static JsonMap _decodeMap(String s) => jsonDecode(s) as JsonMap;

  Future<JsonMap> _getJson(Uri uri) async {
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('NeoWs ${res.statusCode}: ${res.body}');
    }
    return compute(_decodeMap, res.body);
  }

  Uri _uri(String path, [Map<String, String>? q]) {
    final qp = <String, String>{'api_key': apiKey, ...?q};
    return Uri.parse('$_base$path').replace(queryParameters: qp);
  }

  String _ymd(DateTime d) => d.toIso8601String().split('T').first;

  Future<List<JsonMap>> rawFeed(DateTimeRange range) async {
    final json = await _getJson(_uri('/feed', {
      'start_date': _ymd(range.start),
      'end_date': _ymd(range.end),
      'detailed': 'false',
    }));

    final neoByDate = (json['near_earth_objects'] as Map).cast<String, dynamic>();
    final out = <JsonMap>[];
    for (final v in neoByDate.values) {
      final dayList = (v as List?) ?? const [];
      for (final row in dayList) {
        if (row is Map<String, dynamic>) out.add(row);
      }
    }
    return out;
  }

  Future<List<JsonMap>> rawTodayFeed() async {
    final json = await _getJson(_uri('/feed/today'));
    final neoByDate = (json['near_earth_objects'] as Map).cast<String, dynamic>();
    final out = <JsonMap>[];
    for (final v in neoByDate.values) {
      final day = (v as List?) ?? const [];
      for (final row in day) {
        if (row is Map<String, dynamic>) out.add(row);
      }
    }
    return out;
  }

  Future<JsonMap> getNeoRawById(String neoId) => _getJson(_uri('/neo/$neoId'));

  Future<List<JsonMap>> rawSearch(String term, {int limit = 50}) async {
    final q = term.trim();
    if (q.isEmpty) return const <JsonMap>[];

    final target = limit.clamp(10, 1000);
    const pageSize = 20; // API max
    const maxPages = 8;
    final qLower = q.toLowerCase();

    final out = <JsonMap>[];
    for (int page = 0; page < maxPages && out.length < target; page++) {
      final json = await _getJson(_uri('/neo/browse', {
        'page': '$page',
        'size': '$pageSize',
      }));

      final list = (json['near_earth_objects'] as List?) ?? const [];
      if (list.isEmpty) break;

      for (final item in list) {
        final m = (item is Map<String, dynamic>) ? item : null;
        if (m == null) continue;
        final name = (m['name'] ?? '').toString();
        final id = (m['neo_reference_id'] ?? '').toString();
        if (name.toLowerCase().contains(qLower) || id.contains(q)) {
          out.add(m);
          if (out.length >= target) break;
        }
      }

      final pageInfo = json['page'] as Map<String, dynamic>?;
      final totalPages = pageInfo?['total_pages'] as int?;
      if (totalPages != null && page >= totalPages - 1) break;
    }
    return out;
  }

  Future<List<Asteroid>> feed(DateTimeRange range, int limit) async {
    final rows = await rawFeed(range);
    final out = <Asteroid>[];
    for (final m in rows) {
      out.add(asteroidFromFeedItem(m));
      if (out.length >= limit.clamp(10, 1000)) break;
    }
    return out;
  }
  Future<List<Asteroid>> search(String term, {int limit = 50}) async {
    final rows = await rawSearch(term, limit: limit);
    return rows.map(asteroidFromBrowseOrLookup).toList(growable: false);
  }

  Future<Asteroid> getNeoById(String neoId) async {
    final m = await getNeoRawById(neoId);
    return asteroidFromBrowseOrLookup(m);
  }

  Future<({List<JsonMap> items, int? totalPages})> browsePage({
    int page = 0,
    int size = 20, // API max
  }) async {
    if (size > 20) size = 20;
    final json = await _getJson(_uri('/neo/browse', {
      'page': '$page',
      'size': '$size',
    }));
    final list = (json['near_earth_objects'] as List?) ?? const [];
    final pageInfo = json['page'] as Map<String, dynamic>?;
    final totalPages = pageInfo?['total_pages'] as int?;
    final items = list.whereType<Map<String, dynamic>>().toList(growable: false);
    return (items: items, totalPages: totalPages);
  }

  void close() => _client.close();
}
