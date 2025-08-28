import 'package:flutter/foundation.dart';
import 'package:neows_app/model/spaceflight_article.dart';
import 'package:neows_app/service/news_repository.dart';

class NewsController extends ChangeNotifier {
  final NewsRepository repo;
  NewsController(this.repo);

  List<SpaceflightArticle> _items = [];
  List<SpaceflightArticle> get items => _items;

  bool _loading = false;
  bool get loading => _loading;
  bool get exhausted => repo.exhausted;

  String? get search => repo.search;
  DateTime? get since => repo.since;
  String? get newsSite => repo.newsSite;

  Future<void> init() async {
    if (_items.isNotEmpty) return;
    await refresh();
  }

  Future<void> refresh({
    String? newSearch,
    DateTime? newSince,
    String? newNewsSite,
  }) async {
    _loading = true; notifyListeners();
    try {
      _items = await repo.refresh(
        search: newSearch ?? search,
        since: newSince ?? since,
        newsSite: newNewsSite ?? newsSite,
      );
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || exhausted) return;
    _loading = true; notifyListeners();
    try {
      _items = await repo.loadMore();
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
