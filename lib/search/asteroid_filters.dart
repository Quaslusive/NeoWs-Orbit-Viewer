import 'package:flutter/material.dart';

class DoubleRange { // simple, serializable range
  final double? min;
  final double? max;
  const DoubleRange({this.min, this.max});
  bool get isSet => min != null || max != null;
}

class AsteroidFilters {
  DateTimeRange? window;           // close-approach window
  double? maxMissDistanceKm;       // miss distance (km)
  DoubleRange? relVelKmS;          // relative velocity (km/s)
  DoubleRange? diameterM;          // diameter meters
  DoubleRange? hMag;               // absolute magnitude H
  bool phaOnly;                    // potentially hazardous only
  Set<String> orbitClasses;        // Apollo, Aten, Amor, Atira, etc.
  DoubleRange? e;                  // eccentricity
  DoubleRange? aAu;                // semi-major axis (au)
  DoubleRange? iDeg;               // inclination (deg)
  double? maxMoidAu;               // MOID (au)
  int? maxUncertaintyU;            // 0..9
  int? minArcDays;                 // observation arc min days
  String? targetBody;              // Earth, Mars, Venus, Moon, ...
  String? query;                   // text search

  AsteroidFilters({
    this.window,
    this.maxMissDistanceKm,
    this.relVelKmS,
    this.diameterM,
    this.hMag,
    this.phaOnly = false,
    Set<String>? orbitClasses,
    this.e,
    this.aAu,
    this.iDeg,
    this.maxMoidAu,
    this.maxUncertaintyU,
    this.minArcDays,
    this.targetBody,
    this.query,
  }) : orbitClasses = orbitClasses ?? <String>{};

  AsteroidFilters copyWith({
    DateTimeRange? window,
    double? maxMissDistanceKm,
    DoubleRange? relVelKmS,
    DoubleRange? diameterM,
    DoubleRange? hMag,
    bool? phaOnly,
    Set<String>? orbitClasses,
    DoubleRange? e,
    DoubleRange? aAu,
    DoubleRange? iDeg,
    double? maxMoidAu,
    int? maxUncertaintyU,
    int? minArcDays,
    String? targetBody,
    String? query,
  }) {
    return AsteroidFilters(
      window: window ?? this.window,
      maxMissDistanceKm: maxMissDistanceKm ?? this.maxMissDistanceKm,
      relVelKmS: relVelKmS ?? this.relVelKmS,
      diameterM: diameterM ?? this.diameterM,
      hMag: hMag ?? this.hMag,
      phaOnly: phaOnly ?? this.phaOnly,
      orbitClasses: orbitClasses ?? this.orbitClasses,
      e: e ?? this.e,
      aAu: aAu ?? this.aAu,
      iDeg: iDeg ?? this.iDeg,
      maxMoidAu: maxMoidAu ?? this.maxMoidAu,
      maxUncertaintyU: maxUncertaintyU ?? this.maxUncertaintyU,
      minArcDays: minArcDays ?? this.minArcDays,
      targetBody: targetBody ?? this.targetBody,
      query: query ?? this.query,
    );
  }

  bool get isEmpty =>
      window == null &&
          maxMissDistanceKm == null &&
          (relVelKmS?.isSet != true) &&
          (diameterM?.isSet != true) &&
          (hMag?.isSet != true) &&
          phaOnly == false &&
          orbitClasses.isEmpty &&
          (e?.isSet != true) &&
          (aAu?.isSet != true) &&
          (iDeg?.isSet != true) &&
          maxMoidAu == null &&
          maxUncertaintyU == null &&
          minArcDays == null &&
          targetBody == null &&
          (query == null || query!.isEmpty);
}

// Some sane defaults for sliders
class FilterBounds {
  static const double missKmMax = 20000000.0; // 20M km (~52 LD)
  static const double relVelMax = 50.0;         // km/s
  static const double diamMaxM = 3000.0;        // 3 km
  static const double hMin = 10.0, hMax = 30.0;
  static const double eMax = 1.0;
  static const double aMax = 6.0;               // au
  static const double iMax = 180.0;             // deg
  static const double moidMax = 1.0;            // au
  static const int arcMaxDays = 60000;       // ~164 years
}
