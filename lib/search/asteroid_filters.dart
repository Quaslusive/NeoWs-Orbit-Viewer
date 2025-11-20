/*
import 'package:flutter/material.dart';
import 'package:neows_app/service/source_caps.dart';

class DoubleRange {
  final double? min;
  final double? max;
  const DoubleRange({this.min, this.max});
  bool get isSet => min != null || max != null;

  DoubleRange copyWith({double? min, double? max}) =>
      DoubleRange(min: min ?? this.min, max: max ?? this.max);
}

class AsteroidFilters {
  final String query; // non-nullable; empty means "no query"

  final DateTimeRange? window;

  // Ranges
  final DoubleRange? missDistanceKm;
  final DoubleRange? relVelKms;
  final DoubleRange? diameterKm;
  final DoubleRange? hMag;
  final DoubleRange? e;
  final DoubleRange? aAu;
  final DoubleRange? iDeg;
  final DoubleRange? moidAu;

  // Other numeric filters
  final double? maxMoidAu;
  final int?    maxUncertaintyU;
  final int?    minArcDays;
  final int     limit;

  // Flags/sets
  final bool phaOnly;
  final Set<String> orbitClasses;
  final String? targetBody;

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
    this.maxMoidAu,
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


class FilterBounds {
  static const double missKmMax = 20000000.0; // ~52 LD
  static const double relVelMax = 50.0;         // km/s
  static const double diamMaxKm = 3000.0;      // 3,000 km
  static const double hMin = 10.0, hMax = 30.0;
  static const double eMax = 1.0;
  static const double aMax = 6.0;               // au
  static const double iMax = 180.0;             // deg
  static const double moidMax = 1.0;            // au
  static const int arcMaxDays = 60000;         // ~164 years
}

extension ProjectFilters on AsteroidFilters {

  AsteroidFilters forSource(ApiSource src) {
    final c = src.caps;
    return copyWith(
      window:           c.supportsDateWindow     ? window           : null,
      missDistanceKm:   c.supportsCloseApproach  ? missDistanceKm   : null,
      relVelKms:        c.supportsCloseApproach  ? relVelKms        : null,
      // hazard
      phaOnly:          c.supportsHazardFlag     ? phaOnly          : false,

    );
  }

  // int activeCountFor(ApiSource src) => forSource(src).activeCount;
}



*/
