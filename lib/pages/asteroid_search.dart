import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
// Services + mappers
import 'package:neows_app/service/neoWs_service.dart';
import 'package:neows_app/service/asterank_api_service.dart' show AsterankApiService, AsterankObject;
import 'package:neows_app/mappers/asteroid_mappers.dart';
import 'package:neows_app/search/asteroid_filters.dart';
import 'package:neows_app/search/asteroid_filter_sheet.dart';
// UI + model
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/pages/asteroid_details_page.dart';
import 'package:neows_app/widget/asteroid_card.dart';
// Envied key
import 'package:neows_app/env/env.dart';

import 'package:neows_app/service/asteroid_filtering.dart'; // applyFilters + SortKey
import 'package:neows_app/utils/num_utils.dart';// toDouble/toStr if you need them here

import 'package:neows_app/service/source_caps.dart';          // NEW

class AsteroidSearchPage extends StatefulWidget {
  const AsteroidSearchPage({super.key});
  @override
  State<AsteroidSearchPage> createState() => _AsteroidSearchPageState();
}
class _ResultCache {
  final _m = <String, List<Asteroid>>{};
  String _k(ApiSource s, String t, int l) => '${s.name}|$t|$l';
  List<Asteroid>? get(ApiSource s, String t, int l) => _m[_k(s, t, l)];
  void put(ApiSource s, String t, int l, List<Asteroid> v) => _m[_k(s, t, l)] = v;
}


class _AsteroidSearchPageState extends State<AsteroidSearchPage> {
  // Services
  late final NeoWsService _neo;
  late final AsterankApiService _asterank;
final _cache = _ResultCache();

  // cancel stale searches
  int _reqId = 0;



  // User options
  ApiSource _source = ApiSource.neows;
  int _limit = 100; // clamp 10–1000 where used
  DateTimeRange? _neoRange; // NeoWs only

  // Filters + search
  AsteroidFilters _filters = AsteroidFilters();


  // UI/data state
  String _query = '';
  bool _loading = false;
  Timer? _debounce;
  List<Asteroid> _filtered = [];

  // Orbit enrichment cache/throttle (instance-scoped)
  final Map<String, ({double a, double e, double? i})> _orbitCache = {};
  final Set<String> _orbitLoading = {};
  int _orbitActive = 0;
  static const int _orbitMaxConcurrent = 2;

  @override
  void initState() {
    super.initState();
    _neo = NeoWsService(Env.nasaApiKey);
    _asterank = AsterankApiService(enableLogs: true);
    _dispatchSearch(currentTerm: '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final caps = _source.caps; // alias
    final picked = await showModalBottomSheet<AsteroidFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AsteroidFilterSheet(
        initial: _filters.copyWith(query: _query),
        supportsCloseApproach: caps.supportsCloseApproach,
        supportsDateWindow:   caps.supportsDateWindow,
        supportsHazardFlag:   caps.supportsHazardFlag,
      ),
    );


    if (picked != null) {
      setState(() {
        _filters = picked;
        _query = picked.query;
        _neoRange = _source.caps.supportsDateWindow ? picked.window : null;
      });
      _dispatchSearch(currentTerm: _query);
    }
  }

