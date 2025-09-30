import 'dart:math' as math;
import 'package:neows_app/search/asteroid_filters.dart';
import 'package:neows_app/model/asteroid_csv.dart';

enum SortKey { size, moid, name, e, a, i }

extension AsteroidFiltering on List<Asteroid> {
  List<Asteroid> applyFilters(
      AsteroidFilters f, {
        SortKey sortKey = SortKey.size,
        bool descending = true,
      }) {
    final out = <Asteroid>[];
    for (final a in this) {
      if (!_matchesAsteroid(a, f)) continue;
      out.add(a);
    }

    int cmp<T extends Comparable>(T a, T b) => a.compareTo(b);

    out.sort((a, b) {
      int r;
      switch (sortKey) {
        case SortKey.moid: r = cmp(_safeMoidAu(a), _safeMoidAu(b)); break;
        case SortKey.name: r = cmp(toStr(a.name), toStr(b.name)); break;
        case SortKey.e:    r = cmp(_safeE(a), _safeE(b)); break;
        case SortKey.a:    r = cmp(_safeAAu(a), _safeAAu(b)); break;
        case SortKey.i:    r = cmp(_safeIDeg(a), _safeIDeg(b)); break;
        case SortKey.size:
        default:           r = cmp(_safeDiameterKm(a), _safeDiameterKm(b));
      }
      return descending ? -r : r;
    });

    if (f.limit > 0 && out.length > f.limit) {
      return out.sublist(0, f.limit);
    }
    return out;
  }
}

// ---- Single source of truth: the predicate ----

bool _matchesAsteroid(Asteroid a, AsteroidFilters f) {
  // 1) Text query: id/name/fullName
  if (f.query.isNotEmpty) {
    final hay = '${toStr(a.id)} ${toStr(a.name)} ${toStr(a.fullName)}'
        .toLowerCase();
    if (!hay.contains(f.query.toLowerCase())) return false;
  }

  // Normalize all values once
  final dKm   = _safeDiameterKm(a);
  final moid  = _safeMoidAu(a);
  final ecc   = _safeE(a);
  final aAu   = _safeAAu(a);
  final iDeg  = _safeIDeg(a);
  final pha   = _isHazardous(a);
  final cls   = toStr(a.classType); // e.g., Apollo/Aten/Amor…

  // 2) Range helpers
  bool inRange(DoubleRange? r, double v) =>
      r == null || !r.isSet ||
          ((r.min == null || v >= r.min!) && (r.max == null || v <= r.max!));

  // 3) Apply filters that your model supports
  if (!inRange(f.diameterKm, dKm)) return false;
  if (!inRange(f.moidAu, moid)) return false;
  if (!inRange(f.e, ecc)) return false;
  if (!inRange(f.aAu, aAu)) return false;
  if (!inRange(f.iDeg, iDeg)) return false;

  // 4) phaOnly
  if (f.phaOnly && !pha) return false;

  // 5) Orbit classes (if user selected any, require membership)
  if (f.orbitClasses.isNotEmpty) {
    if (cls.isEmpty || !f.orbitClasses.contains(cls)) return false;
  }

  // 6) Ignore unsupported filters gracefully:
  // - f.hMag, f.relVelKms, f.missDistanceKm, f.window, f.targetBody, etc.
  // You can log or surface a subtle UI hint if these are set.

  return true;
}

// ---- Safe accessors (single place for unit/format quirks) ----

double _safeDiameterKm(Asteroid a) {
  // prefer asterankDiameterKm if populated; otherwise use base `diameter`
  final d = toDouble(a.asterankDiameterKm);
  if (d > 0) return d;
  return toDouble(a.diameter); // assuming already in km
}

double _safeMoidAu(Asteroid a) => toDouble(a.moid, fallback: double.maxFinite);
double _safeE(Asteroid a)      => toDouble(a.e);
double _safeAAu(Asteroid a)    => toDouble(a.a);
double _safeIDeg(Asteroid a)   => toDouble(a.i);

bool _isHazardous(Asteroid a) {
  final s = toStr(a.pha).toLowerCase();
  if (s == 'y' || s == 'yes' || s == 'true' || s == '1') return true;
  return false;
}


double toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  final p = double.tryParse(v.toString().trim());
  return p ?? fallback;
}

String toStr(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

/// Estimate diameter in km from H magnitude.
/// Default geometric albedo p = 0.14
double estimateDiameterFromH(double? H, {double p = 0.14}) {
  if (H == null) return 0.0;
  if (p <= 0) p = 0.14;
  return 1329.0 / math.sqrt(p) * math.pow(10.0, -H / 5.0);
}

