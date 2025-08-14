import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show compute;

import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/pages/asteroid_details_page.dart';
import 'package:neows_app/widget/asteroid_card.dart';
import 'package:neows_app/service/asterank_api_service.dart';

// -------- CSV parsing on a background isolate --------
List<List<dynamic>> _parseCsv(String raw) {
  return const CsvToListConverter(eol: '\n').convert(raw);
}

class AsteroidSearchPage extends StatefulWidget {
  const AsteroidSearchPage({super.key});

  @override
  State<AsteroidSearchPage> createState() => _AsteroidSearchPageState();
}

class _AsteroidSearchPageState extends State<AsteroidSearchPage> {
  final AsterankApiService _asterank = AsterankApiService();
  final Set<String> _enriching = {};

  // Data in memory
  List<Asteroid> _asteroids = [];
  List<Asteroid> _filtered = [];

  // Modes & limits
  bool _onlineMode = true;   // API enrichment only when true
  int _csvLimit = 50;        // how many rows to load from CSV
  int _asterankLimit = 50;   // how many results to enrich with Asterank

  // Paging the visible list
  int _visibleCount = 50;
  int _pageSize = 50;

  // Search debounce
  Timer? _debounce;
  String _search = '';

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    _loadCsv(); // initial CSV load
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ---------- helpers ----------
  bool _hasAnyAsterank(Asteroid a) =>
      a.asterankPriceUsd != null ||
          a.asterankAlbedo != null ||
          a.asterankDiameterKm != null ||
          a.asterankDensity != null ||
          (a.asterankSpec?.isNotEmpty == true);

  // Danger label
  String getDangerLevel(Asteroid a) {
    final isPha = a.pha.toUpperCase() == 'Y';
    final moidRisk = a.moid < 0.05;         // au
    final bigEnough = a.diameter >= 0.14;   // km (~140m)
    if ((isPha || moidRisk) && bigEnough) return 'Extreme Danger 🔥🔥🔥';
    if (isPha || moidRisk) return 'Moderate Risk ⚠️';
    return 'Safe ✅';
  }

