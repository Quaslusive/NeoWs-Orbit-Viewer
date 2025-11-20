import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Gaussian gravitational constant [rad/day], suitable for n ≈ k / a^(3/2) with a in AU.
const double _kGaussian = 0.01720209895;

double _toDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

double _deg2rad(num d) => d * math.pi / 180.0;
// double _rad2deg(num r) => r * 180.0 / math.pi;

// Normalize angle to [0, 2π)
double _normTau(double r) {
  r = r % (2 * math.pi);
  return (r < 0) ? r + 2 * math.pi : r;
}

DateTime _jdToUtc(double jd) {
  if (jd <= 0) return DateTime.now().toUtc();
  final ms = (jd - 2440587.5) * 86400000.0; // days → ms
  return DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: true);
}

DateTime _mjdToUtc(double mjd) => _jdToUtc(mjd + 2400000.5);

DateTime _parseEpochNeo(Map<String, dynamic> od) {
  //  ISO first (epoch_osculation or epoch)
  final iso = od['epoch_osculation'] ?? od['epoch'];
  if (iso != null) {
    try { return DateTime.parse(iso.toString()).toUtc(); } catch (_) {}
  }
  //  Numeric epochs (prefer MJD if present)
  final mjd = _toDouble(od['epoch_mjd']);
  if (mjd > 0) return _mjdToUtc(mjd);

  final jd = _toDouble(od['epoch_jd']);
  if (jd > 0) return _jdToUtc(jd);

  return DateTime.now().toUtc();
}

@immutable
class NeoFull {
  final String id;
  final String name;
  final bool isHazardous;
  final String? designation;
  final double? H;
  final double? diameterKm;
  final String? spectralClass;
  final int? orbitId;

  const NeoFull({
    required this.id,
    required this.name,
    required this.isHazardous,
    this.designation,
    this.H,
    this.diameterKm,
    this.spectralClass,
    this.orbitId,
  });
}

class NeoLite {
  final String id;
  final String name;
  final bool isHazardous;

  NeoLite({required this.id, required this.name, required this.isHazardous});

  factory NeoLite.fromFeed(Map<String, dynamic> m) {
    return NeoLite(
      id: m['id'] as String,
      name: (m['name'] ?? '').toString(),
      isHazardous: (m['is_potentially_hazardous_asteroid'] ?? false) as bool,
    );
  }
}

class OrbitElements {
  // Frame: heliocentric ecliptic J2000 (NeoWs / JPL SBDB).
  final double a;       // semi-major axis [AU]
  final double e;       // eccentricity
  final double i;       // inclination [rad]
  final double omega;   // argument of periapsis ω [rad]
  final double Omega;   // longitude of ascending node Ω [rad]
  final double M0;      // mean anomaly at epoch [rad]
  final DateTime epoch; // UTC
  final double n;       // mean motion [rad/day]

  const OrbitElements({
    required this.a,
    required this.e,
    required this.i,
    required this.omega,
    required this.Omega,
    required this.M0,
    required this.epoch,
    required this.n,
  });


  /// Mean anomaly at time `t` (UTC), wrapped to [0, 2π).
  double meanAnomalyAt(DateTime t) {
    final tUtc = t.toUtc();
    final dtMs = tUtc.millisecondsSinceEpoch - epoch.millisecondsSinceEpoch;
    final dtDays = dtMs / 86400000.0;
    return _normTau(M0 + n * dtDays);
  }


  /// Create from a NeoWs "lookup" JSON (m), e.g. /neo/rest/v1/neo/{id}
  /// Also works if you pass m['orbital_data'] directly.
  factory OrbitElements.fromNeo(Map<String, dynamic> m) {
    final od = (m['orbital_data'] is Map<String, dynamic>)
        ? m['orbital_data'] as Map<String, dynamic>
        : m;

    // NeoWs uses strings for many numbers—parse defensively.
    final aAu   = _toDouble(od['semi_major_axis']);
    final ecc   = _toDouble(od['eccentricity']);
  //  final inc   = _deg2rad(_toDouble(od['inclination']));

    double _readAngleDeg(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null) return _toDouble(v);
      }
      return 0.0;
    }


    final incDeg = _readAngleDeg(od, ['inclination']);
    final inc    = _deg2rad(incDeg);

    final argpDeg = _readAngleDeg(od, [
      'argument_of_periapsis',
      'perihelion_argument',
      'periastron_argument',
    ]);
    final argp = _deg2rad(argpDeg);
    final ascDeg = _readAngleDeg(od, ['ascending_node_longitude']);
    final asc    = _deg2rad(ascDeg);
    final M0Deg = _readAngleDeg(od, ['mean_anomaly']);
    final M0    = _normTau(_deg2rad(M0Deg));

    // mean_motion may be deg/day. Convert to rad/day.
    final nProvidedDeg = _toDouble(od['mean_motion']);
    final periodDays   = _toDouble(od['orbital_period']); // days

    final double nRad = (nProvidedDeg != 0.0)
        ? _deg2rad(nProvidedDeg)
        : (periodDays > 0)
        ? (2 * math.pi) / periodDays
        : (aAu > 0 ? _kGaussian / math.pow(aAu, 1.5) : 0.0);

   final epoch = _parseEpochNeo(od);
/*
    debugPrint(
      '—————neo_model input—————\n'
        'aAu: $aAu \n'
            'ecc: $ecc \n'
            'inc: $inc \n'
            'argp: $argp \n'
            'asc: $asc \n'
            '_normTau: $M0 \n'
            'epoch: $epoch \n'
            'n: $nRad \n'
          '—————END INPUT—————'
    );*/
    return OrbitElements(
      a: aAu,
      e: ecc,
      i: inc,
      omega: argp,
      Omega: asc,
      M0: _normTau(M0),
     // M0: M0,
      epoch: epoch,
      n: nRad,
    );
  }
}
