import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neows_app/env/env.dart';
import 'package:neows_app/pages/asteroid_search_page.dart';
import 'package:neows_app/pages/acknowledgements_page.dart';
import 'package:neows_app/pages/orbit_viewer_3d_page.dart';

// import 'package:neows_app/pages/settings_page.dart';
import 'package:neows_app/settings/settings_controller.dart';
import 'package:neows_app/settings/settings_model.dart';
import 'package:neows_app/settings/settings_service.dart';
// import 'package:package_info_plus/package_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final settings = SettingsController(SettingsService());
  await settings.init();

  if (kDebugMode) {
/*    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;  print('App Name: $appName');
    print('Package Name: $packageName');
    print('Version: $version');
    print('Build Number: $buildNumber');*/

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
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  String? _fontFamilyFor(AppFont f) {
    switch (f) {
      case AppFont.evaStandard:
        return 'EVA-Matisse_Standard';
      //   case AppFont.evaClassic:
      //   return 'EVA-Matisse_Classic';
      case AppFont.system:
        return null;
    }
  }

  ThemeData _applyFont(ThemeData base, String? family) {
    if (family == null) return base; // system font
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: family),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: family),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final selectedFontFamily = _fontFamilyFor(settings.state.font);
        final themedLight = _applyFont(_appLightTheme, selectedFontFamily);
        final themedDark = _applyFont(_appDarkTheme, selectedFontFamily);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NeoWS Orbit Viewer',
          themeMode: _toThemeMode(settings.state.theme),
          theme: themedLight,
          darkTheme: themedDark,
          home: OrbitViewer3DPage(apiKey: Env.nasaApiKey, controller: settings),
          routes: {
            "/orbit_viewer_3d_page": (_) =>
                OrbitViewer3DPage(apiKey: Env.nasaApiKey, controller: settings),
            "/asteroid_search_page": (_) => const AsteroidSearchPage(),
            "/acknowledgements_page": (_) => const AcknowledgementsPage(),
            // "/settings_page":        (_) => SettingsPage(controller: settings),
          },
        );
      },
    );
  }
}

final ThemeData _appLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.grey, brightness: Brightness.light),
  appBarTheme: const AppBarTheme(centerTitle: false),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.grey,
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black,
    textColor: Colors.black,
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.grey),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
);

final ThemeData _appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.amber, brightness: Brightness.dark),
  appBarTheme: const AppBarTheme(centerTitle: false),
  drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.black87,
      surfaceTintColor: Colors.transparent),
  listTileTheme: const ListTileThemeData(
      iconColor: Colors.yellowAccent,
      textColor: Colors.white),
  outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.amber),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
);
