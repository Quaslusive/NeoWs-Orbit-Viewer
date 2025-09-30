import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neows_app/service/neoWs_service.dart';

import 'package:neows_app/utils/planet_models.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/neo_models.dart';

import '../widget/orbit_3d_canvas.dart';

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

  int _resetTick = 0;      // bump to trigger canvas reset
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

  void _openDetails3D(Orbit3DItem  it) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      appBar: AppBar(title: const Text('NEO 3D Orbits – Today (Flutter)' )),
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
              gridSpacingAu: 1,   // try 0.2 for denser
              gridExtentAu: 30.0,    // increase to 5–10 to see more
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
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text(
                  'Pinch = zoom • Drag = orbit camera • Tap a dot',
                  style: TextStyle(color: Colors.white70)),
            ),
          ),

          // Controls overlay
          Positioned(
            left: 12, right: 12, bottom: 12,
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
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                        tooltip: _paused ? 'Play' : 'Pause',
                      ),
                      _SpeedBtn(label: '-20', onTap: () => setState(() => _speed = (_speed - 20).clamp(0, 200))),
                      _SpeedBtn(label: '-1',  onTap: () => setState(() => _speed = (_speed - 1).clamp(0, 200))),
                      Chip(
                        label: Text('${_speed.toStringAsFixed(0)} d/s'),
                        backgroundColor: Colors.white10,
                        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                        visualDensity: VisualDensity.compact,
                      ),
                      _SpeedBtn(label: '+1',  onTap: () => setState(() => _speed = (_speed + 1).clamp(0, 200))),
                      _SpeedBtn(label: '+20', onTap: () => setState(() => _speed = (_speed + 20).clamp(0, 200))),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(0, 36)),
                        onPressed: () => setState(() { _resetTick++; _elapsedDays = 0; }),
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
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
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
  const _DetailsSheet3D({ required this.item});
  final Orbit3DItem item;

  @override
  Widget build(BuildContext context) {
    final n = item.neo;
    final el = item.el;

    final jplUrl = Uri.parse('https://ssd.jpl.nasa.gov/tools/sbdb_lookup.html#/?sstr=${n.id}');
    final mpcUrl = Uri.parse('https://minorplanetcenter.net/db_search/show_object?object_id=${Uri.encodeComponent(n.name)}');
    final wikiUrl = Uri.parse('https://en.wikipedia.org/w/index.php?search=${Uri.encodeComponent(n.name)}');

    Future<void> _go(Uri u) async {
      final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open ${u.host}')));
      }
    }

    double _heliocentricRAu({
      required double a,
      required double e,
      required double M0deg,
      required DateTime epochUtc,
      DateTime? tUtc,
    }) {
      tUtc ??= DateTime.now().toUtc();
      const kGauss = 0.01720209895; // rad/day
      double meanMotion(double aAu) => kGauss / math.pow(aAu, 1.5);

      double toRad(double d) => d * math.pi / 180.0;

      double solveE(double M, double e) {
        double E = M;
        for (int i = 0; i < 12; i++) {
          final f = E - e * math.sin(E) - M;
          final fp = 1 - e * math.cos(E);
          E -= f / fp;
        }
        return E;
      }

      final dtDays = tUtc.difference(epochUtc).inMilliseconds / 86400000.0;
      final M = toRad(M0deg) + meanMotion(a) * dtDays;
      final E = solveE(M, e);
      final r = a * (1 - e * e) / (1 + e * math.cos(E)); // AU
      return r;
    }
    final rNow = _heliocentricRAu(
      a: el.a, e: el.e, M0deg: el.M, epochUtc: el.epoch,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with hazard chip + copy button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SelectableText(
                      n.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (n.isHazardous)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Text('PHA', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    ),
                  IconButton(
                    tooltip: 'Copy NEO ID',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: n.id));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NEO ID copied')));
                      }
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _KV('Hazard', n.isHazardous ? 'Potentially' : 'No'),
                  _KV('a (AU)', el.a.toStringAsFixed(3)),
                  _KV('e', el.e.toStringAsFixed(3)),
                  _KV('i (°)', el.i.toStringAsFixed(2)),
                  _KV('ω (°)', el.omega.toStringAsFixed(2)),
                  _KV('Ω (°)', el.Omega.toStringAsFixed(2)),
                  _KV('r now (AU)', rNow.toStringAsFixed(3)),        // NEW
                  _KV('Epoch (UTC)', el.epoch.toIso8601String()),    // NEW
                ],
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _go(jplUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('JPL SBDB'),
                  ),
                  OutlinedButton(
                    onPressed: () => _go(mpcUrl),
                    child: const Text('MPC DB'),
                  ),
                  OutlinedButton(
                    onPressed: () => _go(wikiUrl),
                    child: const Text('Wikipedia'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k, v;
  const _KV(this.k, this.v);
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$k: ', style: base),
      SelectableText(v, style: base.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}