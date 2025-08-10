import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/asteroid_details_page.dart';
import 'package:neows_app/widget/orbitDiagram2D.dart';

//TODO Fix layout
class AsteroidSearchPage extends StatefulWidget {
  const AsteroidSearchPage({super.key});

  @override
  State<AsteroidSearchPage> createState() => _AsteroidSearchPageState();
}

class _AsteroidSearchPageState extends State<AsteroidSearchPage> {
  List<Asteroid> _asteroids = [];
  List<Asteroid> _filtered = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    loadAsteroidData().then((data) {
      setState(() {
        _asteroids = data;
        _filtered = data;
      });
    });
  }

  Future<List<Asteroid>> loadAsteroidData() async {
//    final rawData = await rootBundle.loadString('lib/assets/latest_fulldb.csv');
    final rawData =
        await rootBundle.loadString('lib/assets/astroidReadTest.csv');
    final csvData = const CsvToListConverter(eol: '\n').convert(rawData);

    List<Asteroid> asteroids = [];

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      asteroids.add(Asteroid(
          id: row[0].toString(),
          // id
          name: row[4].toString(),
          // name
          fullName: row[2].toString(),
          // full_name
          diameter: double.tryParse(row[15].toString()) ?? 0.0,
          albedo: double.tryParse(row[17].toString()) ?? 0.0,
          neo: row[6].toString(),
          // neo
          pha: row[7].toString(),
          // pha
          rotationPeriod: double.tryParse(row[18].toString()) ?? 0.0,
          classType: row[60].toString(),
          // class
          orbitId: int.tryParse(row[27].toString()) ?? 0,
          moid: double.tryParse(row[45].toString()) ?? 0.0,
          a: double.tryParse(row[33].toString()) ?? 0.0,
          e: double.tryParse(row[32].toString()) ?? 0.0));
    }

    return asteroids;
  }

  void _filterAsteroids(String query) {
    setState(() {
      _search = query;
      _filtered = _asteroids
          .where((a) =>
              a.name.toLowerCase().contains(query.toLowerCase()) ||
              a.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final aspectRatio = isSmallScreen ? 0.8 : 0.9;

    return Scaffold(
      appBar: AppBar(title: const Text("Sök efter Asteroids")),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(labelText: 'Sök asteroid namn'),
            onChanged: _filterAsteroids,
          ),
        ),
        Expanded(
          child: GridView.builder(
            itemCount: _filtered.length,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: aspectRatio,
              // childAspectRatio: 0.7
              // childAspectRatio: 3 / 2,
            ),
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final asteroid = _filtered[index];
              final danger = getDangerLevel(asteroid);

              Color cardColor;
              if (danger.contains('Extreme')) {
                cardColor = Colors.red[200]!;
              } else if (danger.contains('Moderate')) {
                cardColor = Colors.orange[200]!;
              } else {
                cardColor = Colors.grey[100]!;
              }

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 350),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 250),
                      pageBuilder: (_, animation, secondaryAnimation) =>
                          AsteroidDetailsPage(asteroid: asteroid),
                      transitionsBuilder: (_, animation, __, child) {
                        final curved = CurvedAnimation(
                            parent: animation, curve: Curves.easeOutCubic);
                        return FadeTransition(
                          opacity: curved,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.98, end: 1.0)
                                .animate(curved),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
                child: Hero(
                  tag: asteroid.id, // <-- must match in AsteroidDetailsPage
                  transitionOnUserGestures: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Card(
                      color: cardColor,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header image area
                            ClipRRect(
                              // TODO Ta reda på varför detta visar elepisk (ögon form)
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 100,
                                // tweak to taste (works with your childAspectRatio)
                                width: double.infinity,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Placeholder base
                                    if (!(asteroid.a > 0 &&
                                        asteroid.e >= 0 &&
                                        asteroid.e < 1))
                                      Image.asset(
                                        'lib/assets/images/orbit_placeholder.png',
                                        fit: BoxFit.cover,
                                      ),
                                    // Orbit overlay (only if valid)
                                    if (asteroid.a > 0 &&
                                        asteroid.e >= 0 &&
                                        asteroid.e < 1)
                                      Container(
                                        color: Colors.black12,
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: OrbitDiagram2D(
                                            a: asteroid.a,
                                            e: asteroid.e,
                                            stroke: Colors.white,
                                            // <- fixed color
                                            strokeWidth: 2,
                                            showPlanets: true,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
// TODO detta gör att orbit lines visar cirkuler,
                            /*            ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: OrbitThumb(
                              a: asteroid.a,
                              e: asteroid.e,
                              size: 100,                          // match your layout
                              backgroundColor: Colors.black,      // circular backdrop behind lines
                              stroke: Colors.white,               // fixed orbit color
                              strokeWidth: 2,
                              showPlanets: true,
                              placeholderAsset: 'lib/assets/images/orbit_placeholder.png',
                            ),
                          ),
*/

                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  danger.contains('Extreme')
                                      ? Icons.warning_amber_rounded
                                      : danger.contains('Moderate')
                                          ? Icons.report_problem
                                          : Icons.check_circle,
                                  color: danger.contains('Extreme')
                                      ? Colors.red
                                      : danger.contains('Moderate')
                                          ? Colors.orange
                                          : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${asteroid.name} (${asteroid.id})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Class: ${asteroid.classType}'),
                            Text(
                                'Diameter: ${asteroid.diameter.toStringAsFixed(2)} km'),
                            Text(
                                'PHA: ${asteroid.pha} | MOID: ${asteroid.moid.toStringAsFixed(4)}'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: danger.contains('Extreme')
                                    ? Colors.red[300]
                                    : danger.contains('Moderate')
                                        ? Colors.orange[300]
                                        : Colors.green[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                danger,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
