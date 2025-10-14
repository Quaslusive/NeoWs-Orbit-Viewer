import 'dart:math' as math;
import 'mini_3d.dart'; // for Offset3

/// Gaussian gravitational constant [rad/day].
const double kGauss = 0.01720209895;

/// Mean motion from semi-major axis (AU) if you don't have el.n
double meanMotionFromA(double aAu) => kGauss / math.pow(aAu, 1.5);

/// Kepler solver: E - e sinE = M (all radians)
double solveE(double M, double e) {
  // solid initial guess helps convergence
  double E = (e < 0.8) ? M : (M > math.pi ? M - e : M + e);
  for (int i = 0; i < 12; i++) {
    final f  = E - e * math.sin(E) - M;
    final fp = 1 - e * math.cos(E);
    E -= f / fp;
  }
  // normalize to [0, 2π)
  E %= (2 * math.pi);
  if (E < 0) E += 2 * math.pi;
  return E;
}

/// True anomaly *now* using your radian-based OrbitElements.
/// Returns ν in radians.
double trueAnomalyNow({
  required double aAu,
  required double e,
  required double M0,         // radians at epoch
  required double n,          // rad/day
  required DateTime epochUtc, // epoch
  required DateTime tUtc,     // target time
}) {
  final dtDays = tUtc.difference(epochUtc).inMilliseconds / 86400000.0;
  final M = (M0 + n * dtDays) % (2 * math.pi);
  final E = solveE(M, e);
  // ν via half-angle form
  return 2.0 * math.atan2(
    math.sqrt(1 + e) * math.sin(E / 2.0),
    math.sqrt(1 - e) * math.cos(E / 2.0),
  );
}

/// 3D point in ECI/ecliptic frame from orbital elements at given ν (all radians).
/// Distances are in AU. No degree conversions here.
Offset3 orbitPoint3D(double a, double e, double nu, double omega, double i, double Omega) {
  // radius in AU (equivalent to a*(1-e*cosE) but using ν form)
  final r = a * (1 - e * e) / (1 + e * math.cos(nu));

  // perifocal coordinates (z = 0)
  final xp = r * math.cos(nu);
  final yp = r * math.sin(nu);

  // rotation matrix from perifocal -> ECI using Ω, i, ω (all radians)
  final cO = math.cos(Omega), sO = math.sin(Omega);
  final ci = math.cos(i),     si = math.sin(i);
  final cw = math.cos(omega), sw = math.sin(omega);

  final r11 = cO*cw - sO*sw*ci;
  final r12 = -cO*sw - sO*cw*ci;
  final r21 = sO*cw + cO*sw*ci;
  final r22 = -sO*sw + cO*cw*ci;
  final r31 = sw*si;
  final r32 = cw*si;

  final x = r11 * xp + r12 * yp;
  final y = r21 * xp + r22 * yp;
  final z = r31 * xp + r32 * yp;

  // If your renderer expects z-up feel (swap y/z), keep the swap:
  return Offset3(x, z, y);
}

/* ---------------------------
   OPTIONAL: compatibility shims
   Keep temporarily if some old callsites still pass DEGREES.
   Remove once all callers use radians.
----------------------------*/

double _toRad(double d) => d * math.pi / 180.0;

/// Old signature -> new (degrees in)
@deprecated
double currentTrueAnomaly({
  required double aAu,
  required double e,
  required double M0DegAtEpoch,
  required DateTime epochUtc,
  required DateTime tUtc,
}) {
  final n = meanMotionFromA(aAu); // best-effort if you don't have el.n
  return trueAnomalyNow(
    aAu: aAu,
    e: e,
    M0: _toRad(M0DegAtEpoch),
    n: n,
    epochUtc: epochUtc,
    tUtc: tUtc,
  );
}

/// Old degree-based point -> new radian version
@deprecated
Offset3 orbitPoint3Ddeg(double a, double e, double nuDeg, double omegaDeg, double iDeg, double OmegaDeg) {
  return orbitPoint3D(a, e, _toRad(nuDeg), _toRad(omegaDeg), _toRad(iDeg), _toRad(OmegaDeg));
}
