import 'dart:math';

/// Gaussian gravitational constant [rad/day], suitable for n ≈ k / a^(3/2) with a in AU.
const double _GAUSSIAN_K = 0.01720209895;

double _toDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

double _deg2rad(num d) => d * pi / 180.0;
double _rad2deg(num r) => r * 180.0 / pi;

/// Convert Julian Day to UTC DateTime.
DateTime _jdToUtc(double jd) {
  if (jd <= 0) return DateTime.now().toUtc();
  final unixSec = (jd - 2440587.5) * 86400.0;
  return DateTime.fromMillisecondsSinceEpoch(unixSec.round() * 1000, isUtc: true);
}

/// Parse an epoch from NeoWs fields: prefers ISO string (`epoch_osculation`),
/// falls back to JD (`epoch_jd`), or `orbit_determination_date`.
DateTime _parseEpochNeo(Map<String, dynamic> od) {
  final iso = od['epoch_osculation'] ?? od['epoch'] ?? od['orbit_determination_date'];
  if (iso != null) {
    try {
      return DateTime.parse(iso.toString()).toUtc();
    } catch (_) {/* fall through */}
  }
  final jd = _toDouble(od['epoch_jd']);
  return _jdToUtc(jd);
}

/// Your existing lite entry; keep as-is.
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

/// Normalized orbital elements for rendering/propagation.
/// - Distances in AU
/// - Angles in radians
/// - Mean motion `n` in rad/day
/// - `epoch` as UTC DateTime
class OrbitElements {
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

  /// Backward-compat degree getters (handy for labels/UI).
  double get iDeg => _rad2deg(i);
  double get omegaDeg => _rad2deg(omega);
  double get OmegaDeg => _rad2deg(Omega);
  double get MDeg => _rad2deg(M0);

  /// Mean anomaly at time `t` (UTC), with `n` in rad/day.
  double meanAnomalyAt(DateTime t) {
    final dtDays = t.difference(epoch).inMilliseconds / 86400000.0;
    // Wrap to [0, 2π) for neatness
    final m = M0 + n * dtDays;
    return m % (2 * pi);
  }

  /// Create from a NeoWs "lookup" JSON (m), e.g. /neo/rest/v1/neo/{id}
  /// Also works if you pass m['orbital_data'] directly.
  factory OrbitElements.fromNeo(Map<String, dynamic> m) {
    final od = (m['orbital_data'] is Map<String, dynamic>)
        ? m['orbital_data'] as Map<String, dynamic>
        : m;

    // NeoWs uses strings for many numbers—parse defensively.
    final aAu   = _toDouble(od['semi_major_axis']);            // AU
    final ecc   = _toDouble(od['eccentricity']);
    final inc   = _deg2rad(_toDouble(od['inclination']));

    // Argument of periapsis can appear under either key:
    final argp  = _deg2rad(_toDouble(
      od['perihelion_argument'] ?? od['periastron_argument'],
    ));

    final asc   = _deg2rad(_toDouble(od['ascending_node_longitude']));
    final Mdeg  = _toDouble(od['mean_anomaly']);
    final M0    = _deg2rad(Mdeg);

    // Mean motion may be provided in deg/day; convert to rad/day.
    final nProvidedDeg = _toDouble(od['mean_motion']);
    final nRad = (nProvidedDeg != 0.0)
        ? _deg2rad(nProvidedDeg)
        : (aAu > 0 ? _GAUSSIAN_K / pow(aAu, 1.5) : 0.0);

    final epoch = _parseEpochNeo(od);

    return OrbitElements(
      a: aAu,
      e: ecc,
      i: inc,
      omega: argp,
      Omega: asc,
      M0: M0,
      epoch: epoch,
      n: nRad,
    );
  }
}
