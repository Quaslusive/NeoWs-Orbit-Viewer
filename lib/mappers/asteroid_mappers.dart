import 'dart:math' as math;
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/service/asterank_api_service.dart'; // for MpcRow

// ---------------- Helpers ----------------

// D(km) = 1329/sqrt(p) * 10^(-H/5), p ≈ 0.14 for NEOs
double _estimateDiameterKmFromH(double h, {double p = 0.14}) {
  if (p <= 0) p = 0.14;
  return 1329.0 / math.sqrt(p) * math.pow(10.0, -h / 5.0) as double;
}

// ---------------- NeoWs -> Asteroid ----------------

Asteroid asteroidFromNeowsMap(Map<String, dynamic> m) {
  final name = (m['name'] ?? 'Unknown').toString();

  // diameter (avg of min/max), kilometers
  double diameterKm = 0.0;
  final km = m['estimated_diameter']?['kilometers'];
  final dMin = (km?['estimated_diameter_min'] as num?)?.toDouble();
  final dMax = (km?['estimated_diameter_max'] as num?)?.toDouble();
  if (dMin != null && dMax != null) diameterKm = (dMin + dMax) / 2.0;

  final pha = (m['is_potentially_hazardous_asteroid'] == true) ? 'Y' : 'N';

  return Asteroid(
    id: name,
    name: name,
    fullName: name,
    diameter: diameterKm,   // km
    albedo: 0.0,
    neo: 'Y',
    pha: pha,
    rotationPeriod: 0.0,
    classType: 'NeoWs',
    orbitId: 0,
    moid: 0.0,              // NeoWs /feed doesn’t include MOID
    a: 0.0,
    e: 0.0,
    i: 0.0,
  );
}

// ---------------- MPC (typed: MpcRow) -> Asteroid ----------------

Asteroid _asteroidFromMpcRow(MpcRow r) {
  // Try to read absolute magnitude H if present on the type
  double? h;
  try {
    final v = (r as dynamic).H;
    if (v is num) h = v.toDouble();
  } catch (_) {}
  if (h == null) {
    try {
      final v = (r as dynamic).h;
      if (v is num) h = v.toDouble();
    } catch (_) {}
  }

  // Diameter (km) estimated from H if available; else unknown (0.0)
  final diameterKm = (h != null) ? _estimateDiameterKmFromH(h) : 0.0;

  final display = (r.readableDes ?? r.des ?? 'Unknown');
  final moid = r.moid ?? 0.0;
  final a = r.a ?? 0.0;
  final e = r.e ?? 0.0;
  final inc = r.i ?? 0.0;

  // Neo flag from perihelion distance q = a(1-e) < 1.3 au (optional)
  String neoFlag = 'unknown';
  if (a > 0 && e >= 0) {
    final q = a * (1 - e);
    neoFlag = (q <= 1.3) ? 'Y' : 'N';
  }

  // Derive PHA when raw flag isn’t provided:
  // PHA if (MOID ≤ 0.05 au) AND (diameter ≥ 0.14 km ~ 140 m)
  // If diameter is unknown (0), this will be N (conservative).
  String phaFlag = 'N';
  try {
    final raw = (r as dynamic).pha;
    if (raw is bool) {
      phaFlag = raw ? 'Y' : 'N';
    } else if (raw is String) {
      final s = raw.toLowerCase();
      if (s == 'y' || s == 'true' || s == '1') phaFlag = 'Y';
      if (s == 'n' || s == 'false' || s == '0') phaFlag = 'N';
    }
  } catch (_) {}
  if (phaFlag == 'N') {
    final moidClose = (moid > 0 && moid <= 0.05);
    final bigEnough = (diameterKm >= 0.14);
    if (moidClose && bigEnough) phaFlag = 'Y';
  }

  return Asteroid(
    id: r.des ?? display,
    name: display,
    fullName: display,
    diameter: diameterKm,   // km
    albedo: 0.0,
    neo: neoFlag,
    pha: phaFlag,
    rotationPeriod: 0.0,
    classType: 'MPC',
    orbitId: 0,
    moid: moid,
    a: a,
    e: e,
    i: inc,
  );
}

