import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neows_app/neows/asteroid_mappers.dart';
import 'package:neows_app/pages/asteroid_search_page.dart';
import 'package:neows_app/neows/neows_service.dart';
import 'package:neows_app/neows/asteroid_controller.dart';
import 'package:neows_app/settings/settings_controller.dart';
import 'package:neows_app/canvas/planet_objects.dart';
import 'package:neows_app/space_reference_web/space_ref_sheet.dart';
import 'package:neows_app/canvas/orbit_3d_canvas.dart';
import 'package:neows_app/neows/neo_models.dart' show OrbitElements;
import 'package:neows_app/neows/asteroid_repository.dart';
import 'package:neows_app/quick_add/quick_add_sheet.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:neows_app/quick_add/quick_add_action.dart';
import 'package:neows_app/widget/side_menu.dart';


class OrbitViewer3DPage extends StatefulWidget {
  final String apiKey;
  final SettingsController controller;

  const OrbitViewer3DPage({
    super.key,
    required this.apiKey,
    required this.controller,
  });

  @override
  State<OrbitViewer3DPage> createState() => _OrbitViewer3DPageState();
}

class _OrbitViewer3DPageState extends State<OrbitViewer3DPage> {
  late final NeoWsService _neo = NeoWsService(apiKey: widget.apiKey);
  late final AsteroidRepository _repo = AsteroidRepository(_neo);
  late final AsteroidController _ctrl;
  final _canvasKey = GlobalKey<Orbit3DCanvasState>();
  final _items = <Orbit3DItem>[];
  final _cache = <String, OrbitElements>{};
  double _speed = 5.0;
  bool _paused = false;
  bool _loading = false;
  String? _err;
  double _elapsedDays = 0; // shown in the UI
  String? _focusId;
  String? _centerNotice;
  Timer? _noticeTimer;

  Orbit3DItem? _selectedItem;
 // String? _appVersion;

  // control state
  double _minDist = 2.0;
  double _maxDist = 50.0;

  final _ids = <String>{}; // track which IDs are already in _items
 // final Set<String> _shownAsteroidIds = <String>{};
  bool _busy = false;

  String _simDateString() {
    final base = DateTime.now();
    final ms = (_elapsedDays * 24 * 60 * 60 * 1000).round();
    final d = base.add(Duration(milliseconds: ms));
    String two(int x) => x.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AsteroidController(
      repo: _repo,
      ids: _ids,
      onNotice: _showCenterNotice,
      addItem: (it) {
        _items.add(it);
        // auto select
        /*   if (mounted) setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _canvasKey.currentState?.selectedId(it.neo.id);
        });*/
      },
      setBusy: (b) {
        if (!mounted) return;
        setState(() => _busy = b);
      },
    );
    _initPlanetsOnly();
    //_loadAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canvasKey.currentState?.resetSimulation();
    });
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

  void _initPlanetsOnly() {
    _items.clear();
    _ids.clear();
    _cache.clear();
    _elapsedDays = 0;
    _err = null;
    _loading = false;
  }

  void _openQuickAddSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => QuickAddSheet(onPick: _handleQuickAdd),
    );
  }

  Future<void> _handleQuickAdd(QuickAddAction a) async {
    switch (a) {
      case QuickAddAction.addRandom:
        return _ctrl.addRandom();
      case QuickAddAction.todayAll:
        return _ctrl.addTodayAll();
      case QuickAddAction.addAllHazardous:
        return _ctrl.addAllHazardous(max: 100);
      case QuickAddAction.addAllAsteroids:
        return _ctrl.addAllKnown(max: 100);
    }
  }

