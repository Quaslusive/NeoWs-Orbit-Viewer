import 'package:flutter/material.dart';
import 'dart:math';

class OrbitPainter extends CustomPainter {
  final double semiMajorAxis; // a (AU)
  final double eccentricity; // e

  OrbitPainter({required this.semiMajorAxis, required this.eccentricity});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint orbitPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke;

    final Paint sunPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    // Scale AU to pixels
    double scale = 100;
    double a = semiMajorAxis * scale;
    double b = a * sqrt(1 - pow(eccentricity, 2)); // semi-minor axis
    double focusOffset = a * eccentricity;

    // Canvas center
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Orbit position (centered around one focus)
    final Rect orbitRect = Rect.fromCenter(
      center: Offset(center.dx + focusOffset, center.dy),
      width: 2 * a,
      height: 2 * b,
    );

    canvas.drawOval(orbitRect, orbitPaint);
    canvas.drawCircle(center, 6, sunPaint); // The Sun
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
