import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neows_app/env/env.dart';
import 'package:neows_app/orbit_painter.dart';

class OrbitPage extends StatefulWidget {
  final String asteroidId;
  const OrbitPage({super.key, required this.asteroidId});

  @override
  State<OrbitPage> createState() => _OrbitPageState();
}

class _OrbitPageState extends State<OrbitPage> {
  double? semiMajorAxis; // in AU
  double? eccentricity;
  bool isLoading = true;
  final String apiKey = Env.nasaApiKey;

  @override
  void initState() {
    super.initState();
    fetchOrbitalData();
  }

  Future<void> fetchOrbitalData() async {
    final url =
        "https://api.nasa.gov/neo/rest/v1/neo/${widget.asteroidId}?api_key=$apiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final orbit = json["orbital_data"];
      setState(() {
        semiMajorAxis = double.tryParse(orbit["semi_major_axis"] ?? "1.0");
        eccentricity = double.tryParse(orbit["eccentricity"] ?? "0.0");
        isLoading = false;
      });
    } else {
      throw Exception("Failed to load orbital data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orbit Visualizer")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: CustomPaint(
          size: const Size(300, 300),
          painter: OrbitPainter(
            semiMajorAxis: semiMajorAxis ?? 1.0,
            eccentricity: eccentricity ?? 0.0,
          ),
        ),
      ),
    );
  }
}
