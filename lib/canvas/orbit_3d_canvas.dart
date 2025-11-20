import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:neows_app/camera/orbit_camera_controller.dart';
import 'package:neows_app/neows/neo_models.dart';
import 'package:neows_app/camera/camera_pose.dart' as cam;
import 'package:neows_app/canvas/mini_3d.dart' as m3d;
import 'package:neows_app/math/orbit_3d_math.dart';
import 'package:neows_app/camera/orbit_camera_controls.dart';
import 'package:neows_app/canvas/planet_objects.dart';

class Orbit3DItem {
  Orbit3DItem({required this.neo, required this.el, required this.color});

  final NeoLite neo;
  final OrbitElements el;
  final Color color;

  List<m3d.Offset3>? cachedPoints; // world polyline
  Offset? currentDot; // screen dot for picking
  int currentDotFrame = -1;
}

class Orbit3DCanvas extends StatefulWidget {
  const Orbit3DCanvas({
    super.key,
    required this.items,
    this.onSelect,
    this.simDaysPerSec = 5.0,
    this.stepsPerOrbit = 220,
    this.planets = const [],
    this.showStars = true,
    this.starCount = 800,
    this.paused = false,
    this.rotateSensitivity = 0.004,
    this.zoomSensitivity = 0.05,
    this.minDistance = 2.0,
    this.maxDistance = 50.0,
    this.invertY = false,
    this.showAxes = false,
    this.showGrid = true,
    this.showOrbits = true,
    this.gridSpacingAu = 0.5,
    this.gridExtentAu = 3.0,
    this.axisXColor = const Color(0xFFFF6B6B),
    this.axisYColor = const Color(0xFF6BFF8A),
    this.gridColor = const Color(0x66FFFFFF),
    this.planetOrbitWidth = 2.6,
    this.planetDotScale = 1.6,
    this.planetOrbitOpacity = 0.85,
    this.planetLabelStyle = const TextStyle(
      color: Colors.yellow,
      backgroundColor: Colors.black,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
    this.showAsteroidLabels = true,
    this.asteroidLabelOpacity = 0.5,
    this.asteroidLabelStyle = const TextStyle(
      color: Colors.white,
      // backgroundColor: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
    this.selectedAsteroidLabelStyle = const TextStyle(
      color: Colors.yellow,
      backgroundColor: Colors.black,
      fontSize: 17,
      fontWeight: FontWeight.bold,
    ),
    required this.showShadowPinsAndNodes,
    this.orbitShadowOpacity = 0.35,
    this.pinEveryN = 1,
    this.pinAboveColor = const Color(0xFF4CAF50),
    this.pinBelowColor = const Color(0xFFE57373),
    this.onSimDaysChanged,
    this.selectedId,
    required this.onTapBackground,
  });

  final List<Orbit3DItem> items;
  final void Function(Orbit3DItem)? onSelect;
  final double simDaysPerSec;
  final int stepsPerOrbit;

  final List<Planet> planets;
  final bool showStars;
  final int starCount;
  final bool paused;
  final TextStyle planetLabelStyle;

  final double rotateSensitivity;
  final double zoomSensitivity;
  final double minDistance; // min camera radius
  final double maxDistance; // max camera radius
  final bool invertY;
  final bool showAxes;
  final bool showGrid;
  final bool showOrbits;
  final double gridSpacingAu;
  final double gridExtentAu; // half-size (AU) of grid region (drawn from -extent..+extent)
  final Color axisXColor;
  final Color axisYColor;
  final Color gridColor;

  final double planetOrbitWidth;
  final double planetDotScale;
  final double planetOrbitOpacity;

  final bool showAsteroidLabels; // master toggle
  final double asteroidLabelOpacity;
  final TextStyle asteroidLabelStyle;
  final TextStyle selectedAsteroidLabelStyle;

  final bool showShadowPinsAndNodes;
  final double orbitShadowOpacity;
  final int pinEveryN;
  final Color pinAboveColor;
  final Color pinBelowColor;
  final String? selectedId;

  final void Function(double elapsedDays)? onSimDaysChanged;
  final VoidCallback onTapBackground;


  @override
  State<Orbit3DCanvas> createState() => Orbit3DCanvasState();
}

class Orbit3DCanvasState extends State<Orbit3DCanvas>
    with TickerProviderStateMixin {
  Orbit3DItem itemById(String id) => _byId[id] ?? widget.items.first;
  Orbit3DItem? tryItemById(String id) => _byId[id];
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _simDays = 0.0;
  double _yaw = 0.0, _pitch = 0.4, _dist = 5.0;
  String? _selectedId;
  Offset? _sunDot;
  int _sunDotFrame = -1;
  cam.Offset3 _camTarget = const cam.Offset3(0, 0, 0);
  final Color _highlightOrbitColor = const Color(0xFFF8F8F8);
  late final OrbitCameraController _cam;

  // frame + pick-grid
  int _frame = 0;
  Map<String, Orbit3DItem> _byId = {};
  static const double _sunTapRadiusPx = 28.0;
  static const double _pickRadiusPx = 12.0;

// spatial hash (grid) over screen for picks
  final Map<int, List<String>> _cells = {}; // key = packed(cX,cY)
  static const double _cellSizePx = 64.0;

  int _cellKey(int cx, int cy) => (cx << 16) ^ (cy & 0xFFFF);

  void _beginFrame() {
    _frame++;
    _cells.clear();
  }
  // OrbitCameraController get camera => _cam;

  @override
  void initState() {
    super.initState();
    _byId = {for (final it in widget.items) it.neo.id: it};
    debugPrint(
        'frame=$_frame dots=${_cells.values.fold<int>(0, (a, b) => a + b.length)}');

    _cam = OrbitCameraController(
      initial: cam.CameraPose(
          yaw: _yaw, pitch: _pitch, dist: _dist, target: _camTarget),
      minDist: widget.minDistance,
      maxDist: widget.maxDistance,
      rotateSensitivity: widget.rotateSensitivity,
      zoomSensitivity: widget.zoomSensitivity,
      invertY: widget.invertY,
      panWorldScale: 1.0,
    )..addListener(() {
        final p = _cam.pose;
        if (!mounted) return;
        setState(() {
          _yaw = p.yaw;
          _pitch = p.pitch;
          _dist = p.dist;
          _camTarget = p.target;
        });
      });

    _ticker = createTicker((elapsed) {
      final dtMs = (elapsed - _lastTick).inMilliseconds;
      _lastTick = elapsed;

      if (!widget.paused && dtMs > 0) {
        _simDays += (dtMs / 1000.0) * widget.simDaysPerSec;
        widget.onSimDaysChanged?.call(_simDays);
        if (mounted) setState(() {}); // trigga paint (som fyller grid)
      }

      if (_cam.isFollowing && _selectedId != null) {
        final it = widget.items.firstWhere(
          (e) => e.neo.id == _selectedId!,
          orElse: () => widget.items.first,
        );
        final p = _worldPosForItemNow(it); // m3d.Offset3
        _cam.updateFollowTarget(cam.Offset3(p.x, p.y, p.z));
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cam.dispose();
    super.dispose();
  }

  DateTime get _simNow => DateTime.now()
      .toUtc()
      .add(Duration(microseconds: (_simDays * 86400000000).round()));

  @override
  void didUpdateWidget(covariant Orbit3DCanvas old) {
    super.didUpdateWidget(old);

    // Always rebuild the lookup map — even if the List instance is the same.
    _byId = {for (final it in widget.items) it.neo.id: it};

    if (_selectedId != null && !_byId.containsKey(_selectedId)) {
      _cam.setFollow(false);
      _selectedId = null;
      setState(() {});
    }

    _cam.setRotateSensitivity(widget.rotateSensitivity);
    _cam.setZoomSensitivity(widget.zoomSensitivity);
    _cam.setInvertY(widget.invertY);
    _cam.setDistanceClamp(widget.minDistance, widget.maxDistance);

    /*
    if (widget.selectById != null && widget.selectById != old.selectById) {
      if (_byId.containsKey(widget.selectById)) setSelectedId(widget.selectById);
    }*/
  }

  void resetSimulation() {
    _simDays = 0;
    widget.onSimDaysChanged?.call(0);
    setState(() {}); // repaint
  }

  void _registerSun(Offset pt) {
    _sunDot = pt;
    _sunDotFrame = _frame;
  }

  void _registerDot(String id, Offset dot) {
    final it = _byId[id];
    if (it == null) return;
    it.currentDot = dot;
    it.currentDotFrame = _frame;

    final cx = (dot.dx / _cellSizePx).floor();
    final cy = (dot.dy / _cellSizePx).floor();
    final k = _cellKey(cx, cy);
    final bucket = _cells.putIfAbsent(k, () => <String>[]);
    bucket.add(id);
  }

  void selectedId(String? id) {
    if (id == _selectedId) return;
    if (id != null && widget.items.indexWhere((e) => e.neo.id == id) == -1) {
      return;
    }
    setState(() => _selectedId = id);
    if (id != null) {
      final it = widget.items.firstWhere((e) => e.neo.id == id);
      widget.onSelect?.call(it);
    }
  }

  double _solveKepler(double M, double e) {
    var E = (e < 0.8) ? M : (M > math.pi ? M - e : M + e);
    for (int i = 0; i < 10; i++) {
      final f = E - e * math.sin(E) - M;
      final fp = 1 - e * math.cos(E);
      E -= f / fp;
    }
    E %= (2 * math.pi);
    if (E < 0) E += 2 * math.pi;
    return E;
  }

  m3d.Offset3 _worldPosForItemNow(Orbit3DItem it) {
    final el = it.el;
    final t = _simNow;
    final M = el.meanAnomalyAt(t);
    final E = _solveKepler(M, el.e);
    final nu = 2.0 *
        math.atan2(
          math.sqrt(1 + el.e) * math.sin(E / 2.0),
          math.sqrt(1 - el.e) * math.cos(E / 2.0),
        );
    return orbitPoint3D(el.a, el.e, nu, el.omega, el.i, el.Omega);
  }

  bool _isTapOnSun(Offset localPx) {
    if (_sunDot != null && _sunDotFrame == _frame) {
      final dx = _sunDot!.dx - localPx.dx;
      final dy = _sunDot!.dy - localPx.dy;
      return dx * dx + dy * dy <= _sunTapRadiusPx * _sunTapRadiusPx;
    }

    // Fallback
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final size = box.size;
    final sunScreen = _projectWorldToScreen(const m3d.Offset3(0, 0, 0), size);
    final dx = sunScreen.dx - localPx.dx;
    final dy = sunScreen.dy - localPx.dy;
    return dx * dx + dy * dy <= _sunTapRadiusPx * _sunTapRadiusPx;
  }

  Offset _projectWorldToScreen(m3d.Offset3 p, Size size) {
    // Translate to camera target space
    final dx = p.x - _camTarget.x;
    final dy = p.y - _camTarget.y;
    final dz = p.z - _camTarget.z;

    // Inverse yaw (around Z)
    final cosYaw = math.cos(-_yaw), sinYaw = math.sin(-_yaw);
    final x1 = dx * cosYaw - dy * sinYaw;
    final y1 = dx * sinYaw + dy * cosYaw;
    final z1 = dz;

    // Inverse pitch (around X)
    final cosPitch = math.cos(-_pitch), sinPitch = math.sin(-_pitch);
    final x2 = x1;
    final y2 = y1 * cosPitch - z1 * sinPitch;
    final z2 = y1 * sinPitch + z1 * cosPitch;

    // Move camera back by _dist along +Z in camera space
    final cz = z2 + _dist;
    final cx = x2;
    final cyCam = y2;

    // Pinhole projection (fov ≈ 60°)
    final f = 0.5 * size.height / math.tan((60 * math.pi / 180) / 2);

    // Guard against points behind camera
    const eps = 1e-3;
    final z = (cz.abs() < eps) ? (cz.isNegative ? -eps : eps) : cz;

    final screenX = size.width * 0.5 + (cx * f / z);
    final screenY = size.height * 0.5 - (cyCam * f / z);
    return Offset(screenX, screenY);
  }

/*  void focusSelected({bool follow = false}) {
    final id = _selectedId;
    if (id == null) return;
    final it = widget.items
        .firstWhere((e) => e.neo.id == id, orElse: () => widget.items.first);
    final p = _worldPosForItemNow(it);
    final tCam = cam.Offset3(p.x, p.y, p.z);
    _cam.focusOn(tCam, distance: _dist.clamp(3.5, 12.0));
    if (follow) _cam.setFollow(true);
  }*/

  String? _hitTestAsteroidId(Offset tapPx) {
    final cx = (tapPx.dx / _cellSizePx).floor();
    final cy = (tapPx.dy / _cellSizePx).floor();

    String? bestId;
    double bestD2 = _pickRadiusPx * _pickRadiusPx;

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final k = _cellKey(cx + dx, cy + dy);
        final bucket = _cells[k];
        if (bucket == null) continue;

        for (final id in bucket) {
          final it = _byId[id];
          if (it == null) continue;
          if (it.currentDot == null || it.currentDotFrame != _frame) continue;

          final dpx = it.currentDot!.dx - tapPx.dx;
          final dpy = it.currentDot!.dy - tapPx.dy;
          final d2 = dpx * dpx + dpy * dpy;
          if (d2 <= bestD2) {
            bestD2 = d2;
            bestId = id;
          }
        }
      }
    }
    // Fallback
    if (bestId != null) {
      debugPrint(
          'tap=$tapPx cell=(${(tapPx.dx / _cellSizePx).floor()}, '
              '${(tapPx.dy / _cellSizePx).floor()}) hit=$bestId');
      return bestId;
    }

    for (final it in widget.items) {
      if (it.currentDot == null || it.currentDotFrame != _frame) continue;
      final dpx = it.currentDot!.dx - tapPx.dx;
      final dpy = it.currentDot!.dy - tapPx.dy;
      final d2 = dpx * dpx + dpy * dpy;
      if (d2 <= bestD2) {
        bestD2 = d2;
        bestId = it.neo.id;
      }
    }
    return bestId;
  }

  void homeToSunSnap() {
    final dist = _dist.clamp(widget.minDistance, widget.maxDistance);
    _cam.setFollow(false);
    selectedId(null);
    _cam.focusOn(const cam.Offset3(0, 0, 0), distance: dist, snap: true);
  }

  @override
  Widget build(BuildContext context) {
    _beginFrame();
    return LayoutBuilder(
      builder: (_, constraints) => OrbitCameraControls(
        controller: _cam,
        viewportHeightPx: constraints.maxHeight,
        onTapSelect: (px) async {
          final id = _hitTestAsteroidId(px);
          if (id != null) {
            _selectedId = id;
            final it = tryItemById(id); // safe lookup (see B)
            if (it != null) widget.onSelect?.call(it);
            setState(() {});
            return;
          }
          _selectedId = null;
          widget.onTapBackground.call();
          setState(() {});
        },

        onDoubleTapToFocus: (px) async {
          if (_isTapOnSun(px)) {
            if (_cam.isFollowing) _cam.setFollow(false);
            _selectedId = null;
            widget.onTapBackground.call();
            final dist = (_dist.clamp(widget.minDistance, widget.maxDistance));
            _cam.focusOn(const cam.Offset3(0, 0, 0),
                distance: dist, snap: true);
            setState(() {});
          }

          final id = _hitTestAsteroidId(px);
          if (id == null) return null;
          final it = tryItemById(id);
          if (it == null) return null;
          widget.onSelect?.call(it);
          setState(() {});
          final p = _worldPosForItemNow(it);
          return cam.Offset3(p.x, p.y, p.z);
        },

        child: CustomPaint(
          size: Size.infinite,
          painter: _Orbit3DPainter(
            items: widget.items,
            planets: widget.planets,
            now: _simNow,
            steps: widget.stepsPerOrbit,
            yaw: _yaw,
            pitch: _pitch,
            dist: _dist,
            cameraTarget: _camTarget,
            selectedId: _selectedId,
          //  asteroidOrbitColor: _hazardousOrbitColor,
            highlightColor: _highlightOrbitColor,
            showStars: widget.showStars,
            starCount: widget.starCount,
            labelStyle: widget.planetLabelStyle,
            showAxes: widget.showAxes,
            showGrid: widget.showGrid,
            showOrbits: widget.showOrbits,
            gridSpacingAu: widget.gridSpacingAu,
            gridExtentAu: widget.gridExtentAu,
            axisXColor: widget.axisXColor,
            axisYColor: widget.axisYColor,
            gridColor: widget.gridColor,
            planetOrbitWidth: widget.planetOrbitWidth,
            planetDotScale: widget.planetDotScale,
            planetOrbitOpacity: widget.planetOrbitOpacity,
            showAsteroidLabels: widget.showAsteroidLabels,
            asteroidLabelOpacity: widget.asteroidLabelOpacity,
            asteroidLabelStyle: widget.asteroidLabelStyle,
            selectedAsteroidLabelStyle: widget.selectedAsteroidLabelStyle,
            showShadowPinsAndNodes: widget.showShadowPinsAndNodes,
            orbitShadowOpacity: widget.orbitShadowOpacity,
            pinEveryN: widget.pinEveryN,
            pinAboveColor: widget.pinAboveColor,
            pinBelowColor: widget.pinBelowColor,
            onProjectDot: (String id, Offset dot) {
              _registerDot(id, dot);
            },
            onProjectSun: (Offset pt) {
              _registerSun(pt);
            },
          ),
        ),
      ),
    );
  }
}

class _Orbit3DPainter extends CustomPainter {
  _Orbit3DPainter({
    required this.items,
    required this.planets,
    required this.now,
    required this.steps,
    required this.yaw,
    required this.pitch,
    required this.dist,
    required this.showStars,
    required this.starCount,
    required this.labelStyle,

    required this.cameraTarget,
    required this.selectedId,
   // required this.asteroidOrbitColor,
    required this.highlightColor,
    required this.showAxes,
    required this.showGrid,
    required this.showOrbits,
    required this.gridSpacingAu,
    required this.gridExtentAu,
    required this.axisXColor,
    required this.axisYColor,
    required this.gridColor,
    required this.planetOrbitWidth,
    required this.planetDotScale,
    required this.planetOrbitOpacity,
    required this.showAsteroidLabels,
    required this.asteroidLabelOpacity,
    required this.asteroidLabelStyle,
    required this.selectedAsteroidLabelStyle,
    required this.showShadowPinsAndNodes,
    required this.orbitShadowOpacity,
    required this.pinEveryN,
    required this.pinAboveColor,
    required this.pinBelowColor,
    required this.onProjectDot,
    required this.onProjectSun,
  });

  final List<Orbit3DItem> items;
  final List<Planet> planets;
  final DateTime now;
  final int steps;
  final double yaw, pitch, dist;
  final bool showStars;
  final int starCount;
  final TextStyle labelStyle;

  final cam.Offset3 cameraTarget;
  final String? selectedId;
  final Color highlightColor;
 // final Color asteroidOrbitColor;

  final bool showAxes, showGrid, showOrbits;
  final double gridSpacingAu, gridExtentAu;
  final Color axisXColor, axisYColor, gridColor;
  final double planetOrbitWidth, planetDotScale, planetOrbitOpacity;

  final bool showAsteroidLabels;
  final double asteroidLabelOpacity;
  final TextStyle asteroidLabelStyle;
  final TextStyle selectedAsteroidLabelStyle;

  final bool showShadowPinsAndNodes;
  final double orbitShadowOpacity;
  final int pinEveryN;
  final Color pinAboveColor, pinBelowColor;
  final void Function(String id, Offset dot) onProjectDot;
  final void Function(Offset sun) onProjectSun;

  // cache for grid world points
  // each is a 2-point line
  List<List<m3d.Offset3>>? _gridLines;
  double? _cachedSpacing, _cachedExtent;

  // Cached across paints:
  List<m3d.Offset3>? _starDirs; // unit directions in world space
  Size? _lastSize;

  final Paint _orbitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;

  @override
  void paint(Canvas canvas, Size size) {
    // background
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF000000));

    // camPos is m3d.Offset3 (convert if your helper returns cam.Offset3)
    final pos = _sphericalToCartesian(dist, pitch, yaw); // check its type

    final m3d.Offset3 camPos = (pos is m3d.Offset3)
        ? pos
        : m3d.Offset3((pos as cam.Offset3).x, pos.y, pos.z);

    // cameraTarget is cam.Offset3 -> convert to m3d.Offset3
    final m3d.Offset3 tgt =
        m3d.Offset3(cameraTarget.x, cameraTarget.y, cameraTarget.z);

    final cam3d = m3d.Camera3D(
      fovYDeg: 60,
      aspect: size.width / size.height,
      position: camPos,
      target: tgt,
    );

    // Optional layers
    if (showStars) _drawStars(canvas, size, cam3d);
    if (showAxes) _drawAxes(canvas, size, cam3d);
    if (showGrid) _drawGrid(canvas, size, cam3d);

    // Sun
    final sun = m3d.projectVec(const m3d.Offset3(0, 0, 0), cam3d, size);
    if (sun != null) {
      onProjectSun?.call(sun);
      const coreR = 20.0, glowR = 90.0;
      final glowPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Colors.yellowAccent, Colors.transparent],
          stops: [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: sun, radius: glowR))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(sun, glowR, glowPaint);
      canvas.drawCircle(sun, coreR, Paint()..color = Colors.yellowAccent);
    }

