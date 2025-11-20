import 'package:shared_preferences/shared_preferences.dart';
import 'settings_model.dart';

class SettingsService {
  static const _kTheme = 'app_theme';
  static const _kFont  = 'app_font';

  Future<SettingsModel> load() async {
    final p = await SharedPreferences.getInstance();
    final themeIndex = p.getInt(_kTheme);
    final fontIndex  = p.getInt(_kFont);
    return SettingsModel(
      theme: AppTheme.values[themeIndex ?? AppTheme.system.index],
      font:  AppFont.values[fontIndex  ?? AppFont.system.index],
    );
  }

  Future<void> save(SettingsModel s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTheme, s.theme.index);
    await p.setInt(_kFont,  s.font.index);
  }
}
