import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neows_app/pages/settings_page.dart';
import 'package:neows_app/pages/acknowledgements_page.dart';
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatelessWidget {
  const HomePage({super.key});


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
                Navigator.pushNamed(context, "/acknowledgements_page");
              },
            ),    ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/settings_page");
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
          child: const Text("Sök Asteroider med NeoWs och MPC"),
          onPressed: () {
            Navigator.pushNamed(context, "/asteroid_search");
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          child: const Text("Gå till NeoWs "),
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
      ],
    ),
    );
  }
}