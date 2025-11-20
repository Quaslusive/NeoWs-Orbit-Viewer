import 'package:flutter/material.dart';
import 'package:neows_app/neows/asteroid_model.dart';
import 'package:neows_app/widget/orbit_diagram2d.dart';

class AsteroidCard extends StatelessWidget {
  final Asteroid a;
  final VoidCallback onTap;
  final double? orbitA; // semi-major axis (AU)
  final double? orbitE; // eccentricity
  final bool isOrbitLoading;

  const AsteroidCard({
    super.key,
    required this.a,
    required this.onTap,
    this.orbitA,
    this.orbitE,
    this.isOrbitLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final double? rawA = orbitA ?? a.aAu;
    final double? rawE = orbitE ?? a.e;

    final double? effE = _eccOrNull(rawE);                 // must be 0<=e<1
    final double? effA = _positiveOrNull(rawA);            // >0 if present
    final bool canDraw = _canDrawOrbit(effA, effE);        // OK with e only

    final bool hazardous = a.isPha == true;

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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Container(
                    color: Colors.black87,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(6),
                    child: canDraw
                        ? OrbitDiagram2D(
                      a: effA!,
                      e: effE!,
                      size: 80,
                      strokeWidth: 2,
                      showPlanets: true,
                      backgroundColor: Colors.black87,
                    )
                        : (isOrbitLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Image.asset(
                      'lib/assets/images/PNG_orbit_placeholder_Black.png',
                      fit: BoxFit.cover,
                    )),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.name ?? 'Asteroid',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                       //   const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                            decoration: BoxDecoration(
                              color: hazardous ? Colors.red[300] : Colors.green[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              hazardous ? '⚠️' : '✅',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Quick facts
                     Builder(
                        builder: (_) {
                          final parts = <String>[];
                          if (_isFinite(a.H)) parts.add('H: ${a.H!.toStringAsFixed(1)}');
                          if (_isFinite(a.diameterKm)) {
                            parts.add('Diameter: ${a.diameterKm!.toStringAsFixed(2)} km');
                          }
                          if (_isFinite(effA)) parts.add('a=${effA!.toStringAsFixed(2)} au');
                          if (_isFinite(effE)) parts.add('e=${effE!.toStringAsFixed(2)}');

                          if (parts.isEmpty) {
                            return Text(
                              'No additional data from NeoWs.',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return Text(
                            parts.join('\n'),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
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

  static bool _isFinite(num? v) => v != null && v.isFinite;
  static String _fmt(num? v) => v == null ? 'null' : (v.isFinite ? v.toStringAsFixed(3) : 'NaN');

  static double? _positiveOrNull(num? v) {
    if (v == null || !v.isFinite) return null;
    final d = v.toDouble();
    return d > 0 ? d : null;
  }

  static double? _eccOrNull(num? v) {
    if (v == null || !v.isFinite) return null;
    final d = v.toDouble();
    return (d >= 0.0 && d < 1.0) ? d : null;
  }

  static bool _canDrawOrbit(double? a, double? e) {
    // valid if we have a valid e; a may be null (fallback 1 AU)
    final eOk = e != null && e.isFinite && e >= 0.0 && e < 1.0;
    final aOk = (a == null) || (a.isFinite && a > 0.0);
    return eOk && aOk;
  }
}
