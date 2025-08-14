import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
/*

  Future<List<Asteroid>> loadAsteroidsFromCsv() async {
    final rawData = await rootBundle.loadString('assets/astroidReadTest.csv');
    final csvData = const CsvToListConverter(eol: '\\n').convert(rawData);
    final rows = csvData.sublist(1); // Skip header

    return rows.map((row) {
      return Asteroid(
        id: row[0].toString(),
        name: row[4].toString(),
        fullName: row[2].toString(),
        diameter: double.tryParse(row[15].toString()) ?? 0.0,
        albedo: double.tryParse(row[17].toString()) ?? 0.0,
        neo: row[6].toString(),
        pha: row[7].toString(),
        rotationPeriod: double.tryParse(row[18].toString()) ?? 0.0,
        classType: row[60].toString(),
        orbitId: int.tryParse(row[27].toString()) ?? 0,
        moid: double.tryParse(row[45].toString()) ?? 0.0,
        a: double.tryParse(row[33].toString()) ?? 0.0,
        e: double.tryParse(row[32].toString()) ?? 0.0,
      );
    }).toList();
  }
*/


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hemsida")),
      drawer: Drawer(
        backgroundColor: Colors.deepOrangeAccent[100],
        child: Column(
          children: [
            DrawerHeader(
              child: Image.asset(
                "lib/assets/images/icon/icon1.png",
                width: 100,
                height: 100,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/homesida");
              },
            ),
            ListTile(
              leading: const Icon(Icons.rocket),
              title: const Text("Asteroid Sida"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/asteroid_page");
              },
            ),
            ListTile(
              leading: const Icon(Icons.rocket),
              title: const Text("Orbit Sida"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/orbit_page");
              },
            ),  ListTile(
              leading: const Icon(Icons.info),
              title: const Text("acknowledgements"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/orbit_page");
              },
            ),    ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/orbit_page");
              },
            ),
          ],
        ),
      ),   body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: SvgPicture.asset(
            'lib/assets/images/NASA_Worm_logo.svg',
         //   'lib/assets/images/icon/icon1.png',
            width: 200,
            height: 200,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          child: const Text("Gå till Asteroid sidan"),
          onPressed: () {
            Navigator.pushNamed(context, "/asteroid_page");
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          child: const Text("Gå till Orbit sidan"),
          onPressed: () {
            Navigator.pushNamed(context, "/orbit_page");
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          child: const Text("Gå till hybrid Orbit webviewer"),
          onPressed: () {
            Navigator.pushNamed(context, "/orbit_hybrid_page");
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          child: const Text("Gå till Spacekit Orbit webviewer"),
          onPressed: () {
            Navigator.pushNamed(context, "/OrbitWebViewPage");
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          child: const Text("Sök Asteroider (CSV)"),
          onPressed: () {
            Navigator.pushNamed(context, "/asteroid_search");
          },
        ),
      ],
    ),
    );
  }
}