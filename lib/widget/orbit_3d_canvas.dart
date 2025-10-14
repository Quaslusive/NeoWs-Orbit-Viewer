import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:neows_app/model/neo_models.dart';
import 'package:neows_app/utils/mini_3d.dart';
import 'package:neows_app/utils/orbit_3d_math.dart';
import 'package:neows_app/utils/planet_objects.dart';

class Orbit3DItem {
  Orbit3DItem({
    required this.neo,
    required this.el,
    required this.color
  });

  final NeoLite neo;
  final OrbitElements el;
  final Color color;

  List<Offset3>? cachedPoints; // world polyline
  Offset? currentDot; // screen dot for picking
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
    this.showAxes = true,
    this.showGrid = true,
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
      fontFamily: 'EVA-Matisse_Standard',
      fontWeight: FontWeight.bold,
    ),
    this.showAsteroidLabels = true,
    this.asteroidLabelOpacity = 0.5,
    this.asteroidLabelStyle = const TextStyle(
      color: Colors.white,
      // backgroundColor: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    this.selectedAsteroidLabelStyle = const TextStyle(
      color: Colors.yellow,
      backgroundColor: Colors.black,
      fontSize: 17,
      fontFamily: 'EVA-Matisse_Standard',
      fontWeight: FontWeight.bold,
    ),
    this.showShadowPinsAndNodes = true,
    this.orbitShadowOpacity = 0.35,
    this.pinEveryN = 10,
    this.pinAboveColor = const Color(0xFF4CAF50),
    this.pinBelowColor = const Color(0xFFE57373),
    this.nodeAscColor = const Color(0xFF7CFC00),
    this.nodeDescColor = const Color(0xFFFF6B6B),
    this.nodeRipplePeriodMs = 2200,
    this.nodeRippleMaxRadiusPx = 26.0,
    this.onSimDaysChanged,
    this.resetTick = 0,
 //   this.focusObjectId,
    this.selectById,
    required Null Function(dynamic it) onLongPressItem,
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

  final double rotateSensitivity; // radians per pixel
  final double zoomSensitivity; // multiplicative per pinch delta
  final double minDistance; // min camera radius
  final double maxDistance; // max camera radius
  final bool invertY; // invert vertical drag

  final bool showAxes; // draw X/Y axes through the Sun
  final bool showGrid; // draw horizontal grid in ecliptic plane
  final double gridSpacingAu; // grid spacing (AU)
  final double gridExtentAu; // half-size (AU) of grid region (drawn from -extent..+extent)
  final Color axisXColor;
  final Color axisYColor;
  final Color gridColor;

  final double planetOrbitWidth; // line thickness in px
  final double planetDotScale; // multiplies Planet.radiusPx
  final double planetOrbitOpacity; // 0..1

  final bool showAsteroidLabels; // master toggle
  final double asteroidLabelOpacity; // 0..1 for unselected labels
  final TextStyle asteroidLabelStyle; // base style for unselected
  final TextStyle selectedAsteroidLabelStyle; // style when selected

  final bool showShadowPinsAndNodes;
  final double orbitShadowOpacity;
  final int pinEveryN; // draw a pin every N polyline points
  final Color pinAboveColor;
  final Color pinBelowColor;
  final Color nodeAscColor; // ascending node
  final Color nodeDescColor; // descending node
  final int nodeRipplePeriodMs;
  final double nodeRippleMaxRadiusPx;

  final void Function(double elapsedDays)? onSimDaysChanged; // emit days elapsed (since app open/reset)
  final int resetTick; // bump this to request a reset

//  final String? focusObjectId;

  final String? selectById;

  @override
  State<Orbit3DCanvas> createState() => Orbit3DCanvasState();
}

