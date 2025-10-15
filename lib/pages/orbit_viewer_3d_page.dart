import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neows_app/mappers/asteroid_mappers.dart';
import 'package:neows_app/pages/asteroid_search.dart';
import 'package:neows_app/service/neoWs_service.dart';
import 'package:neows_app/utils/planet_objects.dart';
import 'package:neows_app/widget/asteroid_web_sheet.dart';
import 'package:neows_app/widget/orbit_3d_canvas.dart';
import 'package:neows_app/model/neo_models.dart' show NeoLite, OrbitElements;


class OrbitViewer3DPage extends StatefulWidget {
  const OrbitViewer3DPage({super.key, required this.apiKey});
  final String apiKey;

  @override
  State<OrbitViewer3DPage> createState() => _OrbitViewer3DPageState();
}

class _OrbitViewer3DPageState extends State<OrbitViewer3DPage> {
  late final NeoWsService _neo = NeoWsService(apiKey: widget.apiKey);
  final _canvasKey = GlobalKey<Orbit3DCanvasState>();
  final _items = <Orbit3DItem>[];
  final _cache = <String, OrbitElements>{};
  double _speed = 5.0;
  bool _paused = false;
  bool _loading = true;
  String? _err;

  int _resetTick = 0; // bump to trigger canvas reset
  double _elapsedDays = 0; // shown in the UI

  String? _focusId;
  String? _centerNotice;
  Timer? _noticeTimer;

