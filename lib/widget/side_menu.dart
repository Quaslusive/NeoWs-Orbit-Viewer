import 'package:flutter/material.dart';
import 'package:neows_app/settings/settings_controller.dart';
import 'package:neows_app/settings/settings_model.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
  //  required this.appVersion,
    /// previous patch: v 0.8.9
    this.manuelVersion = 'v1.0.0 alpha', // todo Dont forget to update me
    required this.onGoHomePage,
  //  required this.onGoSearch,
    required this.onGoCredits,
   // required this.onGoSettings,
    required this.controller,

  });
// final String? appVersion;
  final String? manuelVersion;

  final VoidCallback onGoHomePage;
 // final VoidCallback onGoSearch;
  final VoidCallback onGoCredits;
  // final VoidCallback onGoSettings;

  final SettingsController controller;

  ThemeMode _themeModeFor(AppTheme t) {
    switch (t) {
      case AppTheme.light:  return ThemeMode.light;
      case AppTheme.dark:   return ThemeMode.dark;
      case AppTheme.system: return ThemeMode.system;
    }
  }
  AppTheme _appThemeFrom(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:  return AppTheme.light;
      case ThemeMode.dark:   return AppTheme.dark;
      case ThemeMode.system: return AppTheme.system;
    }
  }
  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final model = controller.state;

    void setTheme(ThemeMode mode) {
      controller.update(model.copyWith(theme: _appThemeFrom(mode)));
    }

    void setFont(AppFont f) {
      controller.update(model.copyWith(font: f));
    }

    return Drawer(
      elevation: 100,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "lib/assets/images/icon/icon1.png",
                      width: 75,
                      height: 75,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Created by Quaslusive',
                      style: TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version: $manuelVersion',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                      context, "/orbit_viewer_3d_page");
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text("Credits"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, "/acknowledgements_page");
                },
              ),
              const Divider(height: 5),
              const SizedBox(height: 5),
              const Text('Themes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),

              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ],
                selected: {_themeModeFor(model.theme)},
                onSelectionChanged: (s) => setTheme(s.first),
                showSelectedIcon: false,
              ),

              const SizedBox(height: 5),
              const Divider(height: 5),
              const SizedBox(height: 10),
              const Text('Fonts',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),

              SegmentedButton<AppFont>(
                segments: const [
                  ButtonSegment(
                      value: AppFont.evaStandard, label: Text('Standard')),
                  ButtonSegment(
                      value: AppFont.system, label: Text('System')),
                ],
                selected: {model.font},
                onSelectionChanged: (s) => setFont(s.first),
                showSelectedIcon: false,
              ),

              const SizedBox(height: 10),
              const Divider(height: 8),

              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Invert Y'),
                value: s.invertY,
                onChanged: controller.setInvertY,
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show axes'),
                value: s.showAxes,
                onChanged: controller.setShowAxes,
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show grid'),
                value: s.showGrid,
                onChanged: controller.setShowGrid,
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show orbit'),
                value: s.showOrbits,
                onChanged: controller.setShowOrbits,
              ),

              const Divider(height: 5),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rotate sensitivity'),
                subtitle: Slider(
                  value: s.rotateSens,
                  min: 0.002,
                  max: 0.030,
                  divisions: 19,
                  onChanged: controller.setRotateSens,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Zoom sensitivity'),
                subtitle: Slider(
                  value: s.zoomSens,
                  min: 0.01,
                  max: 0.20,
                  divisions: 19,
                  onChanged: controller.setZoomSens,
                ),
              ),

              const SizedBox(height: 10), // lite luft i botten
            ],
          ),
        ),
      ),
    );

  }
}
