import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrbitThumb extends StatefulWidget {
  /// Semi-major axis in AU units relative to Earth=1.0
  final double asteroidA;
  /// Eccentricity 0..1
  final double asteroidE;
  /// Seconds for one full asteroid revolution (before speedScale)
  final Duration asteroidPeriod;
  /// Visual inclination in degrees (fake 3D tilt via Y scale)
  final double inclinationDeg;
  /// Show perihelion/aphelion ticks + labels
  final bool showApsides;
  /// Show a tiny Moon around Earth
  final bool showMoon;
  /// Parallax starfield in background
  final bool showParallaxStars;
  /// Add a short “comet tail” effect to the asteroid
  final bool cometTail;
  /// Show info chip with a/e and name
  final bool showInfoChip;
  /// Optional display name (used in chip & Semantics)
  final String? objectName;
  /// Multiplier for animation speed (1.0 = normal)
  final double speedScale;
  /// Enable horizontal drag scrubbing
  final bool enableScrub;
  /// Optional Hero tag to animate this thumb into a detail view
  final String? heroTag;
  /// Tap callback (e.g., navigate to full orbit page)
  final VoidCallback? onTap;
  /// Start paused (long-press toggles)
  final bool paused;
  /// Show a floating label next to the asteroid dot
  final bool showAsteroidLabel;

  const OrbitThumb({
    super.key,
    required this.asteroidA,
    required this.asteroidE,
    this.asteroidPeriod = const Duration(seconds: 12),
    this.inclinationDeg = 10,
    this.showApsides = true,
    this.showMoon = true,
    this.showParallaxStars = true,
    this.cometTail = true,
    this.showInfoChip = true,
    this.objectName,
    this.speedScale = 1.0,
    this.enableScrub = true,
    this.heroTag,
    this.onTap,
    this.paused = false,
    this.showAsteroidLabel = true,
  });

  @override
  State<OrbitThumb> createState() => _OrbitThumbState();
}

class _OrbitThumbState extends State<OrbitThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  double _scrubOffset = 0; // 0..1 additive fraction
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _paused = widget.paused;
    _ctl = AnimationController.unbounded(vsync: this);
    if (!_paused) {
      _ctl.repeat(min: 0, max: 1e9, period: const Duration(hours: 1));
    }
  }

  @override
  void didUpdateWidget(covariant OrbitThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_paused && _ctl.isAnimating) _ctl.stop();
    if (!_paused && !_ctl.isAnimating) {
      _ctl.repeat(min: 0, max: 1e9, period: const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _ctl.stop();
      } else {
        _ctl.repeat(min: 0, max: 1e9, period: const Duration(hours: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = Semantics(
      label: 'Orbit thumbnail for ${widget.objectName ?? "asteroid"}',
      enabled: true,
      liveRegion: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: _togglePause,
        onHorizontalDragUpdate: widget.enableScrub
            ? (d) {
                setState(() {
                  _scrubOffset = (_scrubOffset + (d.primaryDelta ?? 0) * 0.001)
                      .clamp(0.0, 1.0);
                });
              }
            : null,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) {
              // Timebase (seconds)
              final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

              // Earth loop ~8s (scaled by speedScale)
              final earthLoop = 8.0 / widget.speedScale.clamp(0.25, 4.0);
              final earthTheta = 2 * math.pi * ((now % earthLoop) / earthLoop);

              // Asteroid loop uses user period + speedScale + scrub
              final basePeriod = widget.asteroidPeriod.inMilliseconds / 1000.0;
              final adjPeriod =
                  (basePeriod / widget.speedScale.clamp(0.25, 4.0))
                      .clamp(3.0, 30.0);
              final baseFrac = (now % adjPeriod) / adjPeriod;
              final astroTheta =
                  2 * math.pi * ((baseFrac + _scrubOffset) % 1.0);

              // Parallax star drift factor
              final starDrift = now * 0.0025 * widget.speedScale;

              return CustomPaint(
                painter: _OrbitThumbPainter(
                  // data
                  asteroidA: widget.asteroidA.clamp(0.2, 3.0),
                  asteroidE: widget.asteroidE.clamp(0.0, 0.95),
                  inclinationDeg: widget.inclinationDeg.clamp(0.0, 75.0),
                  asteroidTheta: astroTheta,
                  earthTheta: earthTheta,
                  // flags
                  showApsides: widget.showApsides,
                  showMoon: widget.showMoon,
                  showParallaxStars: widget.showParallaxStars,
                  cometTail: widget.cometTail,
                  showInfoChip: widget.showInfoChip,
                  objectName: widget.objectName,
                  showAsteroidLabel: widget.showAsteroidLabel,
                  // time-ish visuals
                  starDrift: starDrift,
                ),
                isComplex: true,
                willChange: true,
              );
            },
          ),
        ),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: child);
    }
    return child;
  }
}