  // Search input (debounced)
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = q.trim());
      _dispatchSearch(currentTerm: _query);
    });
  }

  Future<void> _ensureOrbit(Asteroid ast) async {
    if (ast.a > 0 && ast.e > 0) return;
    if (_orbitCache.containsKey(ast.id)) { if (mounted) setState(() {}); return; }
    if (_orbitLoading.contains(ast.id) || _orbitActive >= _orbitMaxConcurrent) return;

    final term = (ast.fullName.isNotEmpty ? ast.fullName : ast.name).trim();
    if (term.isEmpty) return;

    _orbitLoading.add(ast.id);
    _orbitActive++;
    try {
      // 1) If current source is NeoWs and details endpoint exists, try it first
      if (_source == ApiSource.neows) {
        try {

          final d = await _neo.fetchDetailsByNameOrId(term); // implement if not present
          final a = d.a, e = d.e, i = d.i;
          if (a != null && a > 0 && e != null && e > 0) {
            _orbitCache[ast.id] = (a: a, e: e, i: i);
            if (mounted) setState(() {});
            return;
          }
        } catch (_) {}
      }

      // 2) Fallback: Asterank objects
      final rows = await _asterank.search(term, limit: 1);
      if (rows.isNotEmpty) {
        final o = rows.first;
        final a = o.a, e = o.e, i = o.i;
        if (a != null && a > 0 && e != null && e > 0) {
          _orbitCache[ast.id] = (a: a, e: e, i: i);
          if (mounted) setState(() {});
        }
      }
    } finally {
      _orbitLoading.remove(ast.id);
      _orbitActive = math.max(0, _orbitActive - 1);
    }
  }


  Future<void> _dispatchSearch({required String currentTerm}) async {
    final int myId = ++_reqId;                  // take a ticket for cancellation
    setState(() => _loading = true);

    try {
      final int lim = _limit.clamp(10, 1000);
      final f = _filters;
      final String term = (f.query.isNotEmpty ? f.query : currentTerm).trim();
      // 1) Cache check (instant UI if same query/limit/source)
      final cached = _cache.get(_source, term, lim);
      if (cached != null) {
        if (myId != _reqId) return;
        setState(() {
          _filtered = cached;
          _loading = false;
        });
        return;
      }

      // 2) Fetch per source
      List<Asteroid> out = [];
      switch (_source) {
        case ApiSource.neows: {
          final bool hasQuery = term.isNotEmpty;
          if (_source.caps.supportsDateWindow && !hasQuery) {
            final now = DateTime.now();
            final picked = f.window ?? DateTimeRange(
              start: now,
              end: now.add(const Duration(days: 6)),
            );
            final rows = await _neo.feed(picked, lim);
            out = rows.map<Asteroid>(asteroidFromNeowsMap).toList();
          } else {
            final rows = await _neo.search(term, limit: lim);
            out = rows.map<Asteroid>(asteroidFromNeowsMap).toList();
          }
          break;
        }

        case ApiSource.asterank: {
          if (term.isEmpty) {
            final rows = await _asterank.fetchTop(limit: lim);
            out = rows.map<Asteroid>(_asteroidFromAsterank).toList();
          } else {
            final rows = await _asterank.search(term, limit: lim);
            out = rows.map<Asteroid>(_asteroidFromAsterank).toList();
          }
          break;
        }
      }

      // 3) Client-side filter/sort
      out = out.applyFilters(f, sortKey: SortKey.size, descending: true);

      // 4) Save to cache before updating UI
      _cache.put(_source, term, lim, out);

      if (myId != _reqId) return;               // drop stale results
      setState(() => _filtered = out);
    } catch (e) {
      if (myId != _reqId) return;
      debugPrint('Dispatch error: $e');
      setState(() => _filtered = []);
    } finally {
      if (mounted && myId == _reqId) {
        setState(() => _loading = false);
      }
    }
  }




