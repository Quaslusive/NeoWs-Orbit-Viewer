import 'package:flutter/material.dart';
import 'dart:math';

class OrbitPainter extends CustomPainter {
  final double a;
  final double e;

  OrbitPainter({required this.a, required this.e});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint orbitPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint sunPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    // Center of the canvas
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final double semiMajor = size.width * 0.4;
    final double semiMinor = semiMajor * sqrt(1 - e * e);

    // Move orbit to have the sun at one focus
    final double focusOffset = e * semiMajor;
    final Rect orbitRect = Rect.fromCenter(
      center: Offset(centerX + focusOffset, centerY),
      width: 2 * semiMajor,
      height: 2 * semiMinor,
    );

    // Draw orbit
    canvas.drawOval(orbitRect, orbitPaint);

    // Draw sun
    canvas.drawCircle(Offset(centerX, centerY), 5, sunPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class OrbitProfileWidget extends StatelessWidget {
  final double a;
  final double e;

  const OrbitProfileWidget({super.key, required this.a, required this.e});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: OrbitPainter(a: a, e: e),
      size: const Size(80, 80),
    );
  }
}
