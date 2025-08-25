import 'package:flutter/material.dart';
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/widget/orbitDiagram2D.dart';

class AsteroidCard extends StatelessWidget {
  final Asteroid a;
  final VoidCallback onTap;
  final String Function(Asteroid) dangerLevel;
  final bool isLoadingAsterank;

  // NEW (optional): pass cached/enriched orbit values from the list page
  final double? orbitA;
  final double? orbitE;
  final bool isOrbitLoading;

  const AsteroidCard({
    super.key,
    required this.a,
    required this.onTap,
    required this.dangerLevel,
    this.isLoadingAsterank = false,
    this.orbitA,                // NEW
    this.orbitE,                // NEW
    this.isOrbitLoading = false // NEW
  });

  @override
  Widget build(BuildContext context) {
    final danger = dangerLevel(a);
    final dangerColor = danger.contains('Extreme')
        ? Colors.red[300]!
        : danger.contains('Moderate')
        ? Colors.orange[300]!
        : Colors.green[300]!;

    final hasAsterank = _hasAnyAsterank(a);

    // ---- Orbit values preference: explicit props -> model fields ----
    final double? effA = orbitA ?? (a.a > 0 ? a.a : null);
    final double? effE = orbitE ?? (a.e >= 0 && a.e < 1 ? a.e : null);
    final bool hasOrbit = (effA != null && effA > 0) && (effE != null && effE >= 0 && effE < 1);

    return Hero(
      tag: a.id,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Orbit header (now uses effA/effE or shows loading/placeholder) ---
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: hasOrbit
                      ? Container(
                    color: Colors.black12,
                    padding: const EdgeInsets.all(6),
                    child: OrbitDiagram2D(
                      a: effA!,         // AU
                      e: effE!,         // eccentricity
                      stroke: Colors.white,
                      strokeWidth: 2,
                      showPlanets: true,
                    ),
                  )
                      : Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: isOrbitLoading
                        ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Image.asset(
                      'lib/assets/images/orbit_placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // --- Body ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + risk pill
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${a.name ?? 'Asteroid'} (${a.id})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: dangerColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              danger,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Quick facts (use effective orbit if available)
                      Text(
                        'Class: ${a.classType} • Diam: ${a.diameter.toStringAsFixed(2)} km • '
                            'MOID: ${a.moid.toStringAsFixed(4)} au • '
                            'a=${effA?.toStringAsFixed(2) ?? '-'} AU • e=${effE?.toStringAsFixed(2) ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Asterank area
                      if (hasAsterank || isLoadingAsterank) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (hasAsterank)
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (a.asterankPriceUsd != null)
                                      _chip(context, 'Value', _compactUsd(a.asterankPriceUsd!)),
                                    if (a.asterankAlbedo != null)
                                      _chip(context, 'Albedo', a.asterankAlbedo!.toStringAsFixed(2)),
                                    if (a.asterankDiameterKm != null)
                                      _chip(context, 'A.R. Diam', '${a.asterankDiameterKm!.toStringAsFixed(2)} km'),
                                    if (a.asterankSpec != null && a.asterankSpec!.isNotEmpty)
                                      _chip(context, 'Type', a.asterankSpec!),
                                  ],
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                            if (isLoadingAsterank) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _hasAnyAsterank(Asteroid a) =>
      a.asterankPriceUsd != null ||
          a.asterankAlbedo != null ||
          a.asterankDiameterKm != null ||
          (a.asterankSpec?.isNotEmpty == true);

  static Widget _chip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Text('$label: $value', style: Theme.of(context).textTheme.labelSmall),
    );
  }

  static String _compactUsd(double n) {
    if (n >= 1e12) return '\$${(n / 1e12).toStringAsFixed(1)}T';
    if (n >= 1e9)  return '\$${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6)  return '\$${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3)  return '\$${(n / 1e3).toStringAsFixed(1)}K';
    return '\$${n.toStringAsFixed(0)}';
  }
}