  // ---------- CSV loading ----------
  Future<void> _loadCsv() async {
    // Pick the asset you actually want to ship:
    // final raw = await rootBundle.loadString('lib/assets/latest_fulldb.csv');
    final raw = await rootBundle.loadString('lib/assets/astroidReadTest.csv');

    final csv = await compute(_parseCsv, raw);

    final list = <Asteroid>[];
    // Skip header at index 0. Respect _csvLimit.
    for (int i = 1; i < csv.length && i <= _csvLimit; i++) {
      final row = csv[i];
      list.add(
        Asteroid(
          id: (row[0] ?? '').toString(),
          name: (row[4] ?? '').toString(),
          fullName: (row[2] ?? '').toString(),
          diameter: double.tryParse(row[15].toString()) ?? 0.0,  // km
          albedo: double.tryParse(row[17].toString()) ?? 0.0,
          neo: (row[6] ?? '').toString(),
          pha: (row[7] ?? '').toString(),
          rotationPeriod: double.tryParse(row[18].toString()) ?? 0.0,
          classType: (row[60] ?? '').toString(),
          orbitId: int.tryParse(row[27].toString()) ?? 0,
          moid: double.tryParse(row[45].toString()) ?? 0.0,      // au
          a: double.tryParse(row[33].toString()) ?? 0.0,
          e: double.tryParse(row[32].toString()) ?? 0.0,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _asteroids = list;
      _filtered = list;
      _visibleCount = _pageSize.clamp(0, _filtered.length);
    });

    if (_onlineMode) _enrichBatch(_filtered);
  }

  // ---------- Enrichment (Asterank) ----------
  Future<void> _enrichBatch(List<Asteroid> items) async {
    if (!_onlineMode) return;
    final batch = items.take(_asterankLimit).toList();
    for (final a in batch) {
      _fetchAndAttachAsterank(a);
    }
  }

  Future<void> _fetchAndAttachAsterank(Asteroid a) async {
    if (!_onlineMode) return;
    if (_enriching.contains(a.id) || _hasAnyAsterank(a)) return;

    setState(() => _enriching.add(a.id));
    try {
      final key = (a.name?.trim().isNotEmpty == true)
          ? a.name!.trim()
          : (a.fullName ?? '').trim();
      if (key.isEmpty) return;

      final info = await _asterank.fetchByDesignation(key);
      if (!mounted || info == null) return;

      setState(() {
        a.applyAsterank(info);
      });
    } finally {
      if (mounted) setState(() => _enriching.remove(a.id));
    }
  }

  // ---------- Search ----------
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _search = q;
        final needle = q.toLowerCase();
        _filtered = _asteroids.where((a) {
          final n = (a.name ?? '').toLowerCase();
          final fn = (a.fullName ?? '').toLowerCase();
          return n.contains(needle) || fn.contains(needle);
        }).toList();
        _visibleCount = _pageSize.clamp(0, _filtered.length);
      });
      if (_onlineMode) _enrichBatch(_filtered);
    });
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final aspectRatio = isSmallScreen ? 0.8 : 0.9;

    final items = _filtered.take(_visibleCount).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Sök efter Asteroids')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration:
              const InputDecoration(labelText: 'Sök asteroid namn'),
              onChanged: _onSearchChanged,
            ),
          ),

          // Controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Online / Offline
                Expanded(
                  child: SwitchListTile.adaptive(
                    dense: true,
                    title: Text(
                      _onlineMode
                          ? 'Online (API enabled)'
                          : 'Offline (CSV only)',
                    ),
                    value: _onlineMode,
                    onChanged: (v) {
                      setState(() => _onlineMode = v);
                      if (_onlineMode) _enrichBatch(_filtered);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // CSV limit
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('CSV'),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: _csvLimit,
                      items: const [10, 25, 50, 100, 200]
                          .map((n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n'),
                      ))
                          .toList(),
                      onChanged: (n) async {
                        if (n == null) return;
                        setState(() => _csvLimit = n);
                        await _loadCsv(); // re-read with new limit
                      },
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                // API enrichment limit
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('API'),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: _asterankLimit,
                      items: const [10, 25, 50, 100, 200]
                          .map((n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n'),
                      ))
                          .toList(),
                      onChanged: (n) {
                        if (n == null) return;
                        setState(() => _asterankLimit = n);
                        if (_onlineMode) _enrichBatch(_filtered);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grid + infinite scroll
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (sn) {
                if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 200) {
                  setState(() {
                    _visibleCount =
                        (_visibleCount + _pageSize).clamp(0, _filtered.length);
                  });
                }
                return false;
              },
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: aspectRatio,
                ),
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final asteroid = items[index];

                  // On-demand enrichment when visible (only in online mode)
                  if (_onlineMode && !_hasAnyAsterank(asteroid)) {
                    _fetchAndAttachAsterank(asteroid);
                  }

                  final isLoadingAsterank = _onlineMode &&
                      _enriching.contains(asteroid.id) &&
                      !_hasAnyAsterank(asteroid);

                  return AsteroidCard(
                    a: asteroid,
                    dangerLevel: getDangerLevel,
                    isLoadingAsterank: isLoadingAsterank,
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration:
                          const Duration(milliseconds: 350),
                          reverseTransitionDuration:
                          const Duration(milliseconds: 250),
                          pageBuilder: (_, animation, __) =>
                              AsteroidDetailsPage(asteroid: asteroid),
                          transitionsBuilder: (_, animation, __, child) {
                            final curved = CurvedAnimation(
                                parent: animation, curve: Curves.easeOutCubic);
                            return FadeTransition(
                              opacity: curved,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.98, end: 1.0)
                                    .animate(curved),
                                child: child,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
