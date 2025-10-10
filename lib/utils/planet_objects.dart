import 'dart:math' as math;
import 'package:flutter/material.dart';

// Gaussian gravitational constant [rad/day]
const double _kGauss = 0.01720209895;

// J2000 epoch (~UTC is fine for visualization)
final DateTime _j2000 = DateTime.utc(2000, 1, 1, 12, 0, 0);

// Helper
double _deg2rad(num d) => d * math.pi / 180.0;

/// Radian-native planet elements for rendering/propagation.
///
/// All angles are **radians**, distances **AU**, n in **rad/day**.
class Planet {
  final String name;
  final double a;      // AU
  final double e;      // unitless
  final double i;      // rad
  final double omega;  // rad (argument of periapsis, ω)
  final double Omega;  // rad (longitude of ascending node, Ω)
  final double M0;     // rad (mean anomaly at epoch)
  final double n;      // rad/day (mean motion)
  final DateTime epoch;
  final Color color;
  final double radiusPx;

  const Planet({
    required this.name,
    required this.a,
    required this.e,
    required this.i,
    required this.omega,
    required this.Omega,
    required this.M0,
    required this.n,
    required this.epoch,
    required this.color,
    required this.radiusPx,
  });

  /// Convenience: construct from **degrees** + optional `n`.
  /// If `nDegPerDay` is null, it will be computed from `a`.
  factory Planet.deg({
    required String name,
    required double a,
    required double e,
    required double iDeg,
    required double omegaDeg,
    required double OmegaDeg,
    required double M0Deg,
    double? nDegPerDay,       // optional; if missing, compute
    required DateTime epoch,
    required Color color,
    required double radiusPx,
  }) {
    final nRad = (nDegPerDay != null)
        ? _deg2rad(nDegPerDay)
        : _kGauss / math.pow(a, 1.5); // fallback from a

    return Planet(
      name: name,
      a: a,
      e: e,
      i: _deg2rad(iDeg),
      omega: _deg2rad(omegaDeg),
      Omega: _deg2rad(OmegaDeg),
      M0: _deg2rad(M0Deg),
      n: nRad,
      epoch: epoch,
      color: color,
      radiusPx: radiusPx,
    );
  }

  /// Mean anomaly at time `tUtc` (radians).
  double meanAnomalyAt(DateTime tUtc) {
    final dtDays = tUtc.difference(epoch).inMilliseconds / 86400000.0;
    var m = (M0 + n * dtDays) % (2 * math.pi);
    if (m < 0) m += 2 * math.pi;
    return m;
  }
}

// ----------------- COLORS -----------------
const _mercury = Color(0xFF9E9E9E);
const _venus   = Color(0xFFEED6A3);
const _earth   = Color(0xFF66CCFF);
const _mars    = Color(0xFFE07A5F);
const _jupiter = Color(0xFFDAB07E);
const _saturn  = Color(0xFFF3E2A9);
const _uranus  = Color(0xFF6AD2C9);
const _neptune = Color(0xFF5CA2F1);

// ----------------- DATA -----------------
// Your original element values were degrees; we now call Planet.deg(...)
final List<Planet> innerPlanets = [
  Planet.deg(
    name: 'Mercury',
    a: 0.38709893,
    e: 0.20563069,
    iDeg: 7.00487,
    omegaDeg: 29.12478,
    OmegaDeg: 48.33167,
    M0Deg: 174.79588,
    epoch: _j2000,
    color: _mercury,
    radiusPx: 3.0,
  ),
  Planet.deg(
    name: 'Venus',
    a: 0.72333199,
    e: 0.00677323,
    iDeg: 3.39471,
    omegaDeg: 54.85229,
    OmegaDeg: 76.68069,
    M0Deg: 50.115,
    epoch: _j2000,
    color: _venus,
    radiusPx: 4.0,
  ),
  Planet.deg(
    name: 'Earth',
    a: 1.00000011,
    e: 0.01671022,
    iDeg: 0.00005,
    omegaDeg: 102.94719,
    OmegaDeg: 0.0,
    M0Deg: 357.517,
    epoch: _j2000,
    color: _earth,
    radiusPx: 4.0,
  ),
  Planet.deg(
    name: 'Mars',
    a: 1.52366231,
    e: 0.09341233,
    iDeg: 1.85061,
    omegaDeg: 286.46230,
    OmegaDeg: 49.57854,
    M0Deg: 19.41248,
    epoch: _j2000,
    color: _mars,
    radiusPx: 3.5,
  ),
  Planet.deg(
    name: 'Jupiter',
    a: 5.20260,
    e: 0.048498,
    iDeg: 1.303,
    omegaDeg: 273.867,
    OmegaDeg: 100.492,
    M0Deg: 19.8950,
    epoch: _j2000,
    color: _jupiter,
    radiusPx: 5.0,
  ),
  Planet.deg(
    name: 'Saturn',
    a: 9.5549,
    e: 0.055508,
    iDeg: 2.489,
    omegaDeg: 339.392,
    OmegaDeg: 113.642,
    M0Deg: 317.0207,
    epoch: _j2000,
    color: _saturn,
    radiusPx: 5.0,
  ),
  Planet.deg(
    name: 'Uranus',
    a: 19.2184,
    e: 0.046295,
    iDeg: 0.773,
    omegaDeg: 96.998857,
    OmegaDeg: 74.016,
    M0Deg: 142.2386,
    epoch: _j2000,
    color: _uranus,
    radiusPx: 4.5,
  ),
  Planet.deg(
    name: 'Neptune',
    a: 30.1104,
    e: 0.008988,
    iDeg: 1.770,
    omegaDeg: 276.336,
    OmegaDeg: 131.784,
    M0Deg: 256.228,
    epoch: _j2000,
    color: _neptune,
    radiusPx: 4.5,
  ),
];
