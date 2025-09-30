import 'dart:math' as math;

/// Gravitational parameter μ (Sun) in AU^3/day^2.
/// Using k = 0.01720209895 (Gaussian gravitational constant):
/// n = k / a^{3/2}; M(t) = M0 + n * (t - t0) in days.
const double kGauss = 0.01720209895;

double meanMotionAUPerDay(double a) => kGauss / math.pow(a, 1.5);

/// Solve Kepler’s equation M = E - e sin E for eccentric anomaly E
double solveKepler(double M, double e, {int iters = 12}) {
  // M in radians
  double E = M; // good initial guess for small e
  for (int i = 0; i < iters; i++) {
    final f = E - e * math.sin(E) - M;
    final fp = 1 - e * math.cos(E);
    E -= f / fp;
  }
  return E;
}

double trueAnomalyFromMean(double M, double e) {
  final E = solveKepler(M, e);
  final cosE = math.cos(E);
  final sinE = math.sin(E);
  final beta = math.sqrt(1 - e * e);
  final cosNu = (cosE - e) / (1 - e * cosE);
  final sinNu = (beta * sinE) / (1 - e * cosE);
  return math.atan2(sinNu, cosNu); // radians
}

/// Get current true anomaly (radians) at time tUtc for orbit with (a,e,M0,epoch).
double currentTrueAnomaly({
  required double aAu,
  required double e,
  required double M0DegAtEpoch,
  required DateTime epochUtc,
  required DateTime tUtc,
}) {
  final dtDays = tUtc.difference(epochUtc).inMilliseconds / 86400000.0;
  final n = meanMotionAUPerDay(aAu); // rad/day (since M is in rad if we use radians)
  final M0 = M0DegAtEpoch * math.pi / 180.0;
  final M = M0 + n * dtDays;
  return trueAnomalyFromMean(M, e);
}

/// Parametric point (AU) on ellipse in orbital plane (ignoring i,Ω,ω for 2D)
/// If you want rotation: rotate by (Ω + ω) in the XY plane.
({double x, double y}) ellipsePointAU(double a, double e, double nuRad) {
  final r = a * (1 - e * e) / (1 + e * math.cos(nuRad));
  return (x: r * math.cos(nuRad), y: r * math.sin(nuRad));
}

/// Rotate 2D by angle (radians)
({double x, double y}) rot2D(double x, double y, double angRad) {
  final c = math.cos(angRad), s = math.sin(angRad);
  return (x: x * c - y * s, y: x * s + y * c);
}
