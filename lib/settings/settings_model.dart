import 'package:flutter/material.dart';

enum DistanceUnit { km, mi }
enum AppTheme { system, light, dark }

class SettingsModel {
  final DistanceUnit unit;
  final int defaultDays;          // for /feed date range
  final bool hazardousOnly;
  final bool showEclipticGrid;
  final double orbitLineWidth;    // 1.0–4.0
  final AppTheme theme;

  const SettingsModel({
    this.unit = DistanceUnit.km,
    this.defaultDays = 3,
    this.hazardousOnly = false,
    this.showEclipticGrid = true,
    this.orbitLineWidth = 1.5,
    this.theme = AppTheme.system,
  });

  SettingsModel copyWith({
    DistanceUnit? unit,
    int? defaultDays,
    bool? hazardousOnly,
    bool? showEclipticGrid,
    double? orbitLineWidth,
    AppTheme? theme,
  }) => SettingsModel(
    unit: unit ?? this.unit,
    defaultDays: defaultDays ?? this.defaultDays,
    hazardousOnly: hazardousOnly ?? this.hazardousOnly,
    showEclipticGrid: showEclipticGrid ?? this.showEclipticGrid,
    orbitLineWidth: orbitLineWidth ?? this.orbitLineWidth,
    theme: theme ?? this.theme,
  );
}
