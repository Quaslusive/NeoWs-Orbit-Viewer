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
  final double a;
  final double e;
  final double i;

  // Asterank-enriched fields (all optional)
  double? asterankPriceUsd;
  double? asterankAlbedo;
  double? asterankDiameterKm;
  double? asterankDensity;
  String? asterankSpec;
  String? asterankFullName;


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
    required this.a,
    required this.e,
    required this.i,
  });

}
