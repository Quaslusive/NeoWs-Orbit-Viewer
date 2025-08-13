import 'package:neows_app/service/asterank_api_service.dart';

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

  void applyAsterank(AsterankInfo info) {
    asterankPriceUsd   = info.price ?? asterankPriceUsd;
    asterankAlbedo     = info.pv ?? asterankAlbedo;
    asterankDiameterKm = info.diameter ?? asterankDiameterKm;
    asterankDensity    = info.density ?? asterankDensity;
    asterankSpec       = info.spec ?? asterankSpec;
    asterankFullName   = info.fullName ?? asterankFullName;
  }

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
