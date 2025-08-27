import 'package:flutter/material.dart';
import 'package:neows_app/model/asteroid_nasa_lookup.dart';
import 'package:neows_app/service//nasa_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AsteroidPage extends StatefulWidget {
  const AsteroidPage({super.key});

  @override
  _AsteroidPageState createState() => _AsteroidPageState();
}

class _AsteroidPageState extends State<AsteroidPage> {
  late Future<List<Asteroid>> futureAsteroids;
  final NasaApiService nasaApiService = NasaApiService();

  @override
  void initState() {
    super.initState();
    /*
    futureAsteroids = nasaApiService.fetchAsteroidsToday();
*/
    futureAsteroids =
        nasaApiService.fetchAsteroidsToday('2024-09-01', '2024-09-07');
  }

// Går att öppna URL i Webbläsare men ej i android
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Hoppsan! Kunde inte öppna $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista över Asteroider')),
      body: Center(
        child: FutureBuilder<List<Asteroid>>(
          future: futureAsteroids,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final asteroids = snapshot.data!;

              if (asteroids.isEmpty) {
                return const Text('Något gick snett med NASA:s API.');
              }

              return ListView.builder(
                itemCount: asteroids.length,
                itemBuilder: (context, index) {
                  final asteroid = asteroids[index];
                  return ListTile(
                    title: Text(asteroid.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('.Est Diameter: ${asteroid.estimatedDiameter.toStringAsFixed(2)} km'),
                        Text('Absolut Magnitud: ${asteroid.absoluteMagnitude}'),
                        Text('Relativ hastighet: ${asteroid.relativeVelocity.toStringAsFixed(2)} km/h'),
                        Text('Miss Distance: ${asteroid.asteroidDistance.toStringAsFixed(2)} km'),
                        Text('Date: ${asteroid.asteroidDate}'),
                      ],
                    ),
                    trailing: asteroid.isHazardous
                        ? const Icon(Icons.dangerous_sharp, color: Colors.red)
                        : const Icon(Icons.check, color: Colors.green),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(asteroid.name),
                            content: const Text('Vill du see mer om astroiden?'),
                            actions: [
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                 //   _launchURL(asteroid.nasaJplUrl);
                                    _launchURL('${asteroid.nasaJplUrl}&view=VOP');
                                  },
                                  child: const Text('NASA`s NeoWs Service'),
                              ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            } else {
              return const Text('Ej data.');
            }
          },
        ),
      ),
    );
  }
}
