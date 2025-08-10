import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrbitDiagram2D extends StatelessWidget {
  final double a;                 // semi-major axis (AU)
  final double e;                 // eccentricity [0,1)
  final Color stroke;             // orbit line color (fixed)
  final double strokeWidth;       // orbit line width
  final bool showPlanets;         // show Mercury..Mars
  final Color backgroundColor;    // circular background
  final String? placeholderAsset; // shown when a/e invalid
  final double size;              // square size of the badge

  const OrbitDiagram2D({
    super.key,
    required this.a,
    required this.e,
    this.stroke = Colors.white,
    this.strokeWidth = 2,
    this.showPlanets = true,
    this.backgroundColor = Colors.black,
    this.placeholderAsset,        // e.g. 'lib/assets/images/orbit_placeholder.png'
    this.size = 100,
  });

  bool get _hasValidOrbit => a > 0 && e >= 0 && e < 1;

  @override
  Widget build(BuildContext context) {
    // Circular badge with clip
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: _hasValidOrbit
              ? Container(
            color: backgroundColor, // solid background behind orbit lines
            child: CustomPaint(
              painter: _OrbitThumbPainter(
                a: a,
                e: e,
                stroke: stroke,
                strokeWidth: strokeWidth,
                showPlanets: showPlanets,
              ),
            ),
          )
              : _buildPlaceholder(), // only when no valid data
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (placeholderAsset == null) {
      // fallback: simple dark circle with "No data"
      return Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          'No data',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }
    return Container(
      color: backgroundColor,
      child: Image.asset(
        placeholderAsset!,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _OrbitThumbPainter extends CustomPainter {
  final double a, e;
  final Color stroke;
  final double strokeWidth;
  final bool showPlanets;

  _OrbitThumbPainter({
    required this.a,
    required this.e,
    required this.stroke,
    required this.strokeWidth,
    required this.showPlanets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Fit ellipse nicely in the circular badge
    final maxR = math.min(w, h) * 0.45;

    // Orbit ellipse params (thumbnail-friendly scale)
    final A = maxR;                                   // visual semi-major in px
    final B = A * math.sqrt(math.max(0, 1 - e * e));  // semi-minor
    final f = e * A;                                  // focus offset (Sun at focus)

    // Background accent ring (subtle)
    final ring = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), maxR, ring);

    // Sun
    final sun = Paint()..color = Colors.amberAccent;
    canvas.drawCircle(Offset(cx, cy), 3.2, sun);

    // Inner planets (approx mean orbital radii in AU)
    if (showPlanets) {
      // Scale so Mars (~1.52 AU) fits inside badge
      final double auScale = maxR / 1.6;

      final planets = <_Planet>[
        _Planet('Mercury', 0.39, const Color(0xFFB0B0B0)),
        _Planet('Venus',   0.72, const Color(0xFFFFD166)),
        _Planet('Earth',   1.00, const Color(0xFF4DA3FF)),
        _Planet('Mars',    1.52, const Color(0xFFEF476F)),
      ];

      for (final p in planets) {
        final r = p.au * auScale;

        // thin orbit ring
        final orbitPaint = Paint()
          ..color = p.color.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(Offset(cx, cy), r, orbitPaint);

        // dot on +x for clarity (thumbnail)
        final planetCenter = Offset(cx + r, cy);
        final dot = Paint()..color = p.color;
        canvas.drawCircle(planetCenter, 3.0, dot);

        // label
        final tp = TextPainter(
          text: TextSpan(
            text: p.name,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: 72);
        tp.paint(canvas, planetCenter + const Offset(4, -10));
      }
    }

    // Asteroid orbit (ellipse with Sun at a focus)
    final orbitPaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = Rect.fromCenter(
      center: Offset(cx + f, cy),
      width: 2 * A,
      height: 2 * B,
    );
    canvas.drawOval(rect, orbitPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitThumbPainter old) =>
      old.a != a ||
          old.e != e ||
          old.stroke != stroke ||
          old.strokeWidth != strokeWidth ||
          old.showPlanets != showPlanets;
}

class _Planet {
  final String name;
  final double au;
  final Color color;
  const _Planet(this.name, this.au, this.color);
}
