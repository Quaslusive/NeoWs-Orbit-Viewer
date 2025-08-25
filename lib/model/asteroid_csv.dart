
class Asteroid {
  final String id;
  final String name;
  final String fullName;
  final double diameter;
  final double albedo;
  final String neo;
  final String pha;
  final double rotationPeriod;
  final String classType;
  final int orbitId;
  final double moid;
// test chart
  final double a;
  final double e;

  // Asterank-enriched fields (all optional)
  double? asterankPriceUsd;
  double? asterankAlbedo;
  double? asterankDiameterKm;
  double? asterankDensity;
  String? asterankSpec;
  String? asterankFullName;

/*
  void applyAsterank(AsterankInfo info) {
    asterankPriceUsd   = info.price ?? asterankPriceUsd;
    asterankAlbedo     = info.pv ?? asterankAlbedo;
    asterankDiameterKm = info.diameter ?? asterankDiameterKm;
    asterankDensity    = info.density ?? asterankDensity;
    asterankSpec       = info.spec ?? asterankSpec;
    asterankFullName   = info.fullName ?? asterankFullName;
  }

  Asteroid asteroidFromAsterankInfo(AsterankInfo i) {
    return Asteroid(
      id: i.name ?? i.fullName ?? 'NA',
      name: i.name ?? i.fullName ?? 'Unknown',
      fullName: i.fullName ?? i.name ?? 'Unknown',
      diameter: i.diameter ?? 0.0,
      albedo: i.pv ?? 0.0,
      neo: 'unknown',
      pha: 'unknown',
      rotationPeriod: 0.0,
      classType: i.spec ?? 'N/A',
      orbitId: 0,
      moid: i.moid ?? 0.0,
      a: i.a ?? 0.0,
      e: i.e ?? 0.0,
    )
      ..applyAsterank(i);
  }
*/


  Asteroid({
    required this.id,
    required this.name,
    required this.fullName,
    required this.diameter,
    required this.albedo,
    required this.neo,
    required this.pha,
    required this.rotationPeriod,
    required this.classType,
    required this.orbitId,
    required this.moid,
    //test chart
    required this.a,
    required this.e,
  });

}
