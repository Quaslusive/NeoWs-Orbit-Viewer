import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light = ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.black87,
      textColor: Colors.black87,
    ),
  );

  static ThemeData dark = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.amber,
      brightness: Brightness.dark,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.black87,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.yellowAccent,
      textColor: Colors.white,
    ),
  );
}
