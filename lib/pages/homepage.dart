import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: SvgPicture.asset(
              'lib/assets/images/NASA_Worm_logo.svg',
              width: 200,
              height: 200,
            ),
          ),
          const SizedBox(height: 40), // instead of Spacer for better control
          Center(
            child: ElevatedButton(
              child: const Text("Gå till Asteroid sidan"),
              onPressed: () {
                Navigator.pushNamed(context, "/asteroid_page");
              },
            ),
          ),
          const SizedBox(height: 40), // instead of Spacer for better control
          Center(
            child: ElevatedButton(
              child: const Text("Gå till Orbit sidan"),
              onPressed: () {
                Navigator.pushNamed(context, "/orbit_page");
              },
            ),
          ),
          const SizedBox(height: 40), // instead of Spacer for better control
          Center(
            child: ElevatedButton(
              child: const Text("Gå till Orbit webviewer"),
              onPressed: () {
                Navigator.pushNamed(context, "/orbits_webview");
              },
            ),
          ),
          const SizedBox(height: 40), // instead of Spacer for better control
          Center(
            child: ElevatedButton(
              child: const Text("Gå till hybrid Orbit webviewer"),
              onPressed: () {
                Navigator.pushNamed(context, "/orbit_hybrid_page");
              },
            ),
          ),
          const SizedBox(height: 40), // instead of Spacer for better control
          Center(
            child: ElevatedButton(
              child: const Text("Gå till Spacekit Orbit webviewer"),
              onPressed: () {
                Navigator.pushNamed(context, "/OrbitWebViewPage");
              },
            ),
          ), const SizedBox(height: 40), // instead of Spacer for better control
          Center(
            child: ElevatedButton(
              child: const Text("Sök Astroider CSV"),
              onPressed: () {
                Navigator.pushNamed(context, "/asteroid_search");
              },
            ),
          ), const SizedBox(height: 40), // instead of Spacer for better control
          Center(
            child: ElevatedButton(
              child: const Text(" Danger "),
              onPressed: () {
                Navigator.pushNamed(context, "/asteroid_danger_page");
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),

    );
  }
}
