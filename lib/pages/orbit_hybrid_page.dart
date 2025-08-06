import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:neows_app/env/env.dart';

class OrbitHybridPage extends StatefulWidget {
  const OrbitHybridPage({super.key});

  @override
  State<OrbitHybridPage> createState() => _OrbitHybridPageState();
}

class _OrbitHybridPageState extends State<OrbitHybridPage> {
  final String apiKey = Env.nasaApiKey; // Replace with your NASA API key
  final TextEditingController _idController = TextEditingController();
  InAppWebViewController? _webViewController;
  String asteroidName = "";
  bool loading = false;


  Future<void> loadAsteroidOrbit(String id) async {
    setState(() {
      loading = true;
      asteroidName = "";
    });


    final url = "https://api.nasa.gov/neo/rest/v1/neo/$id?api_key=$apiKey";
    try {
      final res = await http.get(Uri.parse(url));
      final json = jsonDecode(res.body);


      final orbit = json["orbital_data"];
/*
      final orbitParams = {
     "semiMajorAxis": 1.2,
    "eccentricity": 0.3,
    "inclination": 5.0,
    "ascendingNode": 120.0,
    "argumentOfPeriapsis": 45.0,
    "meanAnomaly": 0.0,
    "name": "Test Asteroid"
*/



      final orbitParams = {
        "semiMajorAxis": double.tryParse(orbit["semi_major_axis"] ?? "0") ?? 0,
        "eccentricity": double.parse(orbit["eccentricity"]),
        "inclination": double.parse(orbit["inclination"]),
        "ascendingNode": double.parse(orbit["ascending_node_longitude"]),
        "argumentOfPeriapsis": double.parse(orbit["perihelion_argument"]),
        "meanAnomaly": double.parse(orbit["mean_anomaly"]),
        "name": json["name"]

      };

      setState(() {
        asteroidName = json["name"];
        loading = false;
      });

      final jsonStr = jsonEncode(orbitParams);
      print("Sending to WebView: $jsonStr");
      final result = await _webViewController?.evaluateJavascript(source: '''
  window.loadOrbitFromFlutter($jsonStr);
''');
      print("JS result: $result");


  print(jsonStr);
 /* print(orbit[0]);
  print(orbit[1]);
  print(orbit[2]);*/
  print("----------------");
  print("🔍 semi_major_axis (raw): ${orbit["semi_major_axis"]}");

/*

      final jsonStr = jsonEncode(orbitParams).replaceAll("'", r"\'");
      await _webViewController?.evaluateJavascript(source: '''
  window.loadOrbitFromFlutter(JSON.parse('$jsonStr'));
''');
*/

/*
      final jsonStr = jsonEncode(orbitParams);
      await _webViewController?.evaluateJavascript(source: '''
  window.loadOrbitFromFlutter(JSON.parse('$jsonStr'));
''');
*/

/*      // Inject data into WebView
      await _webViewController?.evaluateJavascript(source: '''
  window.loadOrbitFromFlutter(${jsonEncode(orbitParams)});
''');
      */

/*
      final jsonStr = jsonEncode(orbitParams);
      await _webViewController?.evaluateJavascript(source: """
        window.loadOrbitFromFlutter($jsonStr);
      """);
   */
    } catch (e) {
      setState(() {
        asteroidName = "❌ Error loading asteroid";
        loading = false;
      });
      debugPrint("Error: $e");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hybrid Orbit Viewer")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: "Asteroid ID",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final id = _idController.text.trim();
                  if (id.isNotEmpty) loadAsteroidOrbit(id);
                },
                child: const Text("Load"),
              )
            ]),
          ),
          if (loading) const LinearProgressIndicator(),
          if (asteroidName.isNotEmpty) Text("Asteroid: $asteroidName"),
    Expanded(
    child: InAppWebView(
    initialUrlRequest: URLRequest(
    url: WebUri("https://quaslusive.github.io/orbits/"),
    ),
    onWebViewCreated: (controller) {
    _webViewController = controller;
    },
    onLoadStop: (controller, url) async {
    print("✅ WebView finished loading: $url");
    _webViewController = controller;

    // TEST: Inject test orbit manually
    const testOrbit = {
    "semiMajorAxis": 1.2,
    "eccentricity": 0.3,
    "inclination": 5.0,
    "ascendingNode": 120.0,
    "argumentOfPeriapsis": 45.0,
    "meanAnomaly": 0.0,
    "name": "Demo"
    };
    final jsonStr = jsonEncode(testOrbit);
    final result = await _webViewController?.evaluateJavascript(source: '''
        window.loadOrbitFromFlutter($jsonStr);
      ''');
    print("✅ JS test result: $result");
    },
    ),
    ),

    /*
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(

                url: WebUri("https://quaslusive.github.io/orbits/"), // ← replace with your hosted viewer

                // url: WebUri("https://ssd-api.jpl.nasa.gov/sbdb.api?sstr=Eros"), // ← replace with your hosted viewer
              ),
              onLoadStop: (controller, url) async {
                _webViewController = controller;
                print("✅ WebView loaded: $url");
                // Optional: preload a default orbit
              },
            ),
          ),
    */
        ],
      ),
    );
  }
}
