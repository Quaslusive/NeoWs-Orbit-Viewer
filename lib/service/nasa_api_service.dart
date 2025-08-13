import 'dart:convert';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neows_app/model/asteroid_nasa_lookup.dart';
import 'package:http/http.dart' as http;
import 'package:neows_app/env/env.dart'; // Import ENVied class

class NasaApiService {
 // final String apiKey = dotenv.env['API_KEY'] ?? 'k';
  final String apiKey = Env.nasaApiKey;

// har försökt att använda "today" endpont men får
// "Error: TypeError: null: type "Null" is not a subtype of a type"List<dynamic>"

/*  Future<List<Asteroid>> fetchAsteroidsToday() async {
    final url =
        'https://api.nasa.gov/neo/rest/v1/feed?today&api_key=$apiKey';
    final response = await http.get(Uri.parse(url));*/

  Future<List<Asteroid>> fetchAsteroidsToday(String startDate, String endDate) async {
    final url =
        'https://api.nasa.gov/neo/rest/v1/feed?start_date=$startDate&end_date=$endDate&api_key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['near_earth_objects'] != null) {
        final Map<String, dynamic> neoData = data['near_earth_objects'];
        final List<dynamic> allAsteroids = neoData.values.expand((e) => e).toList();

        if (allAsteroids.isNotEmpty) {
          return allAsteroids
              .map((json) => Asteroid.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Inga asteroider hittades.');
      }
    } else {
      throw Exception('Fel vid hämtning. Kod: ${response.statusCode}');
    }
  }
}
