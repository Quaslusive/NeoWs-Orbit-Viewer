import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:neows_app/model/asteroid_csv.dart';

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
    final rawData = await rootBundle.loadString('lib/assets/latest_fulldb.csv');
//    final rawData = await rootBundle.loadString('lib/assets/astroidReadTest.csv');
    final csvData = const CsvToListConverter(eol: '\n').convert(rawData);

    List<Asteroid> asteroids = [];

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      asteroids.add(
          Asteroid(
            id: row[0].toString(),               // id
            name: row[4].toString(),             // name
            fullName: row[2].toString(),         // full_name
            diameter: double.tryParse(row[15].toString()) ?? 0.0,
            albedo: double.tryParse(row[17].toString()) ?? 0.0,
            neo: row[6].toString(),              // neo
            pha: row[7].toString(),              // pha
            rotationPeriod: double.tryParse(row[18].toString()) ?? 0.0,
            classType: row[60].toString(),       // class
            orbitId: int.tryParse(row[27].toString()) ?? 0,
            moid: double.tryParse(row[45].toString()) ?? 0.0,
            a: double.tryParse(row[33].toString()) ?? 0.0,
            e: double.tryParse(row[32].toString()) ?? 0.0
          )

      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sök efter Asteroids")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration:
                  const InputDecoration(labelText: 'Sök asteroid namn'),
              onChanged: _filterAsteroids,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final asteroid = _filtered[index];
                return ListTile(
                  title: Text('${asteroid.name} (${asteroid.id})'),
                  subtitle: Text(
                    'Fullname: ${asteroid.fullName}\n'
                        'Class: ${asteroid.classType}\n'
                        'Diameter: ${asteroid.diameter.toStringAsFixed(2)} km\n'
                        'Albedo: ${asteroid.albedo.toStringAsFixed(2)}\n'
                        'Rotation Period: ${asteroid.rotationPeriod.toStringAsFixed(2)} h\n'
                        'NEO: ${asteroid.neo} | PHA: ${asteroid.pha}\n'
                        'MOID: ${asteroid.moid.toStringAsFixed(4)} AU\n'
                        'Orbit ID: ${asteroid.orbitId}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
