
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class Asteroid {
  final String id;
  final String name;
  final String fullName;
  final double diameter;
  final String pha;
  final double moid;
  final double a;
  final double e;

  Asteroid({
    required this.id,
    required this.name,
    required this.fullName,
    required this.diameter,
    required this.pha,
    required this.moid,
    required this.a,
    required this.e,
  });

  String dangerLevel() {
    if (pha == 'Y' && moid < 0.05 && diameter > 140) {
      return 'Extreme Danger 🔥🔥🔥';
    } else if (pha == 'Y' || moid < 0.1) {
      return 'Moderate Risk ⚠️';
    } else {
      return 'Safe ✅';
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Asteroid> _asteroids = [];

  @override
  void initState() {
    super.initState();
    loadAsteroidData().then((data) {
      setState(() {
        _asteroids = data;
      });
    });
  }

  Future<List<Asteroid>> loadAsteroidData() async {
    final rawData = await rootBundle.loadString('assets/astroidReadTest.csv');
    final csvData = const CsvToListConverter(eol: '\n').convert(rawData);
    final rows = csvData.sublist(1); // Skip header

    List<Asteroid> asteroids = [];

    for (var row in rows) {
      try {
        asteroids.add(Asteroid(
          id: row[0].toString(),
          name: row[4].toString(),
          fullName: row[2].toString(),
          diameter: double.tryParse(row[15].toString()) ?? 0.0,
          pha: row[7].toString(),
          moid: double.tryParse(row[45].toString()) ?? 0.0,
          a: double.tryParse(row[33].toString()) ?? 0.0,
          e: double.tryParse(row[32].toString()) ?? 0.0,
        ));
      } catch (_) {}
    }

    return asteroids;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NEO Danger Meter & Orbit Plot")),
      body: _asteroids.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: buildDangerList(_asteroids)),
                const Divider(),
                SizedBox(height: 300, child: buildOrbitChart(_asteroids)),
              ],
            ),
    );
  }

  Widget buildDangerList(List<Asteroid> asteroids) {
    return ListView.builder(
      itemCount: asteroids.length,
      itemBuilder: (context, index) {
        final a = asteroids[index];
        return ListTile(
          title: Text('${a.name} (${a.id})'),
          subtitle: Text(
            'Fullname: ${a.fullName}\n'
            'Diameter: ${a.diameter.toStringAsFixed(2)} km\n'
            'MOID: ${a.moid.toStringAsFixed(4)} AU\n'
            'Danger: ${a.dangerLevel()}',
          ),
        );
      },
    );
  }

  Widget buildOrbitChart(List<Asteroid> asteroids) {
    return ScatterChart(
      ScatterChartData(
        scatterSpots: asteroids
            .map((a) => ScatterSpot(
                  a.a,
                  a.e,
          dotPainter: FlDotCirclePainter(
          color: a.pha == 'Y' ? Colors.red : Colors.blue,
          radius: 6,
          ),
        ))
            .toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}
