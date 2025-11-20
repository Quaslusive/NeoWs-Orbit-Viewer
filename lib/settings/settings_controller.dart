import 'package:flutter/material.dart';
import 'package:neows_app/settings/settings_model.dart';
import 'package:neows_app/settings/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsController extends ChangeNotifier {
  static const _kTheme = 'theme';
  static const _kFont = 'font';
  static const _kInvertY = 'invert_y';
  static const _kShowAxes = 'show_axes';
  static const _kShowGrid = 'show_grid';
  static const _kRotateSens = 'rotate_sens';
  static const _kZoomSens = 'zoom_sens';
  static const _kShowOrbits = 'show_orbits';

  final SettingsService _service;

  SettingsModel _state = const SettingsModel();
  SettingsModel get state => _state;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _state = _state.copyWith(
      theme: AppTheme.values[p.getInt(_kTheme) ?? _state.theme.index],
      font:  AppFont.values[p.getInt(_kFont) ?? _state.font.index],
      invertY:    p.getBool(_kInvertY) ?? _state.invertY,
      showAxes:   p.getBool(_kShowAxes) ?? _state.showAxes,
      showGrid:   p.getBool(_kShowGrid) ?? _state.showGrid,
      showOrbits: p.getBool(_kShowOrbits) ?? _state.showOrbits,
      rotateSens: p.getDouble(_kRotateSens) ?? _state.rotateSens,
      zoomSens:   p.getDouble(_kZoomSens) ?? _state.zoomSens,
    );
    notifyListeners();
  }

  SettingsController(this._service);

  Future<void> setInvertY(bool v) async {
    _state = _state.copyWith(invertY: v); notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setBool(_kInvertY, v);
  }
  Future<void> setShowAxes(bool v) async {
    _state = _state.copyWith(showAxes: v); notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setBool(_kShowAxes, v);
  }
  Future<void> setShowGrid(bool v) async {
    _state = _state.copyWith(showGrid: v); notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setBool(_kShowGrid, v);
  }
  Future<void> setShowOrbits(bool v) async {
    _state = _state.copyWith(showOrbits: v); notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setBool(_kShowOrbits, v);
  }
  Future<void> setRotateSens(double v) async {
    _state = _state.copyWith(rotateSens: v); notifyListeners();
    final p = await SharedPreferences.getInstance(); await p.setDouble(_kRotateSens, v);
  }
  Future<void> setZoomSens(double v) async {
    _state = _state.copyWith(zoomSens: v); notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kZoomSens, v);
  }


  Future<void> init() async {
    _state = await _service.load();
    notifyListeners();
  }

  Future<void> update(SettingsModel next) async {
    _state = next;
    notifyListeners();
    await _service.save(_state);
  }
}