  final _ids = <String>{}; // track which IDs are already in _items

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showCenterNotice(String text) {
    setState(() => _centerNotice = text);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _centerNotice = null);
    });
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final feed = await _neo.getTodayFeed();
      final list = feed.map(NeoLite.fromFeed).toList();

      // Fetch with limited concurrency
      const maxC = 4;
      for (int i = 0; i < list.length; i += maxC) {
        final batch =
            list.sublist(i, (i + maxC < list.length) ? i + maxC : list.length);
        await Future.wait(batch.map((n) async {
          final el = OrbitElements.fromNeo(await _neo.getNeoById(n.id));
          _cache[n.id] = el;
          _items.add(Orbit3DItem(
            neo: n,
            el: el,
            color: n.isHazardous ? Colors.redAccent : Colors.cyanAccent,
          ));
        }));
        setState(() {}); // progressive paint
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  void _openDetails3D(Orbit3DItem it) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      enableDrag: true,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _DetailsSheet3D(item: it),
    );
  }

  Future<void> _addPickedAsteroid() async {
    final picked = await pickAsteroid(context); // returns Asteroid from the search page
    if (picked == null) return;

    final neoLite = picked.toNeoLite(); // <-- map once

    // Avoid duplicates fast
    if (!_ids.add(neoLite.id)) {
      // Already present — focus and toast instead of adding again
      _focusId = neoLite.id;
      _showCenterNotice('${neoLite.name} (redan tillagd)');
      setState(() {}); // re-render to apply focus/notice
      return;
    }

    try {
      setState(() => _loading = true);

      // OrbitElements cache (radian model)
      final el = _cache[neoLite.id] ??
          OrbitElements.fromNeo(await _neo.getNeoById(neoLite.id));
      _cache[neoLite.id] = el;

      // Choose color once; store in the hot path
      final color = neoLite.isHazardous ? Colors.redAccent : Colors.cyanAccent;

      _items.add(Orbit3DItem(neo: neoLite, el: el, color: color));

// request selection + optional toast
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _canvasKey.currentState?.selectById(neoLite.id);
      });
      _showCenterNotice(neoLite.name);

      setState(() => _loading = false);

    } catch (e) {
      // rollback ID set if fetch failed
      _ids.remove(neoLite.id);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte lägga till: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_err != null) {
      return Scaffold(body: Center(child: Text('Error: $_err')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor:  Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'NEO 3D Orbits',
          style: TextStyle(
            fontFamily: 'EVA-Matisse_Standard',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      drawer: Drawer(
        elevation: 100,
       // shadowColor: Colors.black54,
        child: Column(
          children: [
            DrawerHeader(
              child: Image.asset(
                "lib/assets/images/icon/icon1.png",
                width: 100,
                height: 100,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/orbit_viewer_3d_page");
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text("Sök Asteroider med NeoWs och Asterank"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/asteroid_search");
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper),
              title: const Text("News"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/news");
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("Acknowledgements"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/acknowledgements_page");
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/settings_page");
              },
            ),
            ListTile(
              leading: const Icon(Icons.rocket),
              title: const Text("Asteroid Sida"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/asteroid_page");
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Orbit3DCanvas(
              key: _canvasKey,
              items: _items,
           //   requestSelectId: _focusId,
              onSelect: _openDetails3D,
              onLongPressItem: (it) {
                setState(() {
                  _items.removeWhere((x) => x.neo.id == it.neo.id);
                  _cache.remove(it.neo.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tog bort ${it.neo.name}')),
                );
              },
              simDaysPerSec: _speed,
              paused: _paused,
              planets: innerPlanets,
              showStars: true,
              starCount: 900,
              // Axis + grid controls:
              showAxes: true,
              showGrid: true,
              gridSpacingAu: 1,
              // try 0.2 for denser
              gridExtentAu: 30.0,
              // increase to 5–10 to see more
              axisXColor: const Color(0xFFFF6B6B),
              axisYColor: const Color(0xFF6BFF8A),
              gridColor: const Color(0x33FFFFFF),
              // inclination effect
              showShadowPinsAndNodes: true,
              orbitShadowOpacity: 0.38,
              pinEveryN: 1,
              pinAboveColor: const Color(0xFF4CAF50),
              pinBelowColor: const Color(0xFFE57373),
              nodeAscColor: const Color(0xFF7CFC00),
              nodeDescColor: const Color(0xFFFF6B6B),
              nodeRipplePeriodMs: 2400,
              nodeRippleMaxRadiusPx: 24,

              resetTick: _resetTick,
              // bump to reset sim
              onSimDaysChanged: (d) {
                // report Δt up
                if (mounted) setState(() => _elapsedDays = d);
              },
            ),
          ),

          // center toast
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _centerNotice == null ? 0 : 1,
                child: Center(
                  child: _centerNotice == null
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.onSurface
                            ),
                          ),
                          child: Text(
                            _centerNotice!,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Controls overlay
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _paused = !_paused),
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause,
                          color: Theme.of(context).colorScheme.onSurface,),
                        tooltip: _paused ? 'Play' : 'Pause',
                      ),
                      _SpeedBtn(
                          label: '-20',
                          onTap: () => setState(
                              () => _speed = (_speed - 20).clamp(0, 200))),
                      _SpeedBtn(
                          label: '-1',
                          onTap: () => setState(
                              () => _speed = (_speed - 1).clamp(0, 200))),
                      Chip(
                        label: Text('${_speed.toStringAsFixed(0)} d/s'),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        visualDensity: VisualDensity.compact,
                      ),
                      _SpeedBtn(
                          label: '+1',
                          onTap: () => setState(
                              () => _speed = (_speed + 1).clamp(0, 200))),
                      _SpeedBtn(
                          label: '+20',
                          onTap: () => setState(
                              () => _speed = (_speed + 20).clamp(0, 200))),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _addPickedAsteroid,
                        icon: const Icon(Icons.search),
                        label: const Text('Lägg till asteroid'),
                      ),
                      // TODO Fixa restet days Snart
                  /*    OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36)),
                        onPressed: () => setState(() {
                          _resetTick++;
                          _elapsedDays = 0;
                        }),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),*/
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Δt: ${_elapsedDays.toStringAsFixed(1)} d',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedBtn extends StatelessWidget {
  const _SpeedBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor:  Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _DetailsSheet3D extends StatelessWidget {
  const _DetailsSheet3D({required this.item});

  final Orbit3DItem item;

  @override
  Widget build(BuildContext context) {
    final n = item.neo;
    final el = item.el; // TODO Need this?
    final name = item.neo.name;
 // TODO fix net code:202
    final jplUrl = Uri.parse(
        'https://ssd.jpl.nasa.gov/tools/sbdb_lookup.html#/?sstr=${n.id}');
    final mpcUrl = Uri.parse(
        'https://minorplanetcenter.net/db_search/show_object?object_id=${Uri.encodeComponent(name)}');

    String _slug(String s) => s
        .replaceAll(RegExp(r'[()\[\],]'), '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-');

    final spaceRefUrl =
        Uri.parse('https://www.spacereference.org/asteroid/${_slug(name)}');

    void _openInApp(SourceTab initial) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        // WebView owns vertical scroll
        backgroundColor:Theme.of(context).colorScheme.onSurface,
        builder: (_) => SpaceRefWebSheet(
          title: name,
          initialSource: initial,
          // which one to show first
          spaceRefUrl: spaceRefUrl,
          jplUrl: jplUrl,
          mpcUrl: mpcUrl,
          siteSearchFallbackQuery: name, // SpaceRef slug fallback
        ),
      );
    }

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 5),
            // or ElevatedButton
            OutlinedButton.icon(
              onPressed: () => _openInApp(SourceTab.jpl),
              icon: const Icon(Icons.science_outlined),
              label: const Text('JPL'),
            ),
            const SizedBox(width: 5),
            OutlinedButton.icon(
              onPressed: () => _openInApp(SourceTab.spaceRef),
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('SpaceReference'),
            ),
            const SizedBox(width: 5),
            OutlinedButton.icon(
              onPressed: () => _openInApp(SourceTab.mpc),
              icon: const Icon(Icons.public),
              label: const Text('MPC'),
            ),
          ],
        ));
  }
}
