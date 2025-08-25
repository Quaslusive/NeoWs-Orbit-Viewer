/*
// lib/service/asterank_mpc_mapper.dart
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/service/asterank_api_service.dart';

Asteroid asteroidFromMpc(MpcRow r) {
  final display = r.readableDes ?? r.des ?? 'Unknown';
  return Asteroid(
    id: r.des ?? display,
    name: display,
    fullName: display,
    diameter: 0.0,          // MPC row won’t have diameter; keep 0 or estimate from H if you add that logic
    albedo: 0.0,            // not provided by MPC
    neo: 'unknown',
    pha: 'unknown',
    rotationPeriod: 0.0,    // not in MPC endpoint
    classType: 'MPC',
    orbitId: 0,
    moid: r.moid ?? 0.0,
    a: r.a ?? 0.0,
    e: r.e ?? 0.0,
  );
}
*/
