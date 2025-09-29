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

Asteroid _asteroidFromAsterank(AsterankObject o) {
  final display = o.title.isNotEmpty ? o.title : o.id;
  return Asteroid(
    id: o.id,
    name: display,
    fullName: display,
    diameter: o.diameter ?? 0.0,
    albedo: o.albedo ?? 0.0,
    neo: (o.neo == true) ? 'Y' : 'N',
    pha: 'unknown',   // not supplied by Asterank objects
    rotationPeriod: 0.0,
    classType: 'Asterank',
    orbitId: 0,
    moid: 0.0,        // not supplied
    a: o.a ?? 0.0,
    e: o.e ?? 0.0,
    i: o.i ?? 0.0,
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
