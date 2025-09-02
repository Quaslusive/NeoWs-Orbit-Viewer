import 'package:shared_preferences/shared_preferences.dart';

enum NewsViewMode { list, grid }
enum NewsDensity { comfortable, compact }
enum NewsSort { newest, oldest, sourceAZ }

class FilterPrefs {
  static const _kDays = 'news_days';
  static const _kTopic = 'news_topic';
  static const _kSource = 'news_source';
  static const _kQuery = 'news_query';
  static const _kView = 'news_view';
  static const _kDensity = 'news_density';
  static const _kSort = 'news_sort';
  static const _kOpenInApp = 'news_open_in_app';
  static const _kLowData = 'news_low_data';
  static const _kLastOpenedAt = 'news_last_opened_at';

  Future<void> saveFilters({
    required int days,
    required int topic,
    required int source,
    required String query,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDays, days);
    await p.setInt(_kTopic, topic);
    await p.setInt(_kSource, source);
    await p.setString(_kQuery, query);
  }

  Future<({int days,int topic,int source,String query})> loadFilters() async {
    final p = await SharedPreferences.getInstance();
    return (
    days: p.getInt(_kDays) ?? 0,
    topic: p.getInt(_kTopic) ?? 0,
    source: p.getInt(_kSource) ?? 0,
    query: p.getString(_kQuery) ?? ''
    );
  }

  Future<void> saveViewMode(NewsViewMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kView, mode.index);
  }
  Future<NewsViewMode> loadViewMode() async {
    final p = await SharedPreferences.getInstance();
    return NewsViewMode.values[p.getInt(_kView) ?? 0];
  }

  Future<void> saveDensity(NewsDensity d) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kDensity, d.index);
  }
  Future<NewsDensity> loadDensity() async {
    final p = await SharedPreferences.getInstance();
    return NewsDensity.values[p.getInt(_kDensity) ?? 0];
  }

  Future<void> saveSort(NewsSort s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSort, s.index);
  }
  Future<NewsSort> loadSort() async {
    final p = await SharedPreferences.getInstance();
    return NewsSort.values[p.getInt(_kSort) ?? 0];
  }

  Future<void> saveOpenInApp(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOpenInApp, v);
  }
  Future<bool> loadOpenInApp() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOpenInApp) ?? false;
  }

  Future<void> saveLowData(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLowData, v);
  }
  Future<bool> loadLowData() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLowData) ?? false;
  }

  Future<void> saveLastOpenedAt(DateTime t) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastOpenedAt, t.toUtc().toIso8601String());
  }
  Future<DateTime?> loadLastOpenedAt() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kLastOpenedAt);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toUtc();
  }
}
