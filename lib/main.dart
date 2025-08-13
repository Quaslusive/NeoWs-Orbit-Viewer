import 'package:flutter/material.dart';
import 'package:neows_app/env/env.dart';
import 'package:neows_app/pages/asteroid_page.dart';
import 'package:neows_app/pages/homepage.dart';
import 'package:neows_app/pages/orbit_hybrid_page.dart';
import 'package:neows_app/pages/asteroid_search.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {

    print("it works ${Env.nasaApiKey}");
  } catch (e) {
    throw Exception("Couldn't load environment file: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      routes: {
        "/homepage": (context) => const HomePage(),
        "/asteroid_page": (context) => const AsteroidPage(),
        "/orbit_hybrid_page": (context) => const OrbitHybridPage(),
        "/asteroid_search": (context) => const AsteroidSearchPage(),

      },
    );
  }
}
