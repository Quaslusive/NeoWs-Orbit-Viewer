import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show compute;

import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/pages/asteroid_details_page.dart';
import 'package:neows_app/widget/asteroid_card.dart';

// ✅ Use MPC service + mapper
import 'package:neows_app/service/asterank_api_service.dart';
import 'package:neows_app/service/asterank_mpc_mapper.dart';

// --- CSV parsing (background) ---
List<List<dynamic>> _parseCsv(String raw) =>
    const CsvToListConverter(eol: '\n').convert(raw);

class AsteroidSearchPage extends StatefulWidget {
  const AsteroidSearchPage({super.key});
  @override
  State<AsteroidSearchPage> createState() => _AsteroidSearchPageState();
}

class _AsteroidSearchPageState extends State<AsteroidSearchPage> {
  // ✅ MPC service with dev logs enabled
  final AsterankApiService _mpc = AsterankApiService(enableLogs: true);

  // Data
  List<Asteroid> _csvAsteroids = []; // offline fallback
  List<Asteroid> _filtered = [];

  // Modes & limits
  bool _onlineMode = true; // API search when true
  int _csvLimit = 50;      // rows to load from CSV

  // UI state
  bool _loading = false;
  Timer? _debounce;

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    _initialLoad(); // seed list (API or CSV)
    _loadCsv();     // prepare offline cache
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ---------- CSV load (fallback) ----------
  Future<void> _loadCsv() async {
    try {
      final raw = await rootBundle.loadString('lib/assets/astroidReadTest.csv');
      final csv = await compute(_parseCsv, raw);

      final list = <Asteroid>[];
      for (int i = 1; i < csv.length && i <= _csvLimit; i++) {
        final row = csv[i];
        list.add(
          Asteroid(
            id: (row[0] ?? '').toString(),
            name: (row[4] ?? '').toString(),
            fullName: (row[2] ?? '').toString(),
            diameter: double.tryParse(row[15].toString()) ?? 0.0,
            albedo: double.tryParse(row[17].toString()) ?? 0.0,
            neo: (row[6] ?? '').toString(),
            pha: (row[7] ?? '').toString(),
            rotationPeriod: double.tryParse(row[18].toString()) ?? 0.0,
            classType: (row[60] ?? '').toString(),
            orbitId: int.tryParse(row[27].toString()) ?? 0,
            moid: double.tryParse(row[45].toString()) ?? 0.0,
            a: double.tryParse(row[33].toString()) ?? 0.0,
            e: double.tryParse(row[32].toString()) ?? 0.0,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _csvAsteroids = list);
    } catch (_) {
      // ignore CSV errors; API mode still works
    }
  }

  // ---------- Initial load ----------
  Future<void> _initialLoad() async {
    setState(() => _loading = true);
    try {
      if (_onlineMode) {
        // ✅ use MPC service
        final rows = await _mpc.fetchTop(limit: 50);
        setState(() => _filtered = rows.map(asteroidFromMpc).toList());
      } else {
        await _loadCsv();
        setState(() => _filtered = _csvAsteroids.take(50).toList());
      }
    } catch (e) {
      debugPrint('Initial load failed: $e');
      try {
        await _loadCsv();
        setState(() => _filtered = _csvAsteroids.take(50).toList());
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Search ----------
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final term = q.trim();
      if (term.isEmpty) {
        setState(() => _filtered = []);
        return;
      }

      if (_onlineMode) {
        try {
          setState(() => _loading = true);
          // ✅ call MPC search + map
          final rows = await _mpc.searchMany(term, limit: 50);
          setState(() {
            _filtered = rows.map(asteroidFromMpc).toList();
            _loading = false;
          });
        } catch (e) {
          setState(() => _loading = false);
          debugPrint('MPC search error: $e');
        }
      } else {
        // CSV fallback
        final needle = term.toLowerCase();
        final items = _csvAsteroids.where((a) =>
        a.name.toLowerCase().contains(needle) ||
            a.fullName.toLowerCase().contains(needle)
        ).toList();
        setState(() => _filtered = items);
      }
    });
  } // ← make sure this brace closes _onSearchChanged

  // ---------- Danger label ----------
  String getDangerLevel(Asteroid a) {
    final isPha = a.pha.toUpperCase() == 'Y';
    final moidRisk = a.moid < 0.05;       // au
    final bigEnough = a.diameter >= 0.14; // km (~140m)
    if ((isPha || moidRisk) && bigEnough) return 'Extreme Danger 🔥🔥🔥';
    if (isPha || moidRisk) return 'Moderate Risk ⚠️';
    return 'Safe ✅';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sök efter Asteroids')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Sök asteroid namn'),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: SwitchListTile.adaptive(
                    dense: true,
                    title: Text(
                      _onlineMode ? 'Online (API search: MPC)' : 'Offline (CSV only)',
                    ),
                    value: _onlineMode,
                    onChanged: (v) => setState(() => _onlineMode = v),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('CSV'),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: _csvLimit,
                      items: const [10, 25, 50, 100, 200]
                          .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                          .toList(),
                      onChanged: (n) async {
                        if (n == null) return;
                        setState(() => _csvLimit = n);
                        await _loadCsv();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: _filtered.isEmpty && !_loading
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _onlineMode
                      ? 'No asteroids found via MPC.\nTry another search or switch to CSV.'
                      : 'No CSV data loaded.\nCheck assets path or switch to MPC.',
                  textAlign: TextAlign.center,
                ),
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
                return AsteroidCard(
                  a: asteroid,
                  dangerLevel: getDangerLevel,
                  isLoadingAsterank: false,
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
