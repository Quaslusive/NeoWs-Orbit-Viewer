import 'dart:math';
import 'package:flutter/src/material/date.dart' show DateTimeRange ;
import 'package:neows_app/neows/neows_service.dart';
import 'package:neows_app/neows/asteroid_model.dart';
import 'package:neows_app/neows/asteroid_mappers.dart';
import 'package:neows_app/neows/neo_models.dart';

class AsteroidRepository {
  final NeoWsService _neo;
  final Random _rng = Random();

  // Caches
  final Map<String, OrbitElements> _orbitCache = {};
  List<NeoLite>? _todayCache;

  AsteroidRepository(this._neo);

  NeoLite _toNeoLiteFromFeed(Map<String, dynamic> m) =>
      asteroidFromFeedItem(m).toNeoLite();

  NeoLite _toNeoLite(Asteroid a) => a.toNeoLite();

  Future<OrbitElements> getOrbit(String neoId) async {
    final hit = _orbitCache[neoId];
    if (hit != null) return hit;
    final raw = await _neo.getNeoRawById(neoId);
    final el = OrbitElements.fromNeo(raw);
    _orbitCache[neoId] = el;
    return el;
  }

  /// Hazardous from /browse (paged). Keep max modest to avoid UI stalls
  Future<List<NeoLite>> fetchAllHazardous({int max = 3000}) async {
    const pageSize = 20;
    final out = <NeoLite>[];
    final seen = <String>{};

    var page = 0;
    final first = await _neo.browsePage(page: page, size: pageSize);
    final totalPages = first.totalPages ?? 0;

    void addHazRows(List<Map<String, dynamic>> rows) {
      for (final m in rows) {
        final a = asteroidFromBrowseOrLookup(m);
        if (a.isPha == true) {
          final n = _toNeoLite(a);
          if (seen.add(n.id)) out.add(n);
          if (out.length >= max) break;
        }
      }
    }

    addHazRows(first.items);
    for (page = 1; page < totalPages && out.length < max; page++) {
      final info = await _neo.browsePage(page: page, size: pageSize);
      addHazRows(info.items);
      if (out.length >= max) break;
    }
    return out;
  }

  /// All known (paged)
  Future<List<NeoLite>> fetchAllKnown({int max = 5000}) async {
    const pageSize = 20;
    final out = <NeoLite>[];
    final seen = <String>{};

    var page = 0;
    final first = await _neo.browsePage(page: page, size: pageSize);
    final totalPages = first.totalPages ?? 0;

    void addAllRows(List<Map<String, dynamic>> rows) {
      for (final m in rows) {
        final a = asteroidFromBrowseOrLookup(m);
        final n = _toNeoLite(a);
        if (seen.add(n.id)) out.add(n);
        if (out.length >= max) break;
      }
    }

    addAllRows(first.items);
    for (page = 1; page < totalPages && out.length < max; page++) {
      final info = await _neo.browsePage(page: page, size: pageSize);
      addAllRows(info.items);
      if (out.length >= max) break;
    }
    return out;
  }

  /// Today (no orbital_data). Cached per session.
  Future<List<NeoLite>> fetchToday() async {
    final cache = _todayCache;
    if (cache != null) return cache;
    final rows = await _neo.rawTodayFeed();
    final list = rows.map(_toNeoLiteFromFeed).toList(growable: false);
    _todayCache = list;
    return list;
  }

  Future<List<NeoLite>> fetchTodayHazardous() async {
    final today = await fetchToday();
    return today.where((n) => n.isHazardous).toList(growable: false);
  }

  Future<List<NeoLite>> fetchPoolForRandom() => fetchToday();
  NeoLite pickRandom(List<NeoLite> pool) => pool[_rng.nextInt(pool.length)];

  void clearCaches() {
    _orbitCache.clear();
    _todayCache = null;
  }

  Future<List<Asteroid>> feedRange(DateTime start, DateTime end, int limit) {
    final range = DateTimeRange(start: start, end: end);
    return _neo.feed(range, limit);

  }

  Future<List<Asteroid>> search(String term, {int limit = 500}) {
    return _neo.search(term, limit: limit);
  }

  Future<Asteroid> getNeoById(String id) {
    return _neo.getNeoById(id);
  }

}
