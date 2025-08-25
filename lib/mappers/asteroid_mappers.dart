import 'dart:math' as math;
import 'package:neows_app/model/asteroid_csv.dart';

/// ---------- Helpers ----------
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String _toString(dynamic v, {String fallback = 'Unknown'}) {
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

/// Estimate diameter (km) from absolute magnitude H and geometric albedo p.
/// Default p=0.14 (typical NEO). D(km) = 1329/sqrt(p) * 10^(-H/5)
double _estimateDiameterFromH(double? H, {double p = 0.14}) {
  if (H == null) return 0.0;
  if (p <= 0) p = 0.14;
  return 1329.0 / math.sqrt(p) * math.pow(10.0, -H / 5.0) as double;
}

/// ---------- NeoWs -> Asteroid ----------
/// Expects a single object from /neo/rest/v1/feed flattened list.
Asteroid asteroidFromNeowsMap(Map<String, dynamic> m) {
  final name = _toString(m['name'], fallback: 'Unknown');

  // diameter (avg of min/max, kilometers)
  double diameterKm = 0.0;
  final km = m['estimated_diameter']?['kilometers'];
  final dMin = (km?['estimated_diameter_min'] as num?)?.toDouble();
  final dMax = (km?['estimated_diameter_max'] as num?)?.toDouble();
  if (dMin != null && dMax != null) {
    diameterKm = (dMin + dMax) / 2.0;
  }

  // hazard flag
  final pha = (m['is_potentially_hazardous_asteroid'] == true) ? 'Y' : 'N';

  // You can pull more (miss distance, rel velocity) in your card if needed

  return Asteroid(
    id: name,
    name: name,
    fullName: name,
    diameter: diameterKm,
    albedo: 0.0,           // NeoWs doesn't expose albedo directly
    neo: 'Y',
    pha: pha,
    rotationPeriod: 0.0,
    classType: 'NeoWs',
    orbitId: 0,
    moid: 0.0,             // not directly in NeoWs; keep 0 or fill later
    a: 0.0,
    e: 0.0,
  );
}

/// Convenience: map a list of NeoWs items
List<Asteroid> asteroidsFromNeowsList(List<Map<String, dynamic>> items) =>
    items.map(asteroidFromNeowsMap).toList();


/// ---------- MPC (Asterank /api/mpc) -> Asteroid ----------
/// Typical MPC row fields: readable_des, des, H, a, e, i, moid
Asteroid asteroidFromMpcMap(Map<String, dynamic> m) {
  final display = _toString(m['readable_des'],
      fallback: _toString(m['des'], fallback: 'Unknown'));

  final a = (m['a'] as num?)?.toDouble() ?? 0.0;
  final e = (m['e'] as num?)?.toDouble() ?? 0.0;
  final moid = (m['moid'] as num?)?.toDouble() ?? 0.0;
  final H = (m['H'] as num?)?.toDouble();

  // MPC row usually lacks diameter; estimate from H so your UI has a value
  final diameterKm = _estimateDiameterFromH(H);

  return Asteroid(
    id: _toString(m['des'], fallback: display),
    name: display,
    fullName: display,
    diameter: diameterKm,
    albedo: 0.0,
    neo: 'unknown',
    pha: 'unknown',
    rotationPeriod: 0.0,
    classType: 'MPC',
    orbitId: 0,
    moid: moid,
    a: a,
    e: e,
  );
}

/// Convenience: map a list of MPC items (Map form)
List<Asteroid> asteroidsFromMpcList(List<Map<String, dynamic>> items) =>
    items.map(asteroidFromMpcMap).toList();


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
