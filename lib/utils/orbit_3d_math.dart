import 'dart:math' as math;
import 'mini_3d.dart';

double toRad(double d) => d * math.pi / 180.0;
const double kGauss = 0.01720209895; // rad/day
double meanMotion(double aAu) => kGauss / math.pow(aAu, 1.5);

double solveE(double M, double e) {
  double E = M;
  for (int i=0;i<12;i++) {
    final f = E - e*math.sin(E) - M;
    final fp = 1 - e*math.cos(E);
    E -= f/fp;
  }
  return E;
}

double currentTrueAnomaly({
  required double aAu, required double e,
  required double M0DegAtEpoch,
  required DateTime epochUtc,
  required DateTime tUtc,
}) {
  final dt = tUtc.difference(epochUtc).inMilliseconds / 86400000.0;
  final M = toRad(M0DegAtEpoch) + meanMotion(aAu) * dt;
  final E = solveE(M, e);
  final nu = math.atan2(math.sqrt(1-e*e)*math.sin(E), math.cos(E)-e);
  return nu;
}

/// orbital-plane point → rotate by ω (z), i (x), Ω (z)
Offset3 orbitPoint3D(double a, double e, double nu, double omega, double i, double Omega) {
  final r = a*(1-e*e)/(1+e*math.cos(nu));
  double x = r*math.cos(nu), y = r*math.sin(nu), z = 0;
  // Rz(ω)
  final co=math.cos(toRad(omega)), so=math.sin(toRad(omega));
  double x1 = x*co - y*so, y1 = x*so + y*co, z1 = z;
  // Rx(i)
  final ci=math.cos(toRad(i)), si=math.sin(toRad(i));
  double x2 = x1, y2 = y1*ci - z1*si, z2 = y1*si + z1*ci;
  // Rz(Ω)
  final cO=math.cos(toRad(Omega)), sO=math.sin(toRad(Omega));
  double xf = x2*cO - y2*sO, yf = x2*sO + y2*cO, zf = z2;
  // Swap Y/Z for nicer “up” (z-up feel)
  return Offset3(xf, zf, yf);
}
