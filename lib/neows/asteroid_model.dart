import 'dart:math' as math;
import 'package:flutter/foundation.dart';

@immutable
class Asteroid with DiagnosticableTreeMixin {
  final String id;               // Use neo_reference_id (string)
  final String? name;            // e.g. "(99942) Apophis"
  final String? designation;     // Same as id or parsed numeric part

  final double? H;               // absolute magnitude H
  final double? diameterKm;      // from estimated_diameter.kilometers
  final double? albedo;          // not provided by NeoWs (keep null)

  final bool isNeo;              // always true for NeoWs
  final bool? isPha;             // is_potentially_hazardous_asteroid
  final String? spectralClass;   // orbit_class_type (browse/lookup only)

  final int? orbitId;
  final double? moidAu;
  final double? aAu;
  final double? e;
  final double? iDeg;

  const Asteroid({
    required this.id,
    required this.name,
    required this.designation,
    required this.isNeo,
    this.H,
    this.diameterKm,
    this.albedo,
    this.isPha,
    this.spectralClass,
    this.orbitId,
    this.moidAu,
    this.aAu,
    this.e,
    this.iDeg,
  });

  /// Estimated diameter from H if missing.
  /// D(km) = 1329 / sqrt(p) * 10^(-H/5), assume p = 0.14
  double? get estimatedDiameterKmFromH {
    if (diameterKm != null) return diameterKm;
    if (H == null) return null;
    const p = 0.14;
    return 1329.0 / math.sqrt(p) * math.pow(10.0, -(H!) / 5.0).toDouble();
  }

  /// Extra convenience: treat as hazardous if flagged by NeoWs
  /// OR meets the usual MOID/size heuristic (~140m).
  bool get hazardous =>
      (isPha ?? false) ||
          ((moidAu ?? 99) < 0.05 &&
              ((diameterKm ?? estimatedDiameterKmFromH ?? 0) >= 0.14));

  Asteroid copyWith({
    String? id,
    String? name,
    String? designation,
    double? H,
    double? diameterKm,
    double? albedo,
    bool? isNeo,
    bool? isPha,
    String? spectralClass,
    int? orbitId,
    double? moidAu,
    double? aAu,
    double? e,
    double? iDeg,
  }) {
    return Asteroid(
      id: id ?? this.id,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      isNeo: isNeo ?? this.isNeo,
      H: H ?? this.H,
      diameterKm: diameterKm ?? this.diameterKm,
      albedo: albedo ?? this.albedo,
      isPha: isPha ?? this.isPha,
      spectralClass: spectralClass ?? this.spectralClass,
      orbitId: orbitId ?? this.orbitId,
      moidAu: moidAu ?? this.moidAu,
      aAu: aAu ?? this.aAu,
      e: e ?? this.e,
      iDeg: iDeg ?? this.iDeg,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'designation': designation,
    'H': H,
    'diameterKm': diameterKm,
    'albedo': albedo,
    'isNeo': isNeo,
    'isPha': isPha,
    'spectralClass': spectralClass,
    'orbitId': orbitId,
    'moidAu': moidAu,
    'aAu': aAu,
    'e': e,
    'iDeg': iDeg,
  };

  factory Asteroid.fromJson(Map<String, dynamic> m) => Asteroid(
    id: m['id'] as String,
    name: m['name'] as String?,
    designation: m['designation'] as String?,
    isNeo: m['isNeo'] as bool? ?? true,
    H: (m['H'] as num?)?.toDouble(),
    diameterKm: (m['diameterKm'] as num?)?.toDouble(),
    albedo: (m['albedo'] as num?)?.toDouble(),
    isPha: m['isPha'] as bool?,
    spectralClass: m['spectralClass'] as String?,
    orbitId: m['orbitId'] as int?,
    moidAu: (m['moidAu'] as num?)?.toDouble(),
    aAu: (m['aAu'] as num?)?.toDouble(),
    e: (m['e'] as num?)?.toDouble(),
    iDeg: (m['iDeg'] as num?)?.toDouble(),
  );
}
