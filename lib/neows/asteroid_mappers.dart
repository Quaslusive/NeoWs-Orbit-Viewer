import 'package:neows_app/neows/asteroid_model.dart';
import 'package:neows_app/neows/neo_models.dart';

String _s(dynamic v) => v?.toString() ?? '';
String? _sN(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
double? _d(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

Asteroid asteroidFromFeedItem(Map<String, dynamic> m) {
  final id = _sN(m['neo_reference_id']) ?? _sN(m['id']) ?? '';
  final kms = (m['estimated_diameter']?['kilometers'] as Map?) ?? const {};
  final dMin = _d(kms['estimated_diameter_min']);
  final dMax = _d(kms['estimated_diameter_max']);
  final diameterKm = (dMin != null && dMax != null) ? (dMin + dMax) / 2.0 : dMax ?? dMin;

  return Asteroid(
    id: id,
    name: _sN(m['name']),
    designation: id,
    isNeo: true,
    isPha: m['is_potentially_hazardous_asteroid'] as bool?,
    H: _d(m['absolute_magnitude_h']),
    diameterKm: diameterKm,
  );
}

Asteroid asteroidFromBrowseOrLookup(Map<String, dynamic> m) {
  final id = _sN(m['neo_reference_id']) ?? _sN(m['id']) ?? '';
  final kms = (m['estimated_diameter']?['kilometers'] as Map?) ?? const {};
  final dMin = _d(kms['estimated_diameter_min']);
  final dMax = _d(kms['estimated_diameter_max']);
  final diameterKm = (dMin != null && dMax != null) ? (dMin + dMax) / 2.0 : dMax ?? dMin;

  final od = (m['orbital_data'] as Map?) ?? const {};

  return Asteroid(
    id: id,
    name: _sN(m['name']),
    designation: id,
    isNeo: true,
    isPha: m['is_potentially_hazardous_asteroid'] as bool?,
    H: _d(od['absolute_magnitude_h']) ?? _d(m['absolute_magnitude_h']),
    diameterKm: diameterKm,
    spectralClass: (od['orbit_class'] as Map?)?['orbit_class_type']?.toString(),
    orbitId: int.tryParse(_s(od['orbit_id'])),
    moidAu: _d(od['minimum_orbit_intersection']),
    aAu: _d(od['semi_major_axis']),
    e: _d(od['eccentricity']),
    iDeg: _d(od['inclination']),
  );
}

extension AsteroidToLite on Asteroid {
  NeoLite toNeoLite() => NeoLite(
    id: id,
    name: (name?.isNotEmpty ?? false) ? name! : (designation ?? id),
    isHazardous: hazardous,
  );
}

Map<String, dynamic> neoLiteToFeedMap(NeoLite n) => {
  'id': n.id,
  'neo_reference_id': n.id,
  'name': n.name,
  'is_potentially_hazardous_asteroid': n.isHazardous,
};
