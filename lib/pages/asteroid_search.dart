import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neows_app/db/app_db.dart';
import 'package:neows_app/db/csv_import.dart';

import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/pages/asteroid_details_page.dart';
import 'package:neows_app/widget/asteroid_card.dart';
import 'package:neows_app/service/asterank_api_service.dart';


class AsteroidSearchPage extends StatefulWidget {
  const AsteroidSearchPage({super.key});

  @override
  State<AsteroidSearchPage> createState() => _AsteroidSearchPageState();
}

class _AsteroidSearchPageState extends State<AsteroidSearchPage> {
  final AsterankApiService _asterank = AsterankApiService();
  final Set<String> _enriching = {};

  List<Asteroid> _asteroids = [];
  List<Asteroid> _filtered = [];

  // Online/Offline + limits
  bool _onlineMode = true; // Online by default
  int _asterankLimit = 50; // how many to enrich
  int _csvLimit = 50; // how many CSV rows to load

  late final AppDb _db;
  int _offset = 0;
  late int _pageSize = 50;
  List<Asteroid> _items = [];
  bool _loadingPage = false;
  String _query = '';

  // Paging for UI
  int _visibleCount = 50;

  // Search debounce (optional but nice)
  Timer? _debounce;
  String _search = '';

  bool _hasAnyAsterank(Asteroid a) =>
      a.asterankPriceUsd != null ||
      a.asterankAlbedo != null ||
      a.asterankDiameterKm != null ||
      a.asterankDensity != null ||
      (a.asterankSpec?.isNotEmpty == true);

  @override
  void initState() {
    super.initState();
    _db = AppDb();
    _initDb();
  }

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
      setState(() => a.applyAsterank(info));
    } finally {
      if (mounted) setState(() => _enriching.remove(a.id));
    }
  }

  Future<void> _initDb() async {
    await importCsvIfEmpty(_db); // one-time import
    await _loadFirstPage(); // initial page
  }

  Future<void> _loadFirstPage() async {
    _offset = 0;
    _items =
        await _db.searchPaged(limit: _pageSize, offset: _offset, query: _query);
    setState(() {});
    if (_onlineMode) _enrichBatch(_items);
  }

  Future<void> _loadNextPage() async {
    if (_loadingPage) return;
    _loadingPage = true;
    _offset += _pageSize;
    final next =
        await _db.searchPaged(limit: _pageSize, offset: _offset, query: _query);
    _items.addAll(next);
    _loadingPage = false;
    setState(() {});
    if (_onlineMode) _enrichBatch(next);
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _query = q.trim();
      _loadFirstPage(); // resets paging and re-queries DB
    });
  }

  void _filterAsteroids(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _search = query;
        final q = query.toLowerCase();
        _filtered = _asteroids.where((a) {
          final n = (a.name ?? '').toLowerCase();
          final fn = (a.fullName ?? '').toLowerCase();
          return n.contains(q) || fn.contains(q);
        }).toList();
        _visibleCount = _pageSize; // reset paging for new results
      });
      if (_onlineMode) _enrichBatch(_filtered);
    });
  }

  // PHA heuristic
  String getDangerLevel(Asteroid a) {
    final isPha = a.pha.toUpperCase() == 'Y';
    final moidRisk = a.moid < 0.05;
    final bigEnough = a.diameter >= 0.14; // km ≈ 140 m
    if ((isPha || moidRisk) && bigEnough) {
      return 'Extreme Danger 🔥🔥🔥';
    } else if (isPha || moidRisk) {
      return 'Moderate Risk ⚠️';
    } else {
      return 'Safe ✅';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final aspectRatio = isSmallScreen ? 0.8 : 0.9;

    return Scaffold(
      appBar: AppBar(title: const Text("Sök efter Asteroids")),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Sök asteroid namn'),
              onChanged: _onSearchChanged,
            ),
          ),

          // Controls: Online/Offline + Limits
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Online/Offline toggle
                Expanded(
                  child: SwitchListTile.adaptive(
                    dense: true,
                    title: Text(_onlineMode
                        ? 'Online (API enabled)'
                        : 'Offline (CSV only)'),
                    value: _onlineMode,
                    onChanged: (v) {
                      setState(() => _onlineMode = v);
                      if (_onlineMode) {
                        _enrichBatch(_filtered);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // CSV page size
                DropdownButton<int>(
                  value: _pageSize,
                  items: const [25, 50, 100, 200].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                  onChanged: (n) async {
                    if (n == null) return;
                    setState(() => _pageSize = n);
                    await _loadFirstPage();
                  },
                ),

// API enrichment limit
                DropdownButton<int>(
                  value: _asterankLimit,
                  items: const [10, 25, 50, 100, 200].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                  onChanged: (n) {
                    if (n == null) return;
                    setState(() => _asterankLimit = n);
                    if (_onlineMode) _enrichBatch(_items);
                  },
                ),

              ],
            ),
          ),

          // Grid with infinite scroll
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (sn) {
                if (sn.metrics.pixels >= sn.metrics.maxScrollExtent - 200) {
                  _loadNextPage(); // fetch next page from DB
                }
                return false;
              },
              child: GridView.builder(
                itemCount: _items.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: aspectRatio,
                ),
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final asteroid = _items[index];

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
                          transitionDuration: const Duration(milliseconds: 350),
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
