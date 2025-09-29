enum ApiSource { neows, asterank }

class SourceCaps {
  final bool supportsDateWindow;     // server-side date range
  final bool supportsCloseApproach;  // miss distance, relVel
  final bool supportsHazardFlag;     // PHA flag
  final bool supportsOrbitElems;     // a, e, i, moid
  final bool supportsSearchText;     // id/name search
  const SourceCaps({
    this.supportsDateWindow = false,
    this.supportsCloseApproach = false,
    this.supportsHazardFlag = false,
    this.supportsOrbitElems = true,
    this.supportsSearchText = true,
  });
}

extension ApiSourceX on ApiSource {
  String get label => switch (this) {
    ApiSource.neows    => 'NASA NeoWs',
    ApiSource.asterank => 'Asterank',
  };

  SourceCaps get caps => switch (this) {
    ApiSource.neows => const SourceCaps(
      supportsDateWindow: true,
      supportsCloseApproach: true,
      supportsHazardFlag: true,
      supportsOrbitElems: true,
      supportsSearchText: true,
    ),
    ApiSource.asterank => const SourceCaps(
      supportsDateWindow: false,
      supportsCloseApproach: false,
      supportsHazardFlag: false,
      supportsOrbitElems: true,
      supportsSearchText: true,
    ),
  };
}