/*  Future<Asteroid?> pickAsteroid(BuildContext context) {
    return showModalBottomSheet<Asteroid>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AsteroidSearchPage(pickMode: true),
    );
  }*/

  Future<void> _addPickedAsteroid() async {
    final picked = await pickAsteroid(context);
    if (picked == null) return;

    final neoLite = picked.toNeoLite();

    if (!_ids.add(neoLite.id)) {
      _focusId = neoLite.id;
      _showCenterNotice('${neoLite.name} already added');
      setState(() {});
      return;
    }
    try {
      setState(() => _loading = true);
      final el = await _repo.getOrbit(neoLite.id);
      final color = neoLite.isHazardous ? Colors.redAccent : Colors.cyanAccent;
      _items.add(Orbit3DItem(neo: neoLite, el: el, color: color));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _canvasKey.currentState?.selectedId(neoLite.id);
      });
      _showCenterNotice(neoLite.name);
    } catch (e) {
      _ids.remove(neoLite.id);
      _showCenterNotice(
        'Could not add: $e',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset3DOrbitViewer() {
    _items.removeWhere((it) => it.neo != null);
    _ids.clear();
    _cache.clear();
    _repo.clearCaches();
    _elapsedDays = 0;
    setState(() {});
    _canvasKey.currentState?.resetSimulation();
    _showCenterNotice('Restored');
  }

  // todo [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception:
/*
  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = null);
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.state;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_err != null) {
      return Scaffold(body: Center(child: Text('Error: $_err')));
    }

    return Scaffold(
        appBar: AppBar(
      //    backgroundColor: Colors.transparent,
          //  backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: const Text(
            'NeoWS Orbit Viewer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        drawer: SideMenu(
          controller: widget.controller,
        //  appVersion: _appVersion,
          onGoHomePage: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/orbit_viewer_3d_page");
          },
    /*      onGoSearch: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/asteroid_search");
          },*/
          onGoCredits: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/acknowledgements_page");
          },
     /*     onGoSettings: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/settings_page");
          },*/
        ),
        body: Stack(children: [
          Positioned.fill(
            child: Orbit3DCanvas(
              key: _canvasKey,
              items: _items,
              onSelect: (it) => setState(() => _selectedItem = it),
              onTapBackground: () => setState(() => _selectedItem = null),
              simDaysPerSec: _speed,
              paused: _paused,
              planets: innerPlanets,
              showStars: true,
              starCount: 900,
              invertY: s.invertY,
              showAxes: s.showAxes,
              showGrid: s.showGrid,
              showOrbits: s.showOrbits,
              rotateSensitivity: s.rotateSens,
              zoomSensitivity: s.zoomSens,
              minDistance: _minDist,
              maxDistance: _maxDist,
              gridSpacingAu: 1, // try 0.2 for denser
              gridExtentAu: 30.0,  // increase to 5–10 to see more
              axisXColor: const Color(0xFFFF6B6B),
              axisYColor: const Color(0xFF6BFF8A),
              gridColor: const Color(0x33FFFFFF),
              showShadowPinsAndNodes: true,
              orbitShadowOpacity: 0.38,
              pinEveryN: 2,
              pinAboveColor: const Color(0xFF4CAF50),
              pinBelowColor: const Color(0xFFE57373),
              onSimDaysChanged: (d) {
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
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                          child: Text(
                            _centerNotice!,
                          ),
                        ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: (_selectedItem == null)
                      ? const SizedBox.shrink()
                      : OutlinedButton.icon(
                          key: const ValueKey('spaceRefBtn'),
                          onPressed: () {
                            final item = _selectedItem!;
                            final feedMap = neoLiteToFeedMap(item.neo);
                            final asteroid = asteroidFromFeedItem(feedMap);
                            final el = item.el;
                            final double a = el.a;
                            final double e = el.e;
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              enableDrag: false,
                              useSafeArea: true,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              builder: (_) => SpaceRefSheet(
                                asteroidName: item.neo.name.isNotEmpty
                                    ? item.neo.name
                                    : item.neo.id,
                                asteroid: asteroid,
                                orbitA: a,
                                orbitE: e,
                              ),
                            );
                          },
                          icon: const Icon(Icons.auto_stories_outlined),
                          label: const Text('SpaceReference (Experimental)'),
                        ),
                ),
                if (_selectedItem != null) const SizedBox(height: 0),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SpeedBtn(
                              tooltip: 'Speed -20',
                              icon: const Icon(Icons.fast_rewind),
                              onTap: () => setState(() =>
                                  _speed = (_speed - 20).clamp(0.0, 200))),
                          _SpeedBtn(
                              tooltip: 'Speed -1',
                              icon: const Icon(Icons.skip_previous),
                              onTap: () => setState(
                                  () => _speed = (_speed - 1).clamp(0.0, 200))),
                          Chip(
                            label: Text(_simDateString()),
                            visualDensity: VisualDensity.compact,
                          ),
                          _SpeedBtn(
                              tooltip: 'Speed +1',
                              icon: const Icon(Icons.skip_next),
                              onTap: () => setState(
                                  () => _speed = (_speed + 1).clamp(0.0, 200))),
                          _SpeedBtn(
                              tooltip: 'Speed +20',
                              icon: const Icon(Icons.fast_forward),
                              onTap: () => setState(() =>
                                  _speed = (_speed + 20).clamp(0.0, 200))),
                          IconButton(
                            onPressed: () => setState(() => _paused = !_paused),
                            icon: Icon(
                              _paused ? Icons.play_arrow : Icons.pause,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            tooltip: _paused ? 'Play' : 'Pause',
                          ),
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _addPickedAsteroid,
                            icon: const Icon(Icons.search),
                            label: const Text('Add asteroid'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _openQuickAddSheet,
                            icon: const Icon(Icons.add),
                            label: Text(_busy ? 'Loading…' : 'Options'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: OverflowBar(
                          alignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                                icon: const Icon(Icons.center_focus_strong),
                                label: const Text('Re-center'),
                                onPressed:
                                    _canvasKey.currentState?.homeToSunSnap),
                            TextButton.icon(
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Reset'),
                                onPressed: _reset3DOrbitViewer),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ]));
  }
}

class _SpeedBtn extends StatelessWidget {
  const _SpeedBtn(
      {required this.onTap,
        required this.icon,
        required this.tooltip});

  final Icon icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: icon,
      tooltip: tooltip,
    );
  }
}
