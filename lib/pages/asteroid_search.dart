import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
// Services + mappers
import 'package:neows_app/service/neoWs_service.dart';
import 'package:neows_app/service/asterank_api_service.dart';
import 'package:neows_app/mappers/asteroid_mappers.dart';
import 'package:neows_app/search/asteroid_filters.dart';
import 'package:neows_app/search/asteroid_filter_sheet.dart';
// UI + model
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/pages/asteroid_details_page.dart';
import 'package:neows_app/widget/asteroid_card.dart';
// Envied key
import 'package:neows_app/env/env.dart';

// ----- Source selector -----
enum ApiSource { neows, mpcOnline }

extension ApiSourceX on ApiSource {
  String get label => switch (this) {
    ApiSource.neows => 'NeoWs',
    ApiSource.mpcOnline => 'MPC',
  };
  bool get supportsDate => this == ApiSource.neows;
}

class AsteroidSearchPage extends StatefulWidget {
  const AsteroidSearchPage({super.key});
  @override
  State<AsteroidSearchPage> createState() => _AsteroidSearchPageState();
}

class _AsteroidSearchPageState extends State<AsteroidSearchPage> {
  // Services
  late final NeoWsService _neo;
  late final AsterankApiService _mpcOnline;

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
    _mpcOnline = AsterankApiService(enableLogs: true);
    _dispatchSearch(currentTerm: '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  List<Asteroid> _applyClientFilters(List<Asteroid> list, AsteroidFilters f) {
    double? _mToKm(double? m) => m == null ? null : m / 1000.0;

    bool _useRange(DoubleRange? r, double fullMin, double fullMax) {
      if (r == null) return false;
      final min = r.min ?? fullMin;
      final max = r.max ?? fullMax;
      // If the slider spans the full range, treat it as OFF
      return !(min <= fullMin && max >= fullMax);
    }

    final nameQuery = (f.query ?? _query).trim().toLowerCase();
    final useDiam = _useRange(f.diameterM, 0, FilterBounds.diamMaxM);
    final useH    = _useRange(f.hMag,      FilterBounds.hMin, FilterBounds.hMax);
    final useE    = _useRange(f.e,         0,                 FilterBounds.eMax);
    final useA    = _useRange(f.aAu,       0,                 FilterBounds.aMax);
    final useI    = _useRange(f.iDeg,      0,                 FilterBounds.iMax);

    final diamMinKm = _mToKm(f.diameterM?.min);
    final diamMaxKm = _mToKm(f.diameterM?.max);

    bool _inRange(double v, double? min, double? max) {
      if (min != null && v < min) return false;
      if (max != null && v > max) return false;
      return true;
    }

    double? _getH(Asteroid a) {
      try { return (a as dynamic).H as double?; } catch (_) { return null; }
    }

    bool _matchText(Asteroid a) {
      if (nameQuery.isEmpty) return true;
      final n1 = a.name.toLowerCase();
      final n2 = a.fullName.toLowerCase();
      return n1.contains(nameQuery) || n2.contains(nameQuery);
    }

    bool _isPha(Asteroid a) {
      final v = a.pha.toString().toLowerCase();
      return v == 'y' || v == 'true' || v == 'yes' || v == '1';
    }

    return list.where((a) {
      if (!_matchText(a)) return false;

      if (f.phaOnly && !_isPha(a)) return false;

      // Diameter (slider is meters → convert to km for model)
      if (useDiam) {
        if (!(_inRange(a.diameter, diamMinKm, diamMaxKm))) return false;
      }

      if (useH) {
        final h = _getH(a);
        if (h == null) return false;
        if (!_inRange(h, f.hMag!.min, f.hMag!.max)) return false;
      }

      if (useI) {
        final inc = a.i;
        // Only enforce if we actually have a value; 0.0 = unknown from NeoWs feed
        if (inc != 0.0 && !_inRange(inc, f.iDeg!.min, f.iDeg!.max)) return false;
      }

      if (useE) {
        final ecc = a.e;
        if (ecc != 0.0 && !_inRange(ecc, f.e!.min, f.e!.max)) return false;
      }

      if (useA) {
        final sma = a.a;
        if (sma != 0.0 && !_inRange(sma, f.aAu!.min, f.aAu!.max)) return false;
      }

      if (f.maxMoidAu != null && a.moid > f.maxMoidAu!) return false;

      if (useE && !_inRange(a.e, f.e!.min, f.e!.max)) return false;
      if (useA && !_inRange(a.a, f.aAu!.min, f.aAu!.max)) return false;
      if (useI && !_inRange(a.i, f.iDeg!.min, f.iDeg!.max)) return false;

      // Close-approach filters skipped (not in your model yet)
      return true;
    }).toList(growable: false);
  }