// If you still need a Map-based MPC mapper (not required if your service returns MpcRow):
Asteroid asteroidFromMpcMap(Map<String, dynamic> m) {
  final display = (m['readable_des'] ?? m['des'] ?? 'Unknown').toString();

  final a    = (m['a'] as num?)?.toDouble() ?? 0.0;
  final e    = (m['e'] as num?)?.toDouble() ?? 0.0;
  final inc  = (m['i'] as num?)?.toDouble() ?? 0.0;
  final moid = (m['moid'] as num?)?.toDouble() ?? 0.0;
  final h    = (m['H'] as num?)?.toDouble();

  final diameterKm = (h != null) ? _estimateDiameterKmFromH(h) : 0.0;

  String neoFlag = 'unknown';
  if (a > 0 && e >= 0) {
    final q = a * (1 - e);
    neoFlag = (q <= 1.3) ? 'Y' : 'N';
  }

  String phaFlag = 'N';
  final phaRaw = m['pha'];
  if (phaRaw is bool) {
    phaFlag = phaRaw ? 'Y' : 'N';
  } else if (phaRaw is String) {
    final s = phaRaw.toLowerCase();
    if (s == 'y' || s == 'true' || s == '1') phaFlag = 'Y';
    if (s == 'n' || s == 'false' || s == '0') phaFlag = 'N';
  }
  if (phaFlag == 'N') {
    final moidClose = (moid > 0 && moid <= 0.05);
    final bigEnough = (diameterKm >= 0.14);
    if (moidClose && bigEnough) phaFlag = 'Y';
  }

  return Asteroid(
    id: (m['des'] ?? display).toString(),
    name: display,
    fullName: display,
    diameter: diameterKm,
    albedo: 0.0,
    neo: neoFlag,
    pha: phaFlag,
    rotationPeriod: 0.0,
    classType: 'MPC',
    orbitId: 0,
    moid: moid,
    a: a,
    e: e,
    i: inc,
  );
}


/// Convenience: map a list of MPC items (Map form)
List<Asteroid> asteroidsFromMpcList(List<Map<String, dynamic>> items) =>
    items.map(asteroidFromMpcMap).toList();
/*

/// ---------- Offline CSV -> Asteroid ----------
/// Matches your current CSV indexes from earlier code:
/// id(0), fullName(2), name(4), e(32), a(33), orbitId(27),
/// diameter(15), albedo(17), pha(7), neo(6), rotationPeriod(18),
/// moid(45), classType(60)
Asteroid asteroidFromCsvRow(List<dynamic> row) {
  String s(int idx) => _toString(idx < row.length ? row[idx] : null, fallback: '');
  double d(int idx) => _toDouble(idx < row.length ? row[idx] : null);
  int i(int idx) => (idx < row.length ? int.tryParse(row[idx].toString()) : null) ?? 0;

  final id = s(0);
  final name = s(4).isNotEmpty ? s(4) : (s(2).isNotEmpty ? s(2) : id);

  return Asteroid(
    id: id,
    name: name,
    fullName: s(2).isNotEmpty ? s(2) : name,
    diameter: d(15),
    albedo: d(17),
    neo: s(6).isNotEmpty ? s(6) : 'unknown',
    pha: s(7).isNotEmpty ? s(7) : 'unknown',
    rotationPeriod: d(18),
    classType: s(60).isNotEmpty ? s(60) : 'CSV',
    orbitId: i(27),
    moid: d(45),
    a: d(33),
    e: d(32),
    i: d(31),
  );
}

/// Convenience: map a CSV (first row header) to Asteroids (skips header)
List<Asteroid> asteroidsFromCsvTable(List<List<dynamic>> table) {
  if (table.isEmpty) return const [];
  final List<Asteroid> out = [];
  for (int r = 1; r < table.length; r++) {
    out.add(asteroidFromCsvRow(table[r]));
  }
  return out;
}
*/
