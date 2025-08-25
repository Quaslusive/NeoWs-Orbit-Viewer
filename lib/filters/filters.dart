// NeoWs: mostly date-driven; optional extra client-side filters
import 'package:flutter/material.dart';

class NeoWsFilters {
  DateTimeRange? dateRange;        // max 7 days recommended
  bool? hazardousOnly;             // is_potentially_hazardous_asteroid
  double? minDiameterKm, maxDiameterKm;
  double? maxMissDistanceKm;       // client-side filter
  String? orbitingBody;            // e.g. "Earth"
}

// MPC (Asterank MPC endpoint / regex + element ranges)
class MpcFilters {
  String? term;                    // regex on designation
  double? minA, maxA;              // AU
  double? minE, maxE;
  double? minI, maxI;              // deg
  double? minH, maxH;              // mag
  double? minMoid, maxMoid;        // AU
}

// Offline (MPCORB): same as MPC – we filter locally
typedef OfflineFilters = MpcFilters;
