import 'package:flutter/material.dart';
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/widget/orbitDiagram2D.dart';

class AsteroidDetailsPage extends StatelessWidget {
  final Asteroid asteroid;

  const AsteroidDetailsPage({super.key, required this.asteroid});

  @override
  Widget build(BuildContext context) {
    String dangerLevel() {
      if (asteroid.pha == 'Y' && asteroid.moid < 0.05 &&
          asteroid.diameter > 140) {
        return 'Extreme Danger 🔥';
      } else if (asteroid.pha == 'Y' || asteroid.moid < 0.1) {
        return 'Moderate Risk ⚠️';
      } else {
        return 'Safe ✅';
      }
    }

    Color dangerColor() {
      final d = dangerLevel();
      if (d.contains('Extreme')) return Colors.red[300]!;
      if (d.contains('Moderate')) return Colors.orange[300]!;
      return Colors.green[300]!;
    }

    return Scaffold(
      appBar: AppBar(title: Text(asteroid.name)),
      body: Center(
        child: Hero(
          tag: asteroid.id, // must match the grid card
          child: Material( // <— smooth Hero transitions
            color: Colors.transparent,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              elevation: 6,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (asteroid.a > 0 && asteroid.e >= 0)
                            ? SizedBox(
                          width: double.infinity,
                          height: 180,
                          child: OrbitDiagram2D(
                              a: asteroid.a, e: asteroid.e),
                        )
                            : Image.asset(
                          'lib/assets/images/orbit_placeholder.png',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title + ID row
                      Text(
                        asteroid.fullName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: dangerColor(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dangerLevel(),
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('ID: ${asteroid.id}',
                              style: const TextStyle(color: Colors.black54)),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Copy ID',
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Asteroid ID copied')),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Share',
                            icon: const Icon(Icons.face),
                            onPressed: () {
                              // Hook up share_plus later if you like
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Share coming soon')),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Details
                      _kv('Class', asteroid.classType),
                      _kv('Diameter',
                          '${asteroid.diameter.toStringAsFixed(2)} km'),
                      _kv('Albedo', asteroid.albedo.toStringAsFixed(2)),
                      _kv('Rotation Period',
                          '${asteroid.rotationPeriod.toStringAsFixed(2)} h'),
                      _kv('MOID', '${asteroid.moid.toStringAsFixed(4)} AU'),
                      _kv('PHA', asteroid.pha),
                      _kv('Orbit ID', '${asteroid.orbitId}'),
                      _kv('a (semi-major axis)', asteroid.a.toStringAsFixed(4)),
                      _kv('e (eccentricity)', asteroid.e.toStringAsFixed(4)),

                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// Small helper for clean rows
  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150,
              child: Text(k, style: const TextStyle(color: Colors.black54))),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

