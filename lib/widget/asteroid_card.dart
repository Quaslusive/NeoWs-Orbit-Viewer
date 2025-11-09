import 'package:flutter/material.dart';
import 'package:neows_app/model/asteroid_model.dart';
import 'package:neows_app/widget/orbitDiagram2D.dart';

class AsteroidCard extends StatelessWidget {
  final Asteroid a;
  final VoidCallback onTap;


  final double? orbitA; // semi-major axis (AU)
  final double? orbitE; // eccentricity
  final bool isOrbitLoading;
  final bool debugOrbitValues;

  const AsteroidCard({
    super.key,
    required this.a,
    required this.onTap,
    this.orbitA,
    this.orbitE,
    this.isOrbitLoading = false,
    this.debugOrbitValues = false,
  });

  @override
  Widget build(BuildContext context) {
    final double? rawA = orbitA ?? a.aAu;
    final double? rawE = orbitE ?? a.e;

    final double? effE = _eccOrNull(rawE);                 // must be 0<=e<1
    final double? effA = _positiveOrNull(rawA);            // >0 if present
    final bool canDraw = _canDrawOrbit(effA, effE);        // OK with e only

    // Hazard flag (mapper sets isPha)
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Container(
                    color: Colors.grey,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(6),
                    child: canDraw
                        ? OrbitDiagram2D(
                      a: effA ?? 1.0,
                      e: effE!,
                      size: 96,
                      stroke: Colors.white,
                      strokeWidth: 2,
                      showPlanets: true,
                      backgroundColor: Colors.grey,
                      placeholderAsset: 'lib/assets/images/PNG_orbit_placeholder.png',
                    )
                        : (isOrbitLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Image.asset(
                      'lib/assets/images/PNG_orbit_placeholder.png',
                      fit: BoxFit.cover,
                    )),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

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
                              color: hazardous ? Colors.red[300] : Colors.green[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                       /*     child: Text(
                              hazardous ? 'Hazardous' : 'Not hazardous',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),*/
                          ),
                        ],
                      ),

                      if (debugOrbitValues) ...[
                        const SizedBox(height: 4),
                        Text(
                          'orbit: a=${_fmt(effA)} e=${_fmt(effE)}  (raw a=${_fmt(rawA)} e=${_fmt(rawE)})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                      ],

                      const SizedBox(height: 6),

                      // Quick facts
            /*          Builder(
                        builder: (_) {
                          final parts = <String>[];
                          if (_isFinite(a.H)) parts.add('H: ${a.H!.toStringAsFixed(1)}');
                          if (_isFinite(a.diameterKm)) {
                            parts.add('Diameter: ${a.diameterKm!.toStringAsFixed(2)} km');
                          }
                          if (_isFinite(a.moidAu)) {
                            parts.add('MOID: ${a.moidAu!.toStringAsFixed(4)} au');
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
                            parts.join(' • '),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),*/
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
