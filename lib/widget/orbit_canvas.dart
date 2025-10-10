import 'package:flutter/material.dart';
import 'package:neows_app/utils/orbit_math.dart';

class OrbitCanvas3D extends StatelessWidget {
  final List<Vec3> points; // AU
  final double scale;      // AU -> px
  final bool showAxes;

  const OrbitCanvas3D({
    super.key,
    required this.points,
    this.scale = 120.0,
    this.showAxes = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OrbitPainter(points: points, scale: scale, showAxes: showAxes),
      child: Container(),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final List<Vec3> points;
  final double scale;
  final bool showAxes;

  _OrbitPainter({required this.points, required this.scale, required this.showAxes});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width/2, size.height/2);

    if (showAxes) {
      final axis = Paint()..color = Colors.white.withOpacity(0.25)..strokeWidth = 1;
      canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), axis);
      canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), axis);
      canvas.drawCircle(c, 2, Paint()..color = Colors.yellowAccent); // Sun
    }

    if (points.isEmpty) return;

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.blueAccent;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final v = points[i];
      final o = Offset(c.dx + v.x * scale, c.dy - v.y * scale); // drop z (ortho)
      if (i == 0) path.moveTo(o.dx, o.dy); else path.lineTo(o.dx, o.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => false;
}