  Future<void> _openFilters() async {
    final supportsCA = _source == ApiSource.neows;
    final picked = await showModalBottomSheet<AsteroidFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AsteroidFilterSheet(
        initial: _filters.copyWith(query: _query),
        supportsCloseApproach: supportsCA,
      ),
    );
    if (picked != null) {
      setState(() {
        _filters = picked;
        _query = picked.query ?? _query;
        if (supportsCA && picked.window != null) {
          _neoRange = picked.window; // use selected window for /feed
        }
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

  // Orbit lazy enrichment
  Future<void> _ensureOrbit(Asteroid ast) async {
    if (ast.a > 0 && ast.e > 0) return;
    if (_orbitCache.containsKey(ast.id)) {
      if (mounted) setState(() {});
      return;
    }
    if (_orbitLoading.contains(ast.id) || _orbitActive >= _orbitMaxConcurrent)
      return;

    final term = (ast.fullName.isNotEmpty ? ast.fullName : ast.name).trim();
    if (term.isEmpty) return;

    _orbitLoading.add(ast.id);
    _orbitActive++;
    try {
      // 2) Online fallback
      try {
        final on = await _mpcOnline.searchMany(term, limit: 1);
        if (on.isNotEmpty) {
          final a = on.first.a;
          final e = on.first.e;
          final i = on.first.i;
          if (a != null && a > 0 && e != null && e > 0) {
            _orbitCache[ast.id] = (a: a, e: e, i: i);
            if (mounted) setState(() {});
          }
        }
      } catch (e) {
        debugPrint('Online MPC orbit fetch failed: $e');
      }
    } finally {
      _orbitLoading.remove(ast.id);
      _orbitActive = math.max(0, _orbitActive - 1); // keep int
    }
  }


  Future<void> _dispatchSearch({required String currentTerm}) async {
    setState(() => _loading = true);
    try {
      final lim = _limit.clamp(10, 1000);
      List<Asteroid> out = [];

      switch (_source) {
        case ApiSource.neows: {
          final now = DateTime.now();
          final picked = _neoRange ?? DateTimeRange(start: now, end: now.add(const Duration(days: 6)));
          final rows = await _neo.feed(picked, lim);
          out = rows.map(asteroidFromNeowsMap).toList();
          break;
        }
        case ApiSource.mpcOnline: {
          if (currentTerm.isEmpty) {
            final tops = await _mpcOnline.fetchTop(limit: lim);
            out = tops.map(_asteroidFromMpcRow).toList();
          } else {
            final rows = await _mpcOnline.searchMany(currentTerm, limit: lim);
            out = rows.map(_asteroidFromMpcRow).toList();
          }
          break;
        }
      }

      // 👇 Apply UI filters *after* fetching
      out = _applyClientFilters(out, _filters);

      setState(() => _filtered = out);
    } catch (e) {
      debugPrint('Dispatch error: $e');
      setState(() => _filtered = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // MpcRow -> Asteroid adapter
  Asteroid _asteroidFromMpcRow(MpcRow r) {
    final display = (r.readableDes ?? r.des ?? 'Unknown');
    return Asteroid(
      id: r.des ?? display,
      name: display,
      fullName: display,
      diameter: 0.0,
      albedo: 0.0,
      neo: 'unknown',
      pha: 'unknown',
      rotationPeriod: 0.0,
      classType: 'MPC',
      orbitId: 0,
      moid: r.moid ?? 0.0,
      a: r.a ?? 0.0,
      e: r.e ?? 0.0,
      i: r.i ?? 0.0,
    );
  }

  String getDangerLevel(Asteroid a) {
    final isPha = a.pha.toUpperCase() == 'Y';
    final moidRisk = a.moid < 0.05; // au
    final bigEnough = a.diameter >= 0.14; // km (~140m)
    if ((isPha || moidRisk) && bigEnough) return 'Danger🔥';
    if (isPha || moidRisk) return 'Moderate⚠️';
    return 'Safe✅';
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
                          value: ApiSource.mpcOnline, label: Text('MPC')),

                    ],
                    selected: {_source},
                    showSelectedIcon: false,
                    onSelectionChanged: (sel) {
                      setState(() {
                        _source = sel.first;
                        if (!_source.supportsDate) _neoRange = null;
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
                if (!hasOrbit) _ensureOrbit(asteroid);

                return AsteroidCard(
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
    if (f.maxMissDistanceKm != null) chips.add(Chip(label: Text('≤ ${f.maxMissDistanceKm!.round()} km')));
    if (f.targetBody != null) chips.add(Chip(label: Text(f.targetBody!)));
    if (f.hMag?.isSet == true) chips.add(Chip(label: Text('H ${f.hMag!.min?.toStringAsFixed(1) ?? ""}-${f.hMag!.max?.toStringAsFixed(1) ?? ""}')));
    if (f.diameterM?.isSet == true) chips.add(Chip(label: Text('Ø ${f.diameterM!.min?.round() ?? 0}-${f.diameterM!.max?.round() ?? 0} m')));
    if (f.orbitClasses.isNotEmpty) chips.add(Chip(label: Text(f.orbitClasses.join('·'))));
    if (f.window != null) {
      chips.add(Chip(label: Text(
        '${f.window!.start.toIso8601String().split("T").first}→${f.window!.end.toIso8601String().split("T").first}',
      )));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips.map((c) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: c,
      )).toList()),
    );
  }
}
