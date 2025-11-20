import 'package:flutter/material.dart';

enum AppTheme { light, dark, system }
enum AppFont { system, evaStandard, /*evaClassic*/ }

@immutable
class SettingsModel {
  final AppTheme theme;
  final AppFont font;
  final bool invertY;
  final bool showAxes;
  final bool showGrid;
  final bool showOrbits;
  final double rotateSens; // 0.002–0.030
  final double zoomSens;   // 0.01–0.20


  const SettingsModel({
    this.theme = AppTheme.system,
    this.font = AppFont.system,
    this.invertY = false,
    this.showAxes = false,
    this.showGrid = true,
    this.showOrbits = true,
    this.rotateSens = 0.010,
    this.zoomSens = 0.06,

  });

  SettingsModel copyWith({
    AppTheme? theme,
    AppFont? font,
    bool? invertY,
    bool? showAxes,
    bool? showGrid,
    bool? showOrbits,
    double? rotateSens,
    double? zoomSens,
  }) {
    return SettingsModel(
      theme: theme ?? this.theme,
      font: font ?? this.font,
      invertY: invertY ?? this.invertY,
      showAxes: showAxes ?? this.showAxes,
      showGrid: showGrid ?? this.showGrid,
      showOrbits: showOrbits ?? this.showOrbits,
      rotateSens: rotateSens ?? this.rotateSens,
      zoomSens: zoomSens ?? this.zoomSens,
    );
  }
}
