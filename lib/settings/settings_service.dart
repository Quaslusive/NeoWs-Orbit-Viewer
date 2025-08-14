import 'package:neows_app/settings/settings_model.dart';
import 'package:neows_app/settings/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsService {
  static const _kUnit = 'unit';                 // 0=km,1=mi
  static const _kDays = 'defaultDays';
  static const _kHaz = 'hazardousOnly';
  static const _kGrid = 'showEclipticGrid';
  static const _kLine = 'orbitLineWidth';
  static const _kTheme = 'theme';               // 0=system,1=light,2=dark

  Future<SettingsModel> load() async {
    final p = await SharedPreferences.getInstance();
    return SettingsModel(
      unit: (p.getInt(_kUnit) ?? 0) == 0 ? DistanceUnit.km : DistanceUnit.mi,
      defaultDays: p.getInt(_kDays) ?? 3,
      hazardousOnly: p.getBool(_kHaz) ?? false,
      showEclipticGrid: p.getBool(_kGrid) ?? true,
      orbitLineWidth: p.getDouble(_kLine) ?? 1.5,
      theme: AppTheme.values[p.getInt(_kTheme) ?? 0],
    );
  }

  Future<void> save(SettingsModel s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kUnit, s.unit.index);
    await p.setInt(_kDays, s.defaultDays);
    await p.setBool(_kHaz, s.hazardousOnly);
    await p.setBool(_kGrid, s.showEclipticGrid);
    await p.setDouble(_kLine, s.orbitLineWidth);
    await p.setInt(_kTheme, s.theme.index);
  }
}
