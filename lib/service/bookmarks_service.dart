import 'package:shared_preferences/shared_preferences.dart';

class BookmarksService {
  static const _key = 'bookmarked_article_ids';

  Future<Set<int>> get() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? []).map(int.parse).toSet();
  }

  Future<void> save(Set<int> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, ids.map((e) => e.toString()).toList());
  }
}