class Orbit3DCanvasState extends State<Orbit3DCanvas>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  double _simDays = 0.0; // Δt days since reset
  int _seenReset = 0;



  double _yaw = 0.0, _pitch = 0.0, _dist = 6.0;
  Offset? _lastDrag;

  String? _selectedId;
  Offset3 _camTarget = const Offset3(0, 0, 0);
  final double _followEase = 0.12;
  final Color _highlightColor = const Color(0xFFFFD54F);

  bool _isInteracting = false; // true while finger(s) down
  bool _autoResumeFollow = true; // set false if you want manual resume only
  DateTime? _lastInteractionAt;
  final Duration _resumeDelay = const Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dtMs = (elapsed - _lastTick).inMilliseconds;
      _lastTick = elapsed;

      if (!widget.paused && dtMs > 0) {
        _simDays += (dtMs / 1000.0) * widget.simDaysPerSec;
        widget.onSimDaysChanged?.call(_simDays);
      }

      final now = DateTime.now();
      final canFollow = !_isInteracting &&
          _selectedId != null &&
          (!_autoResumeFollow ||
              _lastInteractionAt == null ||
              now.difference(_lastInteractionAt!) > _resumeDelay);

      if (canFollow) _updateFollowTarget();

      setState(() {}); // repaint
    })..start();
  }


  @override
  void didUpdateWidget(covariant Orbit3DCanvas old) {
    super.didUpdateWidget(old);
    if (widget.resetTick != _seenReset) {
      _seenReset = widget.resetTick;
      _simDays = 0.0;
      widget.onSimDaysChanged?.call(_simDays);
      _lastTick = Duration.zero; // avoid a giant delta on next tick
    }
/*    // NEW: external selection request
    final newReq = widget.requestSelectId;
    final oldReq = old.requestSelectId;
    if (newReq != null && newReq.isNotEmpty && newReq != oldReq) {
      _selectById(newReq);   // set _selectedId and (optionally) snap camera target
    }*/
    }


  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  DateTime get _simNow {
    // _simDays is fractional, so use microseconds
    return DateTime.now()
        .toUtc()
        .add(Duration(microseconds: (_simDays * 86400000000).round()));
  }


// Compute selected asteroid current world position and ease camera target to it
// Kepler solver (radians)
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

// Compute selected asteroid current world position and ease camera target to it
  void _updateFollowTarget() {
    if (_selectedId == null) return;
    final idx = widget.items.indexWhere((e) => e.neo.id == _selectedId);
    if (idx < 0) return;
    final sel = widget.items[idx];
    final el = sel.el;
    final M  = el.meanAnomalyAt(_simNow);
    final E  = _solveKepler(M, el.e);
    final nu = 2.0 * math.atan2(
      math.sqrt(1 + el.e) * math.sin(E / 2.0),
      math.sqrt(1 - el.e) * math.cos(E / 2.0),
    );
    final pNow = orbitPoint3D(el.a, el.e, nu, el.omega, el.i, el.Omega);
    _camTarget = _lerp3(_camTarget, pNow, _followEase);
  }



  Offset3 _lerp3(Offset3 a, Offset3 b, double t) => Offset3(
      a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t);

// rename to PUBLIC method
  void selectById(String id) {
    final idx = widget.items.indexWhere((e) => e.neo.id == id);
    if (idx < 0) return;                 // not in the list yet
    final it = widget.items[idx];
    final el = it.el;

    _selectedId = id;

    // snap camera to its current position (optional but nice)
    final t = _simNow;
    final M = el.meanAnomalyAt(t);
    final E = _solveKepler(M, el.e);
    final nu = 2.0 * math.atan2(
      math.sqrt(1 + el.e) * math.sin(E / 2.0),
      math.sqrt(1 - el.e) * math.cos(E / 2.0),
    );
    final p = orbitPoint3D(el.a, el.e, nu, el.omega, el.i, el.Omega);
    _camTarget = _lerp3(_camTarget, p, 1.0);

    // let follow resume immediately
    _isInteracting = false;
    _lastInteractionAt = DateTime.now().subtract(_resumeDelay * 2);

    if (mounted) setState(() {});
  }



