import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:neows_app/neows/neo_models.dart';

class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);
}

// Solve Kepler’s equation: E - e sinE = M   (all radians)
double _solveKepler(double M, double e, {int iters = 8}) {
  var E = (e < 0.8) ? M : (M > pi ? M - e : M + e);
  for (var k = 0; k < iters; k++) {
    final f = E - e * sin(E) - M;
    final fp = 1 - e * cos(E);
    E -= f / fp;
  }
  // normalize for numeric stability
  E %= (2 * pi);
  if (E < 0) E += 2 * pi;
  return E;
}

/// Rotate from perifocal (P,Q,W) to ECI using Ω, i, ω (all radians)
/// We precompute the rotation matrix terms for speed.
({double r11,double r12,double r21,double r22,double r31,double r32})
_rotationPQW(double Omega, double i, double omega) {
  final cO = cos(Omega), sO = sin(Omega);
  final ci = cos(i),     si = sin(i);
  final cw = cos(omega), sw = sin(omega);

  return (
  r11: cO*cw - sO*sw*ci,
  r12: -cO*sw - sO*cw*ci,
  r21: sO*cw + cO*sw*ci,
  r22: -sO*sw + cO*cw*ci,
  r31: sw*si,
  r32: cw*si,
  );
}

/// Synchronous sampler (runs in an isolate via `compute`)
List<Vec3> _sampleOrbitSync((OrbitElements el, int steps, DateTime t) args) {
  final el    = args.$1;
  final steps = args.$2;
  final t     = args.$3.toUtc();

  // Mean anomaly at time t
  final M_now = el.meanAnomalyAt(t);

  // Precompute rotation
  final R = _rotationPQW(el.Omega, el.i, el.omega);

  final out = <Vec3>[];
  // sweep the orbit uniformly in mean anomaly around the current M
  for (var s = 0; s < steps; s++) {
    final d = (s / steps) * 2 * pi;
    final M = (M_now + d) % (2 * pi);

    final E  = _solveKepler(M, el.e);
    final cosE = cos(E);

    // distance in AU
    final r = el.a * (1 - el.e * cosE);

    // true anomaly (radians)
    final nu = 2.0 * atan2(
      sqrt(1 + el.e) * sin(E / 2.0),
      sqrt(1 - el.e) * cos(E / 2.0),
    );
    // perifocal coords (z = 0)
    final xp = r * cos(nu);
    final yp = r * sin(nu);

    final x = R.r11 * xp + R.r12 * yp;
    final y = R.r21 * xp + R.r22 * yp;
    final z = R.r31 * xp + R.r32 * yp;

    out.add(Vec3(x, y, z));
  }
  return out;
}

Vec3 positionAt(OrbitElements el, DateTime t) {
  final tU = t.toUtc();
  final M = el.meanAnomalyAt(tU);
  final E = _solveKepler(M, el.e);
  final cosE = cos(E);

  final r = el.a * (1 - el.e * cosE);
  final nu = 2.0 * atan2(
    sqrt(1 + el.e) * sin(E / 2.0),
    sqrt(1 - el.e) * cos(E / 2.0),
  );

  final xp = r * cos(nu);
  final yp = r * sin(nu);

  final R = _rotationPQW(el.Omega, el.i, el.omega);
  final x = R.r11 * xp + R.r12 * yp;
  final y = R.r21 * xp + R.r22 * yp;
  final z = R.r31 * xp + R.r32 * yp;

  return (Vec3(x, y, z)); // same frame as polyline
}


/// Public API: sample a polyline of the orbit at time `t` (radians/AU).
Future<List<Vec3>> sampleOrbit(OrbitElements el, DateTime t, {int steps = 720}) {
  return compute(_sampleOrbitSync, (el, steps, t));
}
