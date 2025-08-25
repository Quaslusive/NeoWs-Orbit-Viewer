import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class NeoWsService {
  final String apiKey;
  NeoWsService(this.apiKey);

  /// Clamp limit between 10 and 1000
  int _clampLimit(int v) => v.clamp(10, 1000);

  /// Returns flattened rows from /feed (date buckets merged).
  /// `limit` is positional here.
  Future<List<Map<String, dynamic>>> feed(DateTimeRange dr, int limit) async {
    // Clamp to at most 7 days
    final days = dr.end.difference(dr.start).inDays.abs();
    final end = days > 6 ? dr.start.add(const Duration(days: 6)) : dr.end;

    String fmt(DateTime d) => d.toIso8601String().substring(0, 10);
    final uri = Uri.parse(
      'https://api.nasa.gov/neo/rest/v1/feed'
          '?start_date=${fmt(dr.start)}&end_date=${fmt(end)}&api_key=$apiKey',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('NeoWs ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final neo = data['near_earth_objects'] as Map<String, dynamic>? ?? {};
    final List<Map<String, dynamic>> it = [];

    neo.forEach((_, list) {
      for (final row in (list as List)) {
        it.add(row as Map<String, dynamic>);
      }
    });

    return it.take(_clampLimit(limit)).toList();
  }
}
