// lib/service/news_repository.dart
import 'package:neows_app/model/spaceflight_article.dart';
import 'package:neows_app/service/spaceflight_news_service.dart';

class NewsRepository {
  final SpaceflightNewsService _api;
  final List<SpaceflightArticle> _cache = [];
  int _offset = 0;
  final int pageSize;
  bool _exhausted = false;

  NewsRepository(this._api, {this.pageSize = 20});

  List<SpaceflightArticle> get articles => List.unmodifiable(_cache);
  bool get exhausted => _exhausted;

  Future<List<SpaceflightArticle>> refresh({String? search, String? newsSite}) async {
    _cache.clear();
    _offset = 0;
    _exhausted = false;
    return loadMore(search: search, newsSite: newsSite, reset: true);
  }

  Future<List<SpaceflightArticle>> loadMore({String? search, String? newsSite, bool reset = false}) async {
    if (_exhausted && !reset) return articles;

    final items = await _api.fetchArticles(limit: pageSize, offset: _offset, search: search, newsSite: newsSite);
    if (items.isEmpty) {
      _exhausted = true;
      return articles;
    }
    _cache.addAll(items);
    _offset += items.length;
    if (items.length < pageSize) _exhausted = true;
    return articles;
  }
}
