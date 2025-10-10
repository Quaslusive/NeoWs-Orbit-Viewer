import 'package:flutter/material.dart';
import 'package:neows_app/service/neoWs_service.dart';
import 'package:neows_app/utils/planet_objects.dart';
import 'package:neows_app/widget/asteroid_web_sheet.dart';
import 'package:neows_app/model/neo_models.dart';
import 'package:neows_app/widget/orbit_3d_canvas.dart';

class TodayOrbits3DPageSoft extends StatefulWidget {
  const TodayOrbits3DPageSoft({super.key, required this.apiKey});

  final String apiKey;

  @override
  State<TodayOrbits3DPageSoft> createState() => _TodayOrbits3DPageSoftState();
}

class _TodayOrbits3DPageSoftState extends State<TodayOrbits3DPageSoft> {
  late final NeoWsService _neo = NeoWsService(apiKey: widget.apiKey);
  final _items = <Orbit3DItem>[];
  final _cache = <String, OrbitElements>{};
  double _speed = 5.0;
  bool _paused = false;
  bool _loading = true;
  String? _err;

  int _resetTick = 0; // bump to trigger canvas reset
  double _elapsedDays = 0; // shown in the UI

  @override
  void initState() {
    super.initState();
    _load();
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
      backgroundColor: Colors.black87,
      builder: (_) => _DetailsSheet3D(item: it),
    );
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
      // TODO I might take appBar away
      appBar: AppBar(
        title: const Text('NEO 3D Orbits '),
        titleTextStyle: TextStyle(
          color: Colors.yellow,
          fontFamily: 'EVA-Matisse',
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.yellowAccent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Orbit3DCanvas(
              items: _items,
              onSelect: _openDetails3D,
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
          // Legend (optional)
          Positioned(
            left: 12,
            bottom: 72,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text(
                  'Pinch = zoom • Drag = orbit camera • Tap a dot',
                  style: TextStyle(color: Colors.white70)),
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
                color: Colors.black87,
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
                            color: Colors.white),
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
                        backgroundColor: Colors.white10,
                        labelStyle: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w700),
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
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36)),
                        onPressed: () => setState(() {
                          _resetTick++;
                          _elapsedDays = 0;
                        }),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Δt: ${_elapsedDays.toStringAsFixed(1)} d',
                      style: const TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w600),
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
        foregroundColor: Colors.white,
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

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;

  const _Swatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Semantics(
        label: '$label color',
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}

class _DetailsSheet3D extends StatelessWidget {
  const _DetailsSheet3D({required this.item});

  final Orbit3DItem item;

  @override
  Widget build(BuildContext context) {
    final n = item.neo;
    final el = item.el;
    final name = item.neo.name;

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
        backgroundColor: Colors.transparent,
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
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _openInApp(SourceTab.jpl),
              icon: const Icon(Icons.science_outlined),
              label: const Text('JPL '),
            ),
            ElevatedButton.icon(
              onPressed: () => _openInApp(SourceTab.spaceRef),
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('SpaceReference '),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _openInApp(SourceTab.mpc),
              icon: const Icon(Icons.public),
              label: const Text('MPC '),
            ),
          ],
        ));
  }
}
