import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neows_app/env/env.dart';

import 'package:neows_app/pages/asteroid_page.dart';
import 'package:neows_app/pages/asteroid_search.dart';
import 'package:neows_app/pages/acknowledgements_page.dart';
import 'package:neows_app/pages/orbit_viewer_3d_page.dart';
import 'package:neows_app/pages/news_page.dart';
import 'package:neows_app/pages/settings_page.dart';

import 'package:neows_app/settings/settings_controller.dart';
import 'package:neows_app/settings/settings_model.dart';
import 'package:neows_app/settings/settings_service.dart';

import 'package:neows_app/service/news_repository.dart';
import 'package:neows_app/service/spaceflight_news_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController(SettingsService());
  await settings.init();

  if (kDebugMode) {
    try {
      print("NASA NeoWs API: ${Env.nasaApiKey}");
    } catch (e) {
      throw Exception("😓 Couldn't load environment file: $e");
    }
  }

  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsController settings;
  const MyApp({super.key, required this.settings});

  ThemeMode _toThemeMode(AppTheme t) {
    switch (t) {
      case AppTheme.light: return ThemeMode.light;
      case AppTheme.dark:  return ThemeMode.dark;
      case AppTheme.system:
      return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bygg om när SettingsController ändras (t.ex. vid tema-byte)
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Asteroid Tracker',
          themeMode: _toThemeMode(settings.state.theme),
          theme: _appLightTheme,
          darkTheme: _appDarkTheme,

          home: const OrbitViewer3DPage(apiKey: Env.nasaApiKey),
          routes: {
            "/orbit_viewer_3d_page": (_) => const OrbitViewer3DPage(apiKey: Env.nasaApiKey),
            "/asteroid_search":      (_) => const AsteroidSearchPage(),
            "/news":                 (_) => NewsPage(repo: NewsRepository(SpaceflightNewsService())),
            "/acknowledgements_page":(_) => const AcknowledgementsPage(),
            "/settings_page":        (_) => SettingsPage(controller: settings),
            "/asteroid_page":        (_) => const AsteroidPage(),
          },
        );
      },
    );
  }
}

/// -------------------- Teman --------------------

final ThemeData _appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.light),

  // AppBar följer färgschema
  appBarTheme: const AppBarTheme(centerTitle: false),

  // Drawer och listor
  drawerTheme: const DrawerThemeData(
    surfaceTintColor: Colors.transparent,
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black87,
    textColor: Colors.black87,
  ),

   fontFamily: 'EVA-Matisse_Standard',
);

final ThemeData _appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark),

  appBarTheme: const AppBarTheme(centerTitle: false),

  drawerTheme: const DrawerThemeData(
    // Bakgrunden i mörkt läge
    backgroundColor: Colors.black87,
    surfaceTintColor: Colors.transparent,
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.yellowAccent,
    textColor: Colors.white,
  ),

   fontFamily: 'EVA-Matisse_Classic',
);
