import 'package:flutter/material.dart';
import 'package:neows_app/settings/settings_model.dart';
import 'package:neows_app/settings/settings_service.dart';



class SettingsController extends ChangeNotifier {
  final SettingsService _service;
  SettingsModel _state = const SettingsModel();
  SettingsModel get state => _state;

  SettingsController(this._service);

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
