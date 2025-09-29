import 'package:flutter/material.dart';
import 'package:neows_app/service/source_caps.dart'; // add this at the top of the file

class DoubleRange {
  final double? min;
  final double? max;
  const DoubleRange({this.min, this.max});
  bool get isSet => min != null || max != null;

  DoubleRange copyWith({double? min, double? max}) =>
      DoubleRange(min: min ?? this.min, max: max ?? this.max);
}

class AsteroidFilters {
  // Text search
  final String query; // non-nullable; empty means "no query"

  // Time window for approaches / NeoWs feed
  final DateTimeRange? window;

  // Ranges (use consistent units!)
  // Distances: km, MOID: au, Velocity: km/s, Diameter: km
  final DoubleRange? missDistanceKm;
  final DoubleRange? relVelKms;
  final DoubleRange? diameterKm;
  final DoubleRange? hMag;      // absolute magnitude
  final DoubleRange? e;         // eccentricity
  final DoubleRange? aAu;       // semi-major axis in au
  final DoubleRange? iDeg;      // inclination in degrees
  final DoubleRange? moidAu;    // MOID in au

  // Other numeric filters
  final double? maxMoidAu;        // deprecated by moidAu?.max, but kept if you want a simple slider
  final int?    maxUncertaintyU;  // 0..9 (orbit uncertainty)
  final int?    minArcDays;       // observation arc length days
  final int     limit;            // clamp 10–1000

  // Flags/sets
  final bool phaOnly;                 // potentially hazardous only
  final Set<String> orbitClasses;     // e.g., {'Apollo','Aten','Amor','Atira'}
  final String? targetBody;           // e.g., 'Earth','Mars'

  const AsteroidFilters({
    this.query = '',
    this.window,
    this.missDistanceKm,
    this.relVelKms,
    this.diameterKm,
    this.hMag,
    this.e,
    this.aAu,
    this.iDeg,
    this.moidAu,
    this.maxMoidAu,       // if you keep this, it will be applied in addition to moidAu
    this.maxUncertaintyU,
    this.minArcDays,
    this.limit = 50,
    this.phaOnly = false,
    this.orbitClasses = const <String>{},
    this.targetBody,
  });

  bool get isEmpty =>
      (query.isEmpty) &&
          window == null &&
          missDistanceKm?.isSet != true &&
          relVelKms?.isSet != true &&
          diameterKm?.isSet != true &&
          hMag?.isSet != true &&
          e?.isSet != true &&
          aAu?.isSet != true &&
          iDeg?.isSet != true &&
          moidAu?.isSet != true &&
          maxMoidAu == null &&
          maxUncertaintyU == null &&
          minArcDays == null &&
          targetBody == null &&
          phaOnly == false &&
          orbitClasses.isEmpty;

  AsteroidFilters copyWith({
    String? query,
    DateTimeRange? window,
    DoubleRange? missDistanceKm,
    DoubleRange? relVelKms,
    DoubleRange? diameterKm,
    DoubleRange? hMag,
    DoubleRange? e,
    DoubleRange? aAu,
    DoubleRange? iDeg,
    DoubleRange? moidAu,
    double? maxMoidAu,
    int? maxUncertaintyU,
    int? minArcDays,
    int? limit,
    bool? phaOnly,
    Set<String>? orbitClasses,
    String? targetBody,
  }) {
    return AsteroidFilters(
      query: query ?? this.query,
      window: window ?? this.window,
      missDistanceKm: missDistanceKm ?? this.missDistanceKm,
      relVelKms: relVelKms ?? this.relVelKms,
      diameterKm: diameterKm ?? this.diameterKm,
      hMag: hMag ?? this.hMag,
      e: e ?? this.e,
      aAu: aAu ?? this.aAu,
      iDeg: iDeg ?? this.iDeg,
      moidAu: moidAu ?? this.moidAu,
      maxMoidAu: maxMoidAu ?? this.maxMoidAu,
      maxUncertaintyU: maxUncertaintyU ?? this.maxUncertaintyU,
      minArcDays: minArcDays ?? this.minArcDays,
      limit: limit ?? this.limit,
      phaOnly: phaOnly ?? this.phaOnly,
      orbitClasses: orbitClasses ?? this.orbitClasses,
      targetBody: targetBody ?? this.targetBody,
    );
  }

  AsteroidFilters reset() => const AsteroidFilters();
}

// Sane bounds for UI controls (match the units above)
class FilterBounds {
  static const double missKmMax = 20000000.0; // ~52 LD
  static const double relVelMax = 50.0;         // km/s
  static const double diamMaxKm = 3000.0;      // 3,000 km (overkill, but safe upper)
  static const double hMin = 10.0, hMax = 30.0;
  static const double eMax = 1.0;
  static const double aMax = 6.0;               // au
  static const double iMax = 180.0;             // deg
  static const double moidMax = 1.0;            // au
  static const int arcMaxDays = 60000;         // ~164 years
}
// lib/search/asteroid_filters.dart

extension ProjectFilters on AsteroidFilters {
  /// Returns a version of this filter set that only contains fields
  /// supported by the given source. Others are nulled/disabled.
  AsteroidFilters forSource(ApiSource src) {
    final c = src.caps;
    return copyWith(
      window:           c.supportsDateWindow     ? window           : null,
      missDistanceKm:   c.supportsCloseApproach  ? missDistanceKm   : null,
      relVelKms:        c.supportsCloseApproach  ? relVelKms        : null,
      // hazard
      phaOnly:          c.supportsHazardFlag     ? phaOnly          : false,
      // orbit elems + search text are fine for both
      // moidAu/a/e/i kept as-is
    );
  }

  /// Count only fields that survive projection for this source.
  // int activeCountFor(ApiSource src) => forSource(src).activeCount;
}



