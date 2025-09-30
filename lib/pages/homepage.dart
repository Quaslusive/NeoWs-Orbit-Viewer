import 'package:flutter/material.dart';
import 'package:neows_app/widget/orbit_thumb.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Homepage")),
      drawer: Drawer(
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 100,
        shadowColor: Colors.black54,
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
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("acknowledgements"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/acknowledgements_page");
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/settings_page");
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: OrbitThumb(
              asteroidA: 1.6,
              asteroidE: 0.35,
              asteroidPeriod: const Duration(seconds: 12),
              inclinationDeg: 15,
              showApsides: true,
              showMoon: true,
              showParallaxStars: true,
              cometTail: true,
              showInfoChip: true,
              objectName: '2010 PK9',
              showAsteroidLabel: true,
              speedScale: 0.0,
              enableScrub: true,
              heroTag: 'orbit-thumb-2010PK9',
              onTap: () {

                //     Navigator.pushNamed(context, "/orbit_page");
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            child: const Text("Orbit Viewer"),
            onPressed: () {
              Navigator.pushNamed(context, "/orbit_viewer_3d_today");
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            child: const Text("Sök Asteroider med NeoWs och Asterank"),
            onPressed: () {
              Navigator.pushNamed(context, "/asteroid_search");
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            child: const Text("News "),
            onPressed: () {
              // Navigator.of(context).pushNamed('/news');
              Navigator.pushNamed(context, "/news");
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            child: const Text("Gå till NeoWs "),
            onPressed: () {
              Navigator.pushNamed(context, "/asteroid_page");
            },
          ),
        ],
      ),
    );
  }
}