// make sure you also import your orbit helpers (where orbitPoint3D lives)

  void _focusOn(String id) {
    // Find the item
    final idx = widget.items.indexWhere((it) => it.neo.id == id);
    if (idx < 0) return;
    final it = widget.items[idx];
    final el = it.el;

    // Compute current world position at sim time
    final t = _simNow;
    final M = el.meanAnomalyAt(t);     // radians
    final E = _solveKepler(M, el.e);   // radians
    final nu = 2.0 * math.atan2(
      math.sqrt(1 + el.e) * math.sin(E / 2.0),
      math.sqrt(1 - el.e) * math.cos(E / 2.0),
    );
    final p = orbitPoint3D(el.a, el.e, nu, el.omega, el.i, el.Omega); // AU

    // 1) Set selection so your follow logic will keep tracking it
    _selectedId = id;

    // 2) Snap camera target to that point (1.0 = instant)
    _camTarget = _lerp3(_camTarget, p, 1.0);

    // 3) Optional: pull camera distance in a bit for clarity
    _dist = _dist.clamp(3.5, 12.0);

    // 4) Ensure the auto-follow can kick in immediately
    _isInteracting = false;
    _lastInteractionAt = DateTime.now().subtract(_resumeDelay * 2);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (d) {
        _isInteracting = true;
        _lastInteractionAt = DateTime.now();
        _lastDrag = d.focalPoint;
      },
      onScaleUpdate: (d) {
        // Zoom: you can make pinch stronger/weaker via zoomSensitivity
        if (d.scale != 1.0) {
          final factor = (1.0 / d.scale);
          final tuned = math.pow(factor, widget.zoomSensitivity).toDouble();
          _dist = (_dist * tuned).clamp(widget.minDistance, widget.maxDistance);
        } else if (_lastDrag != null) {
          // Rotate: map pixels to radians via rotateSensitivity
          final dx = d.focalPoint.dx - _lastDrag!.dx;
          final dy = d.focalPoint.dy - _lastDrag!.dy;

          _yaw += dx * widget.rotateSensitivity;
          final sign = widget.invertY ? -1.0 : 1.0;
          _pitch = (_pitch + sign * dy * widget.rotateSensitivity)
              .clamp(-math.pi / 2 + 0.05, math.pi / 2 - 0.05);
        }
        _lastDrag = d.focalPoint;
        setState(() {});
      },
      onScaleEnd: (d) {
        _isInteracting = false;
        _lastInteractionAt = DateTime.now();
        // If you prefer to **stop** following until reselected:
        // _selectedId = null;
      },
      onTapUp: (d) {
        // pick nearest dot (you already store currentDot during paint)
        Orbit3DItem? hit;
        double best = 24;
        for (final it in widget.items) {
          final p = it.currentDot;
          if (p == null) continue;
          final dist = (p - d.localPosition).distance;
          if (dist < best) {
            best = dist;
            hit = it;
          }
        }
        if (hit != null) {
          // set selection for follow + highlight
          _selectedId = hit.neo.id;
          // still allow external details pop
          if (widget.onSelect != null) widget.onSelect!(hit);
        }
      },
      onDoubleTap: () {
        // quick reset & unfollow
        _selectedId = null;
        _camTarget = const Offset3(0, 0, 0);
        _dist = 6.0;
        _yaw = 0.0;
        _pitch = 0.0;
        setState(() {});
      },
      child: CustomPaint(
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
          highlightColor: _highlightColor,
          showStars: widget.showStars,
          starCount: widget.starCount,
          labelStyle: widget.planetLabelStyle,
          showAxes: widget.showAxes,
          showGrid: widget.showGrid,
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
          nodeAscColor: widget.nodeAscColor,
          nodeDescColor: widget.nodeDescColor,
          nodeRipplePeriodMs: widget.nodeRipplePeriodMs,
          nodeRippleMaxRadiusPx: widget.nodeRippleMaxRadiusPx,
        ),
        isComplex: true,
        willChange: true,
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
    required this.highlightColor,
    required this.showAxes,
    required this.showGrid,
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
    required this.nodeAscColor,
    required this.nodeDescColor,
    required this.nodeRipplePeriodMs,
    required this.nodeRippleMaxRadiusPx,
  });

  final List<Orbit3DItem> items;
  final List<Planet> planets;
  final DateTime now;
  final int steps;
  final double yaw, pitch, dist;
  final bool showStars;
  final int starCount;
  final TextStyle labelStyle;

  final Offset3 cameraTarget;
  final String? selectedId;
  final Color highlightColor;

  final bool showAxes, showGrid;
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
  final Color nodeAscColor, nodeDescColor;
  final int nodeRipplePeriodMs;
  final double nodeRippleMaxRadiusPx;