    // AU rings + planets
    _drawAURings(canvas, size, cam3d, const [0.5, 1.0, 1.5, 2.0]);
    _drawPlanets(canvas, size, cam3d);
    final bool drawOrbits = showOrbits;

//  Shadow pins when showOrbit=true
    if (drawOrbits && selectedId != null) {
      final idx = items.indexWhere((e) => e.neo.id == selectedId);
      if (idx != -1) {
        final sel = items[idx];
        sel.cachedPoints ??= List<m3d.Offset3>.generate(steps + 1, (k) {
          final nu = k / steps * 2 * math.pi;
          return orbitPoint3D(sel.el.a, sel.el.e, nu, sel.el.omega, sel.el.i, sel.el.Omega);
        });
        _drawOrbitShadowPinsNodes(
          canvas, size, cam3d, sel, sel.cachedPoints!,
        );
      }
    }

    _orbitPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    _highlightPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    for (final it in items) {
      if (drawOrbits) {
        it.cachedPoints ??= List<m3d.Offset3>.generate(steps + 1, (k) {
          final nu = k / steps * 2 * math.pi;
          return orbitPoint3D(it.el.a, it.el.e, nu, it.el.omega, it.el.i, it.el.Omega);
        });

        final path = Path();
        Offset? first;
        for (final p3 in it.cachedPoints!) {
          final sp = m3d.projectVec(p3, cam3d, size);
          if (sp == null) continue;
          if (first == null) { path.moveTo(sp.dx, sp.dy); first = sp; }
          else { path.lineTo(sp.dx, sp.dy); }
        }

        final isSelected = (it.neo.id == selectedId);
        _orbitPaint.color = it.color.withValues(alpha: 0.8);
        canvas.drawPath(path, _orbitPaint);

        if (isSelected) {
          _highlightPaint.color = highlightColor.withValues(alpha: 0.9);
          canvas.drawPath(path, _highlightPaint);
        }
      } else {
        it.cachedPoints = null;
      }

      final nuNow = trueAnomalyNow(
        aAu: it.el.a,
        e: it.el.e,
        M0: it.el.M0,
        n: it.el.n,
        epochUtc: it.el.epoch,
        tUtc: now.toUtc(),
      );

      // world 3D point
      final pNow3 = orbitPoint3D(it.el.a, it.el.e, nuNow, it.el.omega, it.el.i, it.el.Omega);

      // screen 2D point
      final spNow = m3d.projectVec(pNow3, cam3d, size);
      if (spNow == null) continue;

      onProjectDot(it.neo.id, spNow);

      final isSelected = (it.neo.id == selectedId);
      if (isSelected) {
        canvas.drawCircle(
          spNow,
          8,
          Paint()
            ..color = highlightColor.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(spNow, 4.6, Paint()..color = highlightColor);
      } else {
        canvas.drawCircle(spNow, 3.4, Paint()..color = it.color);
      }

      if (showAsteroidLabels) {
        final style = isSelected
            ? selectedAsteroidLabelStyle
            : asteroidLabelStyle.copyWith(
          color: asteroidLabelStyle.color?.withValues(alpha: asteroidLabelOpacity),
        );
        final labelPos = spNow + const Offset(6, -6); // 2D
        final tp = TextPainter(
          text: TextSpan(text: it.neo.name, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        tp.paint(canvas, labelPos);
      }
    }
  }

  void _drawStars(Canvas canvas, Size size, m3d.Camera3D cam) {
    // Generate deterministic star directions once or if size changed
    if (_starDirs == null || _lastSize != size) {
      final rnd = math.Random(42);
      _starDirs = List.generate(starCount, (_) {
        // Random point on sphere via normal distribution
        double x, y, z;
        do {
          x = rnd.nextDouble() * 2 - 1;
          y = rnd.nextDouble() * 2 - 1;
          z = rnd.nextDouble() * 2 - 1;
        } while (x * x + y * y + z * z > 1 || (x == 0 && y == 0 && z == 0));
        final len = math.sqrt(x * x + y * y + z * z);
        return m3d.Offset3(x / len, y / len, z / len);
      });
      _lastSize = size;
    }

    final paint = Paint()..style = PaintingStyle.fill;
    for (final dir in _starDirs!) {
      // Put star far away along dir (e.g., radius 1000 AU)
      final p = dir * 1000.0;
      final sp = m3d.projectVec(p, cam, size);
      if (sp == null) continue;
      // Vary brightness by |z| to add depth feel
      final b = (0.6 + 0.4 * dir.z.abs()).clamp(0.0, 1.0);
      paint.color = Color.fromRGBO(255, 255, 255, b);
      canvas.drawCircle(sp, 0.8 + 1.5 * b, paint);
    }
  }

  void _drawAURings(
      Canvas canvas, Size size, m3d.Camera3D cam, List<double> radiiAu) {
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final r in radiiAu) {
      const stepsRing = 180;
      final path = Path();
      Offset? first;
      for (int k = 0; k <= stepsRing; k++) {
        final ang = k / stepsRing * 2 * math.pi;
        // ecliptic plane (X,Y), Z=0 → rotate to our z-up feel (already consistent)
        final p = m3d.Offset3(r * math.cos(ang), 0, r * math.sin(ang));
        final sp = m3d.projectVec(p, cam, size);
        if (sp == null) continue;
        if (first == null) {
          path.moveTo(sp.dx, sp.dy);
          first = sp;
        } else {
          path.lineTo(sp.dx, sp.dy);
        }
      }
      canvas.drawPath(path, ringPaint);
    }
  }

  void _drawAxes(Canvas canvas, Size size, m3d.Camera3D cam) {
    final double L = gridExtentAu > 0 ? gridExtentAu : 3.0;
    _drawWorldLine(
      canvas,
      size,
      cam,
      const m3d.Offset3(0, -1, 0) * L,
      const m3d.Offset3(0, 1, 0) * L,
      Paint()
        ..color = axisYColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    // X-axis: from (-L, 0, 0) to (L, 0, 0)
    _drawWorldLine(
      canvas,
      size,
      cam,
      const m3d.Offset3(-1, 0, 0) * L,
      const m3d.Offset3(1, 0, 0) * L,
      Paint()
        ..color = axisXColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    // axis ticks (optional): short ticks every gridSpacing
    final s = gridSpacingAu.clamp(0.1, 5.0);
    final tLen = 0.05 *
        (gridExtentAu / 3.0).clamp(0.5, 2.0); // tick length scales mildly
    for (double v = -L; v <= L + 1e-6; v += s) {
      // tick on X axis (small segment perpendicular in +Z direction)
      _drawWorldLine(
        canvas,
        size,
        cam,
        m3d.Offset3(v, 0, -tLen),
        m3d.Offset3(v, 0, tLen),
        Paint()
          ..color = axisXColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.0,
      );
      // tick on Y axis (perpendicular in +X direction)
      _drawWorldLine(
        canvas,
        size,
        cam,
        m3d.Offset3(-tLen, 0, v),
        m3d.Offset3(tLen, 0, v),
        Paint()
          ..color = axisYColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, m3d.Camera3D cam) {
    // Rebuild cache if spacing/extent changed
    if (_gridLines == null ||
        _cachedSpacing != gridSpacingAu ||
        _cachedExtent != gridExtentAu) {
      _cachedSpacing = gridSpacingAu;
      _cachedExtent = gridExtentAu;

      final L = gridExtentAu;
      final s = gridSpacingAu.clamp(0.1, 10.0);
      final lines = <List<m3d.Offset3>>[];

      // Lines parallel to X (vary Z), and parallel to Y (vary X).
      for (double v = -L; v <= L + 1e-6; v += s) {
        // horizontal lines: X from -L..L at fixed Z=v
        lines.add([m3d.Offset3(-L, 0, v), m3d.Offset3(L, 0, v)]);
        // vertical lines:  Z from -L..L at fixed X=v
        lines.add([m3d.Offset3(v, 0, -L), m3d.Offset3(v, 0, L)]);
      }
      _gridLines = lines;
    }

    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (final seg in _gridLines!) {
      _drawWorldLine(canvas, size, cam, seg[0], seg[1], paint);
    }
  }

// Projects a world-space segment and draws it if visible
  void _drawWorldLine(Canvas canvas, Size size, m3d.Camera3D cam, m3d.Offset3 a,
      m3d.Offset3 b, Paint paint) {
    final pa = m3d.projectVec(a, cam, size);
    final pb = m3d.projectVec(b, cam, size);
    if (pa == null || pb == null) return;
    final path = Path()
      ..moveTo(pa.dx, pa.dy)
      ..lineTo(pb.dx, pb.dy);
    canvas.drawPath(path, paint);
  }

  void _drawPlanets(Canvas canvas, Size size, m3d.Camera3D cam) {
    for (final pl in planets) {
      // Orbit ring in the planet's color, thicker
      const stepsRing = 320; // a bit smoother
      final path = Path();
      Offset? first;
      for (int k = 0; k <= stepsRing; k++) {
        final nu = k / stepsRing * 2 * math.pi;
        final p = orbitPoint3D(pl.a, pl.e, nu, pl.omega, pl.i, pl.Omega);
        final sp = m3d.projectVec(p, cam, size);
        if (sp == null) continue;
        if (first == null) {
          path.moveTo(sp.dx, sp.dy);
          first = sp;
        } else {
          path.lineTo(sp.dx, sp.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = pl.color.withValues(alpha: (planetOrbitOpacity))
          ..style = PaintingStyle.stroke
          ..strokeWidth = planetOrbitWidth,
      );

      // Current planet position
      final nuNow = trueAnomalyNow(
        aAu: pl.a,
        e: pl.e,
        M0: pl.M0,
        n: pl.n,
        epochUtc: pl.epoch,
        tUtc: now,
      );
      final pNow = orbitPoint3D(pl.a, pl.e, nuNow, pl.omega, pl.i, pl.Omega);
      final spNow = m3d.projectVec(pNow, cam, size);
      if (spNow != null) {
        // Bigger dot
        canvas.drawCircle(
          spNow,
          pl.radiusPx * planetDotScale,
          Paint()..color = pl.color,
        );
        _drawLabel(canvas, spNow + const Offset(8, -8), pl.name);
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset at, String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);

    // soft shadow/outline for legibility
/*    final bg = Paint()
      ..color = Colors.black.withValues(alpha: 0.55); // TODO need soft shadows?*/
    canvas.save();
    canvas.translate(at.dx + 1.2, at.dy + 1.2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();

    tp.paint(canvas, at);
  }

// Projects a world segment and draws it
  void _lineWorld(Canvas c, Size sz, m3d.Camera3D cam, m3d.Offset3 a,
      m3d.Offset3 b, Paint p) {
    final pa = m3d.projectVec(a, cam, sz);
    final pb = m3d.projectVec(b, cam, sz);
    if (pa == null || pb == null) return;
    final path = Path()
      ..moveTo(pa.dx, pa.dy)
      ..lineTo(pb.dx, pb.dy);
    c.drawPath(path, p);
  }

  void _drawOrbitShadowPinsNodes(Canvas canvas, Size size, m3d.Camera3D cam,
      Orbit3DItem it, List<m3d.Offset3> worldPts) {
    // Orbit SHADOW on ecliptic plane (y == 0)
    final shadowPath = Path();
    Offset? first;
    for (final p in worldPts) {
      final pShadow = m3d.Offset3(p.x, 0.0, p.z);
      // project onto grid plane
      final sp = m3d.projectVec(pShadow, cam, size);
      if (sp == null) continue;
      if (first == null) {
        shadowPath.moveTo(sp.dx, sp.dy);
        first = sp;
      } else {
        shadowPath.lineTo(sp.dx, sp.dy);
      }
    }
    canvas.drawPath(shadowPath, Paint()
      ..color = it.color.withValues(alpha: orbitShadowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..blendMode = BlendMode
          .srcOver,);
    // Vertical PINS (every Nth point)
    final pinPaintAbove = Paint()
      ..color = pinAboveColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.6;
    final pinPaintBelow = Paint()
      ..color = pinBelowColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.6;
    for (int k = 0; k < worldPts.length; k += pinEveryN.clamp(1, 9999)) {
      final p = worldPts[k];
      if (p.y.abs() < 1e-6)
        continue; // skip exactly on plane
       final pShadow = m3d.Offset3(p.x, 0.0, p.z);
      final paint = (p.y > 0) ? pinPaintAbove : pinPaintBelow;
      _lineWorld(canvas, size, cam, pShadow, p, paint);
    }
  }

  m3d.Offset3 _sphericalToCartesian(double r, double pitch, double yaw) {
    final x = r * math.cos(pitch) * math.sin(yaw);
    final y = r * math.sin(pitch);
    final z = r * math.cos(pitch) * math.cos(yaw);
    return m3d.Offset3(x, y, z);
  }

  @override
  bool shouldRepaint(covariant _Orbit3DPainter old) =>
      old.now != now ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.dist != dist ||
      old.items != items ||
      old.planets != planets ||
      old.showStars != showStars ||
      old.starCount != starCount ||
      old.selectedId != selectedId ||
      old.cameraTarget != cameraTarget ||
      old.labelStyle != labelStyle ||
      old.highlightColor != highlightColor ||
      old.showAxes != showAxes ||
      old.showGrid != showGrid ||
      old.showOrbits != showOrbits ||
      old.gridSpacingAu != gridSpacingAu ||
      old.gridExtentAu != gridExtentAu ||
      old.axisXColor != axisXColor ||
      old.axisYColor != axisYColor ||
      old.gridColor != gridColor ||
      old.showShadowPinsAndNodes != showShadowPinsAndNodes ||
      old.orbitShadowOpacity != orbitShadowOpacity ||
      old.pinEveryN != pinEveryN ||
      old.pinAboveColor != pinAboveColor ||
      old.pinBelowColor != pinBelowColor;
}