class _OrbitThumbPainter extends CustomPainter {
  final double asteroidA;
  final double asteroidE;
  final double inclinationDeg;
  final double asteroidTheta;
  final double earthTheta;

  final bool showApsides;
  final bool showMoon;
  final bool showParallaxStars;
  final bool cometTail;
  final bool showInfoChip;
  final String? objectName;

  final double starDrift;

  final bool showAsteroidLabel;

  _OrbitThumbPainter({
    required this.asteroidA,
    required this.asteroidE,
    required this.inclinationDeg,
    required this.asteroidTheta,
    required this.earthTheta,
    required this.showApsides,
    required this.showMoon,
    required this.showParallaxStars,
    required this.cometTail,
    required this.showInfoChip,
    required this.objectName,
    required this.starDrift,
    required this.showAsteroidLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // ---- Background gradient
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0F23), Color(0xFF09121E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Parallax stars (two layers)
    if (showParallaxStars) {
      _drawStars(canvas, size,
          driftX: starDrift * 12,
          driftY: starDrift * 6,
          seed: 42,
          count: 60,
          opacity: 0.55);
      _drawStars(canvas, size,
          driftX: starDrift * 24,
          driftY: starDrift * 10,
          seed: 108,
          count: 30,
          opacity: 0.35);
    }

    final radiusBase = math.min(size.width, size.height) * 0.38;

    // Sun glow
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFD37D),
          Color(0x55FFA600),
          Colors.transparent
        ],
        stops: [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radiusBase * 0.8));
    canvas.drawCircle(center, radiusBase * 0.35, sunPaint);

    // Earth orbit ring
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF3A92FF).withValues(alpha: 0.6);
    canvas.drawCircle(center, radiusBase, orbitPaint);

    // Earth and optional Moon
    final earthPos = Offset(
      cx + radiusBase * math.cos(earthTheta),
      cy + radiusBase * math.sin(earthTheta),
    );
    _planet(canvas, earthPos, 6, const Color(0xFF74B6FF));

    if (showMoon) {
      final moonTheta = earthTheta * 12.0;
      const moonR = 12.0;
      final moonPos = earthPos +
          Offset(moonR * math.cos(moonTheta), moonR * math.sin(moonTheta));

      // lunar orbit ring (subtle)
      canvas.drawCircle(
        earthPos,
        moonR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = Colors.white24,
      );
      _planet(canvas, moonPos, 2.5, const Color(0xFFE0E0E0));
      _satLabel(canvas, 'moon', moonPos + const Offset(6, -6));
    }

    // ----- Asteroid ellipse with fake tilt
    final a = radiusBase * asteroidA;
    final e = asteroidE;
    final i = inclinationDeg * math.pi / 180.0;
    final bNoTilt = a * math.sqrt(1 - e * e);
    final b = bNoTilt * math.cos(i);
    final focusOffset = a * e; // Sun at right focus

    final orbitRect = Rect.fromCenter(
      center: Offset(cx + focusOffset, cy),
      width: a * 2,
      height: b * 2,
    );

    final dashed = _dashedPath(Path()..addOval(orbitRect), dash: 7, gap: 6);
    final asteroidOrbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFF9F5A).withValues(alpha: 0.7);
    canvas.drawPath(dashed, asteroidOrbitPaint);

    // Apsides (q/Q) ticks & labels
    if (showApsides) {
      final peri = Offset(cx + (a * (1 - e)) + focusOffset, cy);
      final aphe = Offset(cx - (a * (1 - e)) + focusOffset, cy);
      _tick(canvas, peri, length: 8);
      _tick(canvas, aphe, length: 8);
      _label(canvas, 'q', peri + const Offset(6, -6));
      _label(canvas, 'Q', aphe + const Offset(6, -6));
    }

    // Asteroid parametric position (eccentric anomaly approx)
    final E = asteroidTheta; // thumbnail-friendly
    final x = a * (math.cos(E) - e);
    final y = b * math.sin(E);
    final asteroidPos = Offset(cx + x + focusOffset, cy + y);

    // Comet-ish tail (short gradient strokes from previous positions)
    if (cometTail) {
      _tail(canvas,
          center: Offset(cx + focusOffset, cy), a: a, b: b, e: e, E: E);
    }

    _asteroid(canvas, asteroidPos);

    if (showAsteroidLabel) {
      final name = objectName ?? 'NEO';

      // place label away from Sun to reduce overlap
      final vx = asteroidPos.dx - center.dx;
      final vy = asteroidPos.dy - center.dy;
      // pick a direction that points further from center
      final signX = vx >= 0 ? 1.0 : -1.0;
      final signY = vy >= 0 ? 1.0 : -1.0;

      // distance the label from the dot (px)
      final labelOffset = Offset(10 * signX, -10 * signY);

      _label(canvas, name, asteroidPos + labelOffset);
    }

    // Motion line to Sun (subtle)
    _trail(canvas, asteroidPos, center);

    // Overlay label / info chip
    if (showInfoChip) {
      final name = objectName ?? 'NEO';
      _labelBox(
        canvas,
        text:
            '$name   a=${(asteroidA).toStringAsFixed(2)} AU   e=${asteroidE.toStringAsFixed(2)}',
        at: const Offset(12, 12),
      );
    }
  }

  // ---------- helpers ----------

  void _drawStars(Canvas canvas, Size size,
      {required double driftX,
      required double driftY,
      required int seed,
      int count = 60,
      double opacity = 0.5}) {
    final rnd = math.Random(seed);
    final paint = Paint();
    for (int i = 0; i < count; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final x = (baseX + driftX * (0.4 + rnd.nextDouble())) % size.width;
      final y = (baseY + driftY * (0.4 + rnd.nextDouble())) % size.height;
      final r = 0.5 + rnd.nextDouble() * 1.3;
      paint.color =
          Colors.white.withValues(alpha:  opacity * (0.4 + rnd.nextDouble() * 0.6));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _planet(Canvas c, Offset p, double r, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.black.withValues(alpha:  0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: p, radius: r * 2.2));
    c.drawCircle(p, r, paint);
  }

  void _asteroid(Canvas c, Offset p) {
    final body = Paint()..color = const Color(0xFFFFC38B);
    c.drawCircle(p, 3.5, body);
    c.drawCircle(p + const Offset(1, -1), 1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  void _trail(Canvas c, Offset pos, Offset center) {
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(pos.dx, pos.dy);
    final trail = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x00FFFFFF), Color(0x66FFFFFF)],
      ).createShader(Rect.fromPoints(center, pos))
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    c.drawPath(path, trail);
  }

  void _tick(Canvas c, Offset p, {double length = 6}) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    c.drawLine(p + Offset(0, -length / 2), p + Offset(0, length / 2), paint);
  }

  void _label(Canvas c, String text, Offset p) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, p);
  }

  void _satLabel(Canvas c, String text, Offset p) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
            color: Colors.lightBlueAccent,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, p);
  }

  void _labelBox(Canvas c, {required String text, required Offset at}) {
    final tp = TextPainter(
      text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 11),
          text: text),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 260);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(at.dx - 8, at.dy - 6, tp.width + 16, tp.height + 12),
      const Radius.circular(10),
    );
    c.drawRRect(rect, Paint()..color = const Color(0x55000000));
    tp.paint(c, at);
  }

  // small gradient tail along previous anomalies
  void _tail(Canvas c,
      {required Offset center,
      required double a,
      required double b,
      required double e,
      required double E}) {
    // draw a few segments behind current E
    const segs = 8;
    for (int k = 1; k <= segs; k++) {
      final back = E - k * 0.06; // step in radians
      final x = a * (math.cos(back) - e);
      final y = b * math.sin(back);
      final p = Offset(center.dx + x, center.dy + y);

      final alpha = (1.0 - k / (segs + 1)) * 0.7;
      final r = (4.0 - k * 0.35).clamp(1.2, 4.0);
      c.drawCircle(p, r.toDouble(),
          Paint()..color = Colors.white.withValues(alpha: alpha  * 0.25));
    }
  }

  Path _dashedPath(Path source, {double dash = 6, double gap = 4}) {
    final Path dest = Path();
    for (final m in source.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final double len = draw ? dash : gap;
        final double next = (d + len).clamp(0, m.length).toDouble();
        if (draw) dest.addPath(m.extractPath(d, next), Offset.zero);
        d = next;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _OrbitThumbPainter old) =>
      old.asteroidA != asteroidA ||
      old.asteroidE != asteroidE ||
      old.inclinationDeg != inclinationDeg ||
      old.asteroidTheta != asteroidTheta ||
      old.earthTheta != earthTheta ||
      old.showApsides != showApsides ||
      old.showMoon != showMoon ||
      old.showParallaxStars != showParallaxStars ||
      old.cometTail != cometTail ||
      old.showInfoChip != showInfoChip ||
      old.objectName != objectName ||
      old.showAsteroidLabel != showAsteroidLabel;
}