// cache for grid world points (rebuild only if spacing/extent change)
  List<List<Offset3>>? _gridLines; // each is a 2-point line
  double? _cachedSpacing, _cachedExtent;

  // Cached across paints:
  List<Offset3>? _starDirs; // unit directions in world space
  Size? _lastSize;

  @override
  void paint(Canvas canvas, Size size) {
    // background
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF000000));

    final camPos = _sphericalToCartesian(dist, pitch, yaw);
    final cam = Camera3D(
      fovYDeg: 60,
      aspect: size.width / size.height,
      position: camPos,
      target: cameraTarget,
    );

    // stars
    if (showStars) _drawStars(canvas, size, cam);
    if (showAxes) _drawAxes(canvas, size, cam);
    if (showGrid) _drawGrid(canvas, size, cam);

    // sun
    final sun = projectVec(const Offset3(0, 0, 0), cam, size);
    if (sun != null) {
      const coreR = 20.0;
      const glowR = 90.0;

      // Outer glow
      final glowPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Colors.yellowAccent, Colors.transparent],
          stops: [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: sun, radius: glowR))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(sun, glowR, glowPaint);

      // Inner glow
      final corePaint = Paint()..color = Colors.yellowAccent;
      canvas.drawCircle(sun, coreR, corePaint);
    }


    // AU rings
    _drawAURings(canvas, size, cam, [0.5, 1.0, 1.5, 2.0]);

    // planets
    _drawPlanets(canvas, size, cam);

    if (showShadowPinsAndNodes && selectedId != null) {
      final selIdx = items.indexWhere((e) => e.neo.id == selectedId);
      if (selIdx != -1) {
        final sel = items[selIdx];
        // ensure world polyline exists
        sel.cachedPoints ??= List<Offset3>.generate(steps + 1, (k) {
          final nu = k / steps * 2 * math.pi;
          return orbitPoint3D(
              sel.el.a, sel.el.e, nu, sel.el.omega, sel.el.i, sel.el.Omega);
        });
        _drawOrbitShadowPinsNodes(canvas, size, cam, sel, sel.cachedPoints!);
      }
    }

    // asteroids (with highlight)
    for (final it in items) {
      it.cachedPoints ??= List<Offset3>.generate(steps + 1, (k) {
        final nu = k / steps * 2 * math.pi;
        return orbitPoint3D(
            it.el.a, it.el.e, nu, it.el.omega, it.el.i, it.el.Omega);
      });

      final path = Path();
      Offset? first;
      for (final p in it.cachedPoints!) {
        final sp = projectVec(p, cam, size);
        if (sp == null) continue;
        if (first == null) {
          path.moveTo(sp.dx, sp.dy);
          first = sp;
        } else {
          path.lineTo(sp.dx, sp.dy);
        }
      }

      final isSelected = (it.neo.id == selectedId);

      // base orbit
      canvas.drawPath(
        path,
        Paint()
          ..color = (isSelected
              ? it.color.withValues(alpha: 0.35)
              : it.color.withValues(alpha: 0.8))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // highlight overlay
      if (isSelected) {
        canvas.drawPath(
          path,
          Paint()
            ..color = highlightColor.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }

      // dot
      final nuNow = currentTrueAnomaly( // TODO deprecated
        aAu: it.el.a,
        e: it.el.e,
        M0DegAtEpoch: it.el.M0,
        epochUtc: it.el.epoch,
        tUtc: now,
      );
      final pNow = orbitPoint3D(
          it.el.a, it.el.e, nuNow, it.el.omega, it.el.i, it.el.Omega);
      final spNow = projectVec(pNow, cam, size);
      it.currentDot = spNow;
      if (spNow != null) {
        if (isSelected) {
          canvas.drawCircle(
              spNow,
              8,
              Paint()
                ..color = highlightColor.withValues(alpha: 0.25)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
          canvas.drawCircle(spNow, 4.6, Paint()..color = highlightColor);
        } else {
          canvas.drawCircle(spNow, 3.4, Paint()..color = it.color);
        }
      }
      if (spNow != null && showAsteroidLabels) {
        final isSelected = (it.neo.id == selectedId);

        // pick style + opacity
        final TextStyle style = isSelected
            ? selectedAsteroidLabelStyle
            : asteroidLabelStyle.copyWith(
                color: asteroidLabelStyle.color
                    ?.withValues(alpha: asteroidLabelOpacity),
              );

        // offset label relative to dot
        final Offset labelPos = spNow + const Offset(6, -6);

        _drawAsteroidLabel(canvas, labelPos, it.neo.name, style);
      }
    }
  }

  void _drawStars(Canvas canvas, Size size, Camera3D cam) {
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
        return Offset3(x / len, y / len, z / len);
      });
      _lastSize = size;
    }

    final paint = Paint()..style = PaintingStyle.fill;
    for (final dir in _starDirs!) {
      // Put star far away along dir (e.g., radius 1000 AU)
      final p = dir * 1000.0;
      final sp = projectVec(p, cam, size);
      if (sp == null) continue;
      // Vary brightness by |z| to add depth feel
      final b = (0.6 + 0.4 * dir.z.abs()).clamp(0.0, 1.0);
      paint.color = Color.fromRGBO(255, 255, 255, b);
      canvas.drawCircle(sp, 0.8 + 1.5 * b, paint);
    }
  }

  void _drawAURings(
      Canvas canvas, Size size, Camera3D cam, List<double> radiiAu) {
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
        final p = Offset3(r * math.cos(ang), 0, r * math.sin(ang));
        final sp = projectVec(p, cam, size);
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

  void _drawAxes(Canvas canvas, Size size, Camera3D cam) {
    final double L = gridExtentAu > 0 ? gridExtentAu : 3.0;
    // Y-axis (in our z-up mapping, ecliptic Y is world Z after our swap)
    _drawWorldLine(
      canvas,
      size,
      cam,
      const Offset3(0, -1, 0) * L,
      const Offset3(0, 1, 0) * L,
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
      const Offset3(-1, 0, 0) * L,
      const Offset3(1, 0, 0) * L,
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
        Offset3(v, 0, -tLen),
        Offset3(v, 0, tLen),
        Paint()
          ..color = axisXColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.0,
      );
      // tick on Y axis (perpendicular in +X direction)
      _drawWorldLine(
        canvas,
        size,
        cam,
        Offset3(-tLen, 0, v),
        Offset3(tLen, 0, v),
        Paint()
          ..color = axisYColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, Camera3D cam) {
    // Rebuild cache if spacing/extent changed
    if (_gridLines == null ||
        _cachedSpacing != gridSpacingAu ||
        _cachedExtent != gridExtentAu) {
      _cachedSpacing = gridSpacingAu;
      _cachedExtent = gridExtentAu;

      final L = gridExtentAu;
      final s = gridSpacingAu.clamp(0.1, 10.0);
      final lines = <List<Offset3>>[];

      // Lines parallel to X (vary Z), and parallel to Y (vary X).
      for (double v = -L; v <= L + 1e-6; v += s) {
        // horizontal lines: X from -L..L at fixed Z=v
        lines.add([Offset3(-L, 0, v), Offset3(L, 0, v)]);
        // vertical lines:  Z from -L..L at fixed X=v
        lines.add([Offset3(v, 0, -L), Offset3(v, 0, L)]);
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
  void _drawWorldLine(Canvas canvas, Size size, Camera3D cam, Offset3 a,
      Offset3 b, Paint paint) {
    final pa = projectVec(a, cam, size);
    final pb = projectVec(b, cam, size);
    if (pa == null || pb == null) return;
    final path = Path()
      ..moveTo(pa.dx, pa.dy)
      ..lineTo(pb.dx, pb.dy);
    canvas.drawPath(path, paint);
  }

  void _drawPlanets(Canvas canvas, Size size, Camera3D cam) {
    for (final pl in planets) {
      // Orbit ring in the planet's color, thicker
      const stepsRing = 320; // a bit smoother
      final path = Path();
      Offset? first;
      for (int k = 0; k <= stepsRing; k++) {
        final nu = k / stepsRing * 2 * math.pi;
        final p = orbitPoint3D(pl.a, pl.e, nu, pl.omega, pl.i, pl.Omega);
        final sp = projectVec(p, cam, size);
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
      final nuNow = currentTrueAnomaly( // TODO deprecated
        aAu: pl.a,
        e: pl.e,
        M0DegAtEpoch: pl.M0,
        epochUtc: pl.epoch,
        tUtc: now,
      );
      final pNow = orbitPoint3D(pl.a, pl.e, nuNow, pl.omega, pl.i, pl.Omega);
      final spNow = projectVec(pNow, cam, size);
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
    final bg = Paint()..color = Colors.black.withValues(alpha: 0.55); // TODO need soft shadows?
    canvas.save();
    canvas.translate(at.dx + 1.2, at.dy + 1.2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();

    tp.paint(canvas, at);
  }

  void _drawAsteroidLabel(
      Canvas canvas, Offset at, String name, TextStyle style,
      {double shadowOpacity = 0.55}) {
    final tp = TextPainter( // TODO need shadows??
      text: TextSpan(text: name, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);

    // subtle shadow for legibility
    canvas.save();
    canvas.translate(at.dx + 1.0, at.dy + 1.0);
    tp.paint(canvas, Offset.zero);
    canvas.restore();

    tp.paint(canvas, at);
  }

// Projects a world segment and draws it
  void _lineWorld(
      Canvas c, Size sz, Camera3D cam, Offset3 a, Offset3 b, Paint p) {
    final pa = projectVec(a, cam, sz);
    final pb = projectVec(b, cam, sz);
    if (pa == null || pb == null) return;
    final path = Path()
      ..moveTo(pa.dx, pa.dy)
      ..lineTo(pb.dx, pb.dy);
    c.drawPath(path, p);
  }

// Core effect
  void _drawOrbitShadowPinsNodes(Canvas canvas, Size size, Camera3D cam,
      Orbit3DItem it, List<Offset3> worldPts) {
    // ---- 1) Orbit SHADOW on ecliptic plane (y == 0) ----
    final shadowPath = Path();
    Offset? first;
    for (final p in worldPts) {
      final pShadow = Offset3(p.x, 0.0, p.z); // project onto grid plane
      final sp = projectVec(pShadow, cam, size);
      if (sp == null) continue;
      if (first == null) {
        shadowPath.moveTo(sp.dx, sp.dy);
        first = sp;
      } else {
        shadowPath.lineTo(sp.dx, sp.dy);
      }
    }
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = it.color.withValues(alpha: orbitShadowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..blendMode = BlendMode.srcOver,
    );

    // ---- 2) Vertical PINS (every Nth point) ----
    final pinPaintAbove = Paint()
      ..color = pinAboveColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.6;
    final pinPaintBelow = Paint()
      ..color = pinBelowColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.6;

    for (int k = 0; k < worldPts.length; k += pinEveryN.clamp(1, 9999)) {
      final p = worldPts[k];
      if (p.y.abs() < 1e-6) continue; // skip exactly on plane
      final pShadow = Offset3(p.x, 0.0, p.z);
      final paint = (p.y > 0) ? pinPaintAbove : pinPaintBelow;
      _lineWorld(canvas, size, cam, pShadow, p, paint);
    }

    // ---- 3) Node markers + RIPPLE ----
    // find where the orbit crosses y=0 (sign changes)
    for (int k = 1; k < worldPts.length; k++) {
      final a = worldPts[k - 1];
      final b = worldPts[k];
      final ya = a.y, yb = b.y;
      if ((ya == 0 && yb == 0) || ya.sign == yb.sign) continue; // no crossing

      // linear interpolate where y == 0
      final t = ya.abs() < 1e-9 ? 0.0 : (ya / (ya - yb)).clamp(0.0, 1.0);
      final x = a.x + (b.x - a.x) * t;
      final z = a.z + (b.z - a.z) * t;
      final dir = (yb - ya); // >0 ascending, <0 descending

      final nodeWorld = Offset3(x, 0.0, z); // on grid
      final nodeScreen = projectVec(nodeWorld, cam, size);
      if (nodeScreen == null) continue;

      final isAsc = dir > 0;
      final baseColor = isAsc ? nodeAscColor : nodeDescColor;

      // small solid marker
      canvas.drawCircle(nodeScreen, 3.0, Paint()..color = baseColor);

      // gentle ripple
      final phase = (now.millisecondsSinceEpoch % nodeRipplePeriodMs) /
          nodeRipplePeriodMs;
      final r =
          (phase * nodeRippleMaxRadiusPx).clamp(0.0, nodeRippleMaxRadiusPx);
      final alpha = (1.0 - phase).clamp(0.0, 1.0) * 0.8;
      canvas.drawCircle(
        nodeScreen,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = baseColor.withValues(alpha: alpha),
      );
    }
  }

  Offset3 _sphericalToCartesian(double r, double pitch, double yaw) {
    final x = r * math.cos(pitch) * math.sin(yaw);
    final y = r * math.sin(pitch);
    final z = r * math.cos(pitch) * math.cos(yaw);
    return Offset3(x, y, z);
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
      old.gridSpacingAu != gridSpacingAu ||
      old.gridExtentAu != gridExtentAu ||
      old.axisXColor != axisXColor ||
      old.axisYColor != axisYColor ||
      old.gridColor != gridColor ||
      old.showShadowPinsAndNodes != showShadowPinsAndNodes ||
      old.orbitShadowOpacity != orbitShadowOpacity ||
      old.pinEveryN != pinEveryN ||
      old.pinAboveColor != pinAboveColor ||
      old.pinBelowColor != pinBelowColor ||
      old.nodeAscColor != nodeAscColor ||
      old.nodeDescColor != nodeDescColor;
}
