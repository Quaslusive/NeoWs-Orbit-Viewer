import 'package:flutter/material.dart';
import 'package:neows_app/env/env.dart';
import 'package:neows_app/pages/asteroid_page.dart';
import 'package:neows_app/pages/homepage.dart';
import 'package:neows_app/pages/orbit_hybrid_page.dart';
import 'package:neows_app/pages/orbit_page.dart';
import 'package:neows_app/pages/orbits_webview.dart';
import 'package:neows_app/pages/spacekit_page.dart';
import 'package:neows_app/pages/OrbitWebViewPage.dart';
import 'package:neows_app/pages/asteroid_search.dart';

// import 'env/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // await dotenv.load(fileName:"dotenv.production");
    print("it works ${Env.nasaApiKey}");
  } catch (e) {
    throw Exception("Couldn't load environment file: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        "/homepage": (context) => const HomePage(),
        "/asteroid_page": (context) => const AsteroidPage(),
        "/orbit_page": (context) => const OrbitPage(asteroidId: "2163679"),
        // 465633 (2009 JR5)
        "/orbit_hybrid_page": (context) => const OrbitHybridPage(),
        "/OrbitWebViewPage": (context) => const OrbitWebViewPage(),
        "/asteroid_search": (context) => const AsteroidSearchPage(),
        /*  "/asteroid_danger_page":(context) => const AsteroidDangerPage(asteroids: [],),*/

//        "/orbit_page": (context) => const OrbitPage(semiMajorAxis:1.2, eccentricity: 0.3),
        //"/orbits_webview":(context) => const OrbitsWebViewPage(),

/*        "/spacekit_page":(context) => const OrbitHybridPage()*/
      },
    );
  }
}