// AsterankObject -> Asteroid adapter
  Asteroid _asteroidFromAsterank(AsterankObject o) {
    final display = o.title.isNotEmpty ? o.title : o.id;
    return Asteroid(
      id: o.id,
      name: display,
      fullName: display,
      diameter: o.diameter ?? 0.0,
      albedo: o.albedo ?? 0.0,
      neo: (o.neo == true) ? 'Y' : 'N',
      pha: 'unknown',   // /api/asterank doesn’t expose PHA reliably
      rotationPeriod: 0.0,
      classType: 'Asterank',
      orbitId: 0,
      moid: 0.0,        /// not provided by /api/asterank
      a: o.a ?? 0.0,
      e: o.e ?? 0.0,
      i: o.i ?? 0.0,
    );
  }


  String getDangerLevel(Asteroid a) {
    // NeoWs case: you might have pha + moid
    final pha = a.pha.toUpperCase() == 'Y';
    final moidKnown = a.moid > 0;
    final moidRisk = moidKnown && a.moid < 0.05; // au
    final big = a.diameter >= 0.14;

    if (pha && (big || moidRisk)) return 'Danger🔥';
    if (pha || moidRisk) return 'Moderate⚠️';

    // Asterank fallback: no PHA/MOID; show NEO tag if sizable
    final isNeo = a.neo.toUpperCase() == 'Y';
    if (isNeo && big) return 'NEO⚠️';
    if (isNeo) return 'NEO';
    return '—';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sök efter Asteroids')),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                  labelText: 'Sök asteroid namn'),
              onChanged: _onSearchChanged,
            ),
          ),

          // Source selector + date picker row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  height: 40,
                  child: SegmentedButton<ApiSource>(
                    segments: const [
                      ButtonSegment(
                          value: ApiSource.neows, label: Text('NeoWs')),
                      ButtonSegment(
                          value: ApiSource.asterank, label: Text('Asterank')),
                    ],
                    selected: {_source},
                    showSelectedIcon: false,
                    onSelectionChanged: (sel) {
                      setState(() {
                        _source = sel.first;
                        final caps = _source.caps;
                        if (!caps.supportsDateWindow) _neoRange = null;
                      });
                      _dispatchSearch(currentTerm: _query);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Source + results + Filter/Rensa buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Källa: ${_source.label} • Resultat: ${_filtered.length}',
                    style: Theme
                        .of(context)
                        .textTheme
                        .labelMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                      _filters.isEmpty ? 'Filter' : 'Filter (aktiva)'),
                ),
                if (!_filters.isEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _filters = AsteroidFilters());
                      _dispatchSearch(currentTerm: _query);
                    },
                    child: const Text('Rensa'),
                  ),
              ],
            ),
          ),

          // Active filter chips (optional)
          if (!_filters.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: _ActiveFilterSummary(_filters),
            ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: _filtered.isEmpty && !_loading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Inga träffar'),
              ),
            )
                : GridView.builder(
              itemCount: _filtered.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final asteroid = _filtered[index];

                final cached = _orbitCache[asteroid.id];
                final orbitA = cached?.a ??
                    (asteroid.a > 0 ? asteroid.a : null);
                final orbitE = cached?.e ??
                    (asteroid.e > 0 ? asteroid.e : null);
                final orbitI = cached?.i ??
                    (asteroid.i > 0 ? asteroid.i : null);
                final hasOrbit = (orbitA != null && orbitE != null && orbitI != null);
                if (!hasOrbit) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _ensureOrbit(asteroid);
                  });
                }

                return AsteroidCard(
                  key: ValueKey(asteroid.id),
                  a: asteroid,
                  dangerLevel: getDangerLevel,
                  isLoadingAsterank: false,
                  orbitA: orbitA,
                  orbitE: orbitE,
                  isOrbitLoading: _orbitLoading.contains(asteroid.id),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AsteroidDetailsPage(asteroid: asteroid),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _ActiveFilterSummary extends StatelessWidget {
  final AsteroidFilters f;
  const _ActiveFilterSummary(this.f);

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (f.phaOnly) chips.add(const Chip(label: Text('PHA')));


    if (f.targetBody != null) chips.add(Chip(label: Text(f.targetBody!)));

    // H-magnitude not in your model; only show if your filter UI uses it intentionally
    if (f.hMag?.isSet == true) {
      chips.add(Chip(label: Text('H ${f.hMag!.min?.toStringAsFixed(1) ?? ""}-${f.hMag!.max?.toStringAsFixed(1) ?? ""}')));
    }


    if (f.diameterKm?.isSet == true) {
      final minTxt = f.diameterKm!.min?.toStringAsFixed(2) ?? '';
      final maxTxt = f.diameterKm!.max?.toStringAsFixed(2) ?? '';
      chips.add(Chip(label: Text('Ø $minTxt–$maxTxt km')));
    }


    // Orbit classes (if used)
    if (f.orbitClasses.isNotEmpty) {
      chips.add(Chip(label: Text(f.orbitClasses.join('·'))));
    }

    // Window (NeoWs)
    if (f.window != null) {
      chips.add(Chip(
        label: Text(
          '${f.window!.start.toIso8601String().split("T").first} → ${f.window!.end.toIso8601String().split("T").first}',
        ),
      ));
    }

    // MOID (use range if present; else show single max)
    if (f.moidAu?.isSet == true) {
      final minTxt = f.moidAu!.min?.toStringAsFixed(3) ?? '';
      final maxTxt = f.moidAu!.max?.toStringAsFixed(3) ?? '';
      chips.add(Chip(label: Text('MOID $minTxt–$maxTxt au')));
    } else if (f.maxMoidAu != null) {
      chips.add(Chip(label: Text('MOID ≤ ${f.maxMoidAu!.toStringAsFixed(3)} au')));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: c))
            .toList(),
      ),
    );
  }
}

