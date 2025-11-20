import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrbitDiagram2D extends StatelessWidget {
  final double a;
  final double e;
  final Color stroke;
  final double strokeWidth;
  final bool showPlanets;
  final bool showLabels;
  final Color backgroundColor;
  final String? placeholderAsset;
  final double size;

  const OrbitDiagram2D({
    super.key,
    required this.a,
    required this.e,
    this.stroke = Colors.white,
    this.strokeWidth = 2,
    this.showPlanets = true,
    this.showLabels = false,
    this.backgroundColor = Colors.black,
    this.placeholderAsset,
    this.size = 100,
  });

  bool get _hasValidOrbit => a > 0 && e >= 0 && e < 1;

  @override
  Widget build(BuildContext context) {
    final bool labelsAllowed = showLabels && size >= 72;

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: _hasValidOrbit
              ? ColoredBox(
            color: backgroundColor,
            child: CustomPaint(
              isComplex: true,
              willChange: false,
              painter: _OrbitThumbPainter(
                a: a,
                e: e,
                stroke: stroke,
                strokeWidth: strokeWidth,
                showPlanets: showPlanets,
                showLabels: labelsAllowed,
              ),
            ),
          )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (placeholderAsset == null) {
      return ColoredBox(
        color: backgroundColor,
        child: const Center(
          child: Text('No data', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      );
    }
    return ColoredBox(
      color: backgroundColor,
      child: Image.asset(placeholderAsset!, fit: BoxFit.cover),
    );
  }
}

class _OrbitThumbPainter extends CustomPainter {
  final double a, e;
  final Color stroke;
  final double strokeWidth;
  final bool showPlanets;
  final bool showLabels;

  _OrbitThumbPainter({
    required this.a,
    required this.e,
    required this.stroke,
    required this.strokeWidth,
    required this.showPlanets,
    required this.showLabels,
  });

  static const List<_Planet> _planets = <_Planet>[
    _Planet('Mercury', 0.39, Color(0xFFB0B0B0)),
    _Planet('Venus',   0.72, Color(0xFFFFD166)),
    _Planet('Earth',   1.00, Color(0xFF006ADD)),
    _Planet('Mars',    1.52, Color(0xFFEF476F)),
  ];

/*
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 9,
    color: Colors.yellow,
    fontWeight: FontWeight.w600,
    shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
  );
*/


  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w * 0.5, cy = h * 0.5;
    final circleR = math.min(w, h) * 0.5;

    final double margin =
        1.0 + (strokeWidth * 0.5) + (showPlanets ? strokeWidth * 0.5 : 0.0);
    final double baseR = (circleR - margin).clamp(0.0, double.infinity);

    final double maxPlanetAu = showPlanets ? 1.52 : 0.0;

    // Scale so BOTH the asteroid ellipse and planet rings fit.
    // Horizontal ellipse bound: A + f = A(1+e) = a*scale*(1+e)
    final double neededAu = math.max(a * (1 + e), maxPlanetAu);
    final double auScale = neededAu > 0 ? (baseR / neededAu) : 0.0;

    // Ellipse params in px (Sun at focus on +x)
    final double A = a * auScale;                          // semi-major (px)
    final double B = A * math.sqrt(math.max(0.0, 1 - e*e));// semi-minor (px)
    final double f = e * A;                                // focus offset (px)

    // Subtle badge ring
    final ring = Paint()
      ..color = const Color(0x24FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), baseR, ring);

    // Sun
    final sun = Paint()..color = Colors.amberAccent;
    canvas.drawCircle(Offset(cx, cy), 3.2, sun);

    // Planet rings (fit via auScale)
    if (showPlanets && auScale > 0) {
      final orbitPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      final dotPaint = Paint();

      for (final p in _planets) {
        final r = p.au * auScale;
        if (r <= 0) continue;
        orbitPaint.color = p.color.withValues(alpha: 0.75);
        canvas.drawCircle(Offset(cx, cy), r, orbitPaint);

        final planetCenter = Offset(cx + r, cy);
        dotPaint.color = p.color;
        canvas.drawCircle(planetCenter, 3.0, dotPaint);

/*        if (showLabels && r + 30 < baseR) {
          final tp = TextPainter(
            text: TextSpan(text: p.name, style: _labelStyle),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: 72);
          tp.paint(canvas, planetCenter + const Offset(4, -10));
        }*/
      }
    }

    // Asteroid ellipse (fits by construction)
    if (auScale > 0 && A > 0 && B > 0) {
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
  }

  @override
  bool shouldRepaint(covariant _OrbitThumbPainter old) =>
      old.a != a ||
          old.e != e ||
          old.stroke != stroke ||
          old.strokeWidth != strokeWidth ||
          old.showPlanets != showPlanets ||
          old.showLabels != showLabels;
}

class _Planet {
  final String name;
  final double au;
  final Color color;
  const _Planet(this.name, this.au, this.color);
}
