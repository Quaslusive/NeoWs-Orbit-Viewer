import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neows_app/env/env.dart';
import 'package:neows_app/neows/asteroid_model.dart';
import 'package:neows_app/neows/asteroid_repository.dart';
import 'package:neows_app/neows/asteroid_controller.dart';
import 'package:neows_app/widget/asteroid_card.dart';
import 'package:neows_app/neows/neows_service.dart';

class AsteroidSearchPage extends StatefulWidget {
  const AsteroidSearchPage({
    super.key,
    this.pickMode = false,
    this.onPick,
    this.controller,
    this.repo,
  });

  final bool pickMode;
  final ValueChanged<Asteroid>? onPick;

  final AsteroidController? controller;
  final AsteroidRepository? repo;

  @override
  State<AsteroidSearchPage> createState() => _AsteroidSearchPageState();
}

class _AsteroidSearchPageState extends State<AsteroidSearchPage> {
  late final AsteroidRepository _repo;

  String _query = '';
  bool _hazardOnly = false;
  int _limit = 500;

  bool _loading = false;
  List<Asteroid> _results = [];
  Timer? _debounce;

  final Map<String, double?> _orbitA = {}; // neoId -> a (AU)
  final Map<String, double?> _orbitE = {}; // neoId -> e
  final Set<String> _orbitLoading = {};    // ids currently fetching
  int _reqId = 0;                          // cancel stale searches

  @override
  void initState() {
    super.initState();

    if (widget.repo != null) {
      _repo = widget.repo!;
    } else if (widget.controller != null) {
      _repo = widget.controller!.repo;
    } else {
      final neoService = NeoWsService(apiKey: Env.nasaApiKey);
      _repo = AsteroidRepository(neoService);
    }
    _dispatchSearch(currentTerm: '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTapAsteroid(Asteroid a) {
    if (widget.pickMode) {
      widget.onPick?.call(a);
      Navigator.of(context).maybePop<Asteroid>(a);
      return;
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = q.trim());
      _dispatchSearch(currentTerm: _query);
    });
  }

  void _ensureOrbitLoaded(Asteroid ast) {
    final id = ast.id;
    if (_orbitA.containsKey(id) ||
        _orbitE.containsKey(id) ||
        _orbitLoading.contains(id)) {
      return;
    }

    _orbitLoading.add(id);
    _repo.getOrbit(id).then((el) {
      if (!mounted) return;
      setState(() {

        _orbitA[id] = el.a;
        _orbitE[id] = el.e;
        _orbitLoading.remove(id);
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _orbitLoading.remove(id));
    });
  }

  Future<void> _dispatchSearch({required String currentTerm}) async {
    final int ticket = ++_reqId;
    setState(() => _loading = true);

    try {
      final term = currentTerm;
      final lim = _limit.clamp(10, 1000);
      List<Asteroid> out;

      if (term.isEmpty) {
        final now = DateTime.now();
        out = await _repo.feedRange(now, now.add(const Duration(days: 6)), lim);
      } else {
        out = await _repo.search(term, limit: lim);
      }

      if (_hazardOnly) {
        out = out.where((a) => a.isPha == true).toList();
      }

      if (!mounted || ticket != _reqId) return;
      setState(() {
        _results = out;
      });
    } catch (e) {
      if (!mounted || ticket != _reqId) return;
      debugPrint('Search error: $e');
      setState(() => _results = []);
    } finally {
      if (!mounted || ticket != _reqId) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search asteroids'),
        actions: [
          if (widget.pickMode)
            IconButton(
              tooltip: 'close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or SPK-ID',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: SwitchListTile(
              title: const Text('Show only potentially hazardous (PHA)'),
              value: _hazardOnly,
              onChanged: (v) {
                setState(() => _hazardOnly = v);
                _dispatchSearch(currentTerm: _query);
              },
              dense: true,
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(left: 12, right: 12, bottom: 6),
              child: LinearProgressIndicator(),
            ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: _results.isEmpty && !_loading
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No matches'),
              ),
            )
                : GridView.builder(
              itemCount: _results.length,
              padding: const EdgeInsets.all(8),
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final asteroid = _results[index];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _ensureOrbitLoaded(asteroid);
                });
                return AsteroidCard(
                  key: ValueKey(asteroid.id),
                  a: asteroid,
                  orbitA: _orbitA[asteroid.id],
                  orbitE: _orbitE[asteroid.id],
                  isOrbitLoading:
                  _orbitLoading.contains(asteroid.id),
                  onTap: () => _onTapAsteroid(asteroid),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<Asteroid?> pickAsteroid(
    BuildContext context, {
      AsteroidController? controller,
      AsteroidRepository? repo,
    }) {
  return showModalBottomSheet<Asteroid>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AsteroidSearchPage(
      pickMode: true,
      controller: controller,
      repo: repo,
    ),
  );
}
