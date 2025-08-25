// lib/pages/asteroid_search_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// Services + mappers
import 'package:neows_app/service/neoWs_service.dart';
import 'package:neows_app/service/asterank_api_service.dart';
import 'package:neows_app/service/offline_mpc_service.dart';
import 'package:neows_app/mappers/asteroid_mappers.dart';

// UI + model
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/pages/asteroid_details_page.dart';
import 'package:neows_app/widget/asteroid_card.dart';

// Envied key
import 'package:neows_app/env/env.dart';

// ----- Source selector -----
enum ApiSource { neows, mpcOnline, mpcOffline }

extension ApiSourceX on ApiSource {
  String get label => switch (this) {
    ApiSource.neows => 'NeoWs',
    ApiSource.mpcOnline => 'MPC',
    ApiSource.mpcOffline => 'Offline',
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
  late final OfflineMpcService _mpcOffline;

  // User options
  ApiSource _source = ApiSource.neows;
  int _limit = 50; // clamp 10–1000 where used
  DateTimeRange? _neoRange; // NeoWs only

  // UI/data state
  String _query = '';
  bool _loading = false;
  Timer? _debounce;
  List<Asteroid> _filtered = [];

  // Orbit enrichment cache/throttle (instance-scoped)
  final Map<String, ({double a, double e})> _orbitCache = {};
  final Set<String> _orbitLoading = {};
  int _orbitActive = 0;
  static const int _orbitMaxConcurrent = 2;

  @override
  void initState() {
    super.initState();
    _neo = NeoWsService(Env.nasaApiKey);
    _mpcOnline = AsterankApiService(enableLogs: true);
    _mpcOffline = OfflineMpcService();

    // Preload offline file (CSV: readable_des,des,H,a,e,i,moid)
    _mpcOffline.loadFromAssets('assets/mpc_subset.csv');

    _dispatchSearch(currentTerm: '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
    if (_orbitLoading.contains(ast.id) || _orbitActive >= _orbitMaxConcurrent) return;

    final term = (ast.fullName.isNotEmpty ? ast.fullName : ast.name).trim();
    if (term.isEmpty) return;

    _orbitLoading.add(ast.id);
    _orbitActive++;
    try {
      // 1) Offline first
      try {
        final off = await _mpcOffline.search(term: term, limit: 1);
        if (off.isNotEmpty) {
          final a = (off.first['a'] as num?)?.toDouble();
          final e = (off.first['e'] as num?)?.toDouble();
          if (a != null && a > 0 && e != null && e > 0) {
            _orbitCache[ast.id] = (a: a, e: e);
            if (mounted) setState(() {});
            return;
          }
        }
      } catch (_) {}

      // 2) Online fallback
      try {
        final on = await _mpcOnline.searchMany(term, limit: 1);
        if (on.isNotEmpty) {
          final a = on.first.a;
          final e = on.first.e;
          if (a != null && a > 0 && e != null && e > 0) {
            _orbitCache[ast.id] = (a: a, e: e);
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

  // Dispatcher
  Future<void> _dispatchSearch({required String currentTerm}) async {
    setState(() => _loading = true);
    try {
      final lim = _limit.clamp(10, 1000);

      switch (_source) {
        case ApiSource.neows:
          final now = DateTime.now();
          final dr = _neoRange ?? DateTimeRange(start: now, end: now);
          final rows = await _neo.feed(dr, lim);
          _filtered = rows.map(asteroidFromNeowsMap).toList();
          break;

        case ApiSource.mpcOnline:
          final rows = await _mpcOnline.searchMany(currentTerm, limit: lim);
          _filtered = rows.map(_asteroidFromMpcRow).toList();
          break;

        case ApiSource.mpcOffline:
          final rows = await _mpcOffline.search(term: currentTerm, limit: lim);
          _filtered = rows.map(asteroidFromMpcMap).toList();
          break;
      }
    } catch (e) {
      debugPrint('Dispatch error: $e');
      _filtered = [];
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
    );
  }

  String getDangerLevel(Asteroid a) {
    final isPha = a.pha.toUpperCase() == 'Y';
    final moidRisk = a.moid < 0.05;       // au
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
              decoration: const InputDecoration(labelText: 'Sök asteroid namn'),
              onChanged: _onSearchChanged,
            ),
          ),

          // Segmented source + Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  height: 40,
                  child: SegmentedButton<ApiSource>(
                    segments: const [
                      ButtonSegment(value: ApiSource.neows,     label: Text('NeoWs')),
                      ButtonSegment(value: ApiSource.mpcOnline, label: Text('MPC')),
                      ButtonSegment(value: ApiSource.mpcOffline,label: Text('Offline')),
                    ],
                    selected: {_source},
                    showSelectedIcon: false,
                    onSelectionChanged: (sel) {
                      setState(() {
                        _source = sel.first;
                        if (!_source.supportsDate) _neoRange = null;
                      });
                      _dispatchSearch(currentTerm: _query); // refresh with current text
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _source.supportsDate ? () async {
                    final now = DateTime.now();
                    final init = _neoRange ?? DateTimeRange(start: now, end: now);
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      initialDateRange: init,
                    );
                    if (picked != null) {
                      setState(() => _neoRange = picked);
                      _dispatchSearch(currentTerm: _query);
                    }
                  } : null,
                  child: Text(
                    _source.supportsDate
                        ? (_neoRange == null
                        ? 'Choose dates'
                        : '${_neoRange!.start.toString().substring(0,10)} → ${_neoRange!.end.toString().substring(0,10)}')
                        : 'Dates N/A',
                  ),
                ),
              ],
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),

          // Results
          Expanded(
            child: _filtered.isEmpty && !_loading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No asteroids found.'),
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

                // orbit enrichment/cache
                final cached = _orbitCache[asteroid.id];
                final orbitA = cached?.a ?? (asteroid.a > 0 ? asteroid.a : null);
                final orbitE = cached?.e ?? (asteroid.e > 0 ? asteroid.e : null);
                final hasOrbit = (orbitA != null && orbitE != null);
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
                        builder: (_) => AsteroidDetailsPage(asteroid: asteroid),
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
