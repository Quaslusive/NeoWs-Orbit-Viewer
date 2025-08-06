import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:neows_app/model/asteroid_csv.dart';

class OrbitPlotPage extends StatelessWidget {
  final List<Asteroid> asteroids;

  const OrbitPlotPage({super.key, required this.asteroids});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orbit Visualizer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ScatterChart(
          ScatterChartData(
            scatterSpots: asteroids.map((a) {
              return ScatterSpot(
                a.a,
                a.e,
                dotPainter: FlDotCirclePainter(
                  color: Colors.blue,
                  radius: 6,
                ),
              );

            }).toList(),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1)),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1)),
                ),
              ),
            ),

          ),
        ),
      ),
    );
  }
}
