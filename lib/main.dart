import 'package:flutter/material.dart';
import 'package:neows_app/env/env.dart';
import 'package:neows_app/pages/asteroid_page.dart';
import 'package:neows_app/pages/homepage.dart';
import 'package:neows_app/pages/orbit_hybrid_page.dart';
import 'package:neows_app/pages/asteroid_search.dart';
import 'package:neows_app/pages/acknowledgements_page.dart';
import 'package:neows_app/settings/settings_controller.dart';
import 'package:neows_app/settings/settings_model.dart';
import 'package:neows_app/settings/settings_service.dart';
import 'package:neows_app/pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Create & init the settings controller
  final settings = SettingsController(SettingsService());
  await settings.init();

  try {
    print("it works ${Env.nasaApiKey}");
  } catch (e) {
    throw Exception("Couldn't load environment file: $e");
  }

  // 2) Pass it into the app (note: no const)
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsController settings;
  const MyApp({super.key, required this.settings});

  ThemeMode _toThemeMode(AppTheme t) =>
      t == AppTheme.light ? ThemeMode.light :
      t == AppTheme.dark  ? ThemeMode.dark  : ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp when settings change (e.g., theme switch)
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: _toThemeMode(settings.state.theme),
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
          home: const HomePage(),
          routes: {
            "/homepage": (context) => const HomePage(),
            "/asteroid_page": (context) => const AsteroidPage(),
            "/orbit_hybrid_page": (context) => const OrbitHybridPage(),
            "/asteroid_search": (context) => const AsteroidSearchPage(),
            "/acknowledgements_page": (context) => const AcknowledgementsPage(),
            // Controller is now in scope here ✅
            "/settings_page": (context) => SettingsPage(controller: settings),
          },
        );
      },
    );
  }
}
