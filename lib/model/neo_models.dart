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
  final double a;   // semi-major axis (au)
  final double e;   // eccentricity
  final double i;   // inclination (deg)
  final double omega; // argument of periapsis ω (deg)
  final double Omega; // longitude of ascending node Ω (deg)
  final double M;   // mean anomaly at epoch (deg)
  final DateTime epoch; // epoch_jd or epoch_osculation

  OrbitElements({
    required this.a, required this.e, required this.i,
    required this.omega, required this.Omega, required this.M,
    required this.epoch,
  });

  factory OrbitElements.fromNeo(Map<String, dynamic> m) {
    final od = m['orbital_data'] as Map<String, dynamic>;
    // Some fields come as strings → parse carefully
    double _d(String k) => double.tryParse((od[k] ?? '0').toString()) ?? 0.0;

    // epoch as JD → convert to DateTime (rough; good enough for plotting)
    final jd = double.tryParse((od['epoch_jd'] ?? '0').toString()) ?? 0.0;
    final epoch = _jdToDate(jd);

    return OrbitElements(
      a: _d('semi_major_axis'),
      e: _d('eccentricity'),
      i: _d('inclination'),
      omega: _d('perihelion_argument'),
      Omega: _d('ascending_node_longitude'),
      M: _d('mean_anomaly'),
      epoch: epoch,
    );
  }

  static DateTime _jdToDate(double jd) {
    if (jd <= 0) return DateTime.now().toUtc();
    // JD -> Unix time conversion
    final unix = ((jd - 2440587.5) * 86400.0).round();
    return DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true);
  }
}
