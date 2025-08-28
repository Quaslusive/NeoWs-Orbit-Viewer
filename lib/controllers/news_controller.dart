// lib/controllers/news_controller.dart
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

  String? _search;
  String? get search => _search;

  Future<void> init() async {
    if (_items.isNotEmpty) return;
    await refresh();
  }

  Future<void> refresh({String? newSearch}) async {
    _search = newSearch ?? _search;
    _loading = true; notifyListeners();
    try {
      _items = await repo.refresh(search: _search);
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || exhausted) return;
    _loading = true; notifyListeners();
    try {
      _items = await repo.loadMore(search: _search);
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
