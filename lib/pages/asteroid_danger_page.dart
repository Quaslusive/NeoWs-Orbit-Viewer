
import 'package:flutter/material.dart';
import '../model/asteroid_csv.dart';

class AsteroidDangerPage extends StatelessWidget {
  final List<Asteroid> asteroids;

  const AsteroidDangerPage({super.key, required this.asteroids});

  String getDangerLevel(Asteroid a) {
    if (a.pha == 'Y' && a.moid < 0.05 && a.diameter > 140) {
      return 'Extreme Danger 🔥🔥🔥';
    } else if (a.pha == 'Y' || a.moid < 0.1) {
      return 'Moderate Risk ⚠️';
    } else {
      return 'Safe ✅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NEO Danger Meter")),
      body: ListView.builder(
        itemCount: asteroids.length,
        itemBuilder: (context, index) {
          final a = asteroids[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(a.name),
              subtitle: Text(
                'Fullname: ${a.fullName}'
                'Diameter: ${a.diameter.toStringAsFixed(2)} km'
                'PHA: ${a.pha} | MOID: ${a.moid.toStringAsFixed(4)} AU'
                'Danger Level: ${getDangerLevel(a)}',
              ),
            ),
          );
        },
      ),
    );
  }
}
