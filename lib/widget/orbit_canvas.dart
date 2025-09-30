import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../model/neo_models.dart';
import '../utils/orbit_math.dart';

class OrbitDrawable {
  OrbitDrawable({
    required this.neo,
    required this.el,
    required this.color,
    DateTime? appearAt,
  }) : appearAt = appearAt ?? DateTime.now();

  final NeoLite neo;
  final OrbitElements el;
  final Color color;

  // computed per-frame for hit-testing
  Offset? currentPtScreen;

  // for fade-in
  final DateTime appearAt;
}

class OrbitCanvas extends StatefulWidget {
  const OrbitCanvas({
    super.key,
    required this.items,                // many asteroids supported
    this.onSelect,
    this.initialZoomPxPerAu = 140.0,
    this.simSpeedDaysPerSec = 5.0,      // 5 days / real second
    this.maxFps = 60,                   // cap for battery
    this.showEarthRing = true,
    this.background = const Color(0xFF000000),
  });

  final List<OrbitDrawable> items;
  final void Function(OrbitDrawable)? onSelect;

  /// Start zoom level (pixels per AU)
  final double initialZoomPxPerAu;

  /// Simulation speed: how many days pass per 1 real second
  final double simSpeedDaysPerSec;

  /// Max redraws per second
  final int maxFps;

  final bool showEarthRing;
  final Color background;

  @override
  State<OrbitCanvas> createState() => _OrbitCanvasState();
}

class _OrbitCanvasState extends State<OrbitCanvas> with TickerProviderStateMixin {
  late double _scale = widget.initialZoomPxPerAu;
  Offset _offset = Offset.zero;
  Offset? _lastFocal;

  late final Ticker _ticker;
  late DateTime _simStartUtc;
  late Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _simStartUtc = DateTime.now().toUtc();
    _ticker = createTicker((elapsed) {
      // Cap FPS by skipping frames
      final frameInterval = Duration(milliseconds: (1000 / widget.maxFps).round());
      if (elapsed - _elapsed < frameInterval) return;
      _elapsed = elapsed;
      // Drive animation
      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  DateTime get _simNow {
    final days = widget.simSpeedDaysPerSec * (_elapsed.inMilliseconds / 1000.0);
    return _simStartUtc.add(Duration(milliseconds: (days * 86400000).round()));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (d) => _lastFocal = d.focalPoint,
      onScaleUpdate: (d) {
        final focal = d.focalPoint;
        if (d.scale != 1.0) {
          final pre = (focal - _offset) / _scale;
          _scale *= d.scale;
          final post = pre * _scale + _offset;
          _offset += focal - post;
        } else if (_lastFocal != null) {
          _offset += (focal - _lastFocal!);
        }
        _lastFocal = focal;
        setState(() {});
      },
      onTapUp: (d) {
        final pos = d.localPosition;
        OrbitDrawable? picked;
        double best = 24.0; // px radius
        for (final it in widget.items) {
          final pt = it.currentPtScreen;
          if (pt == null) continue;
          final dist = (pt - pos).distance;
          if (dist < best) {
            best = dist;
            picked = it;
          }
        }
        if (picked != null && widget.onSelect != null) widget.onSelect!(picked);
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _OrbitPainter(
            items: widget.items,
            scale: _scale,
            offset: _offset,
            simNowUtc: _simNow,
            showEarthRing: widget.showEarthRing,
            background: widget.background,
          ),
          isComplex: true,
          willChange: true,
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.items,
    required this.scale,
    required this.offset,
    required this.simNowUtc,
    required this.showEarthRing,
    required this.background,
  });

  final List<OrbitDrawable> items;
  final double scale;
  final Offset offset;
  final DateTime simNowUtc;
  final bool showEarthRing;
  final Color background;

  static const _pathSteps = 180; // good performance/quality
  static const _fadeInMs = 500;  // per-asteroid fade in

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    Offset world2screen(double x, double y) => Offset(x * scale, -y * scale) + center + offset;

    // Background
    final bg = Paint()..color = background;
    canvas.drawRect(Offset.zero & size, bg);

    // Sun
    final sunPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(center + offset, 6.0, sunPaint);

    // Earth 1 AU ring (optional)
    if (showEarthRing) {
      final ring = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center + offset, 1.0 * scale, ring);
    }

    // Draw each asteroid orbit + current position
    for (final it in items) {
      final el = it.el;

      // Fade-in alpha based on when this item appeared
      final ms = simNowUtc.millisecondsSinceEpoch - it.appearAt.millisecondsSinceEpoch;
      final t = (ms / _fadeInMs).clamp(0.0, 1.0);
      final alpha = Curves.easeOut.transform(t);
      if (alpha <= 0) continue;

      // Build orbit path
      final path = Path();
      for (int k = 0; k <= _pathSteps; k++) {
        final nu = (k / _pathSteps) * 2 * math.pi;
        final p = ellipsePointAU(el.a, el.e, nu);
        // Rotate in plane by (Ω + ω)
        final rot = rot2D(p.x, p.y, (el.Omega + el.omega) * math.pi / 180.0);
        final sp = world2screen(rot.x, rot.y);
        if (k == 0) {
          path.moveTo(sp.dx, sp.dy);
        } else {
          path.lineTo(sp.dx, sp.dy);
        }
      }

      final orbitPaint = Paint()
        ..color = it.color.withOpacity(0.7 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, orbitPaint);

      // Animated current position based on simulated time
      final nuNow = currentTrueAnomaly(
        aAu: el.a,
        e: el.e,
        M0DegAtEpoch: el.M,
        epochUtc: el.epoch,
        tUtc: simNowUtc,
      );
      final pNow = ellipsePointAU(el.a, el.e, nuNow);
      final rotNow = rot2D(pNow.x, pNow.y, (el.Omega + el.omega) * math.pi / 180.0);
      final spNow = world2screen(rotNow.x, rotNow.y);
      it.currentPtScreen = spNow;

      final dot = Paint()..color = it.color.withOpacity(alpha);
      canvas.drawCircle(spNow, 3.4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) {
    return old.items != items ||
        old.scale != scale ||
        old.offset != offset ||
        old.simNowUtc != simNowUtc ||
        old.showEarthRing != showEarthRing ||
        old.background != background;
  }
}
