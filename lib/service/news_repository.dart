import 'package:neows_app/model/spaceflight_article.dart';
import 'package:neows_app/service/spaceflight_news_service.dart';

class NewsRepository {
  final SpaceflightNewsService _api;
  final List<SpaceflightArticle> _cache = [];
  int _offset = 0;
  final int pageSize;
  bool _exhausted = false;

  String? _search;
  DateTime? _since;
  String? _newsSite;

  NewsRepository(this._api, {this.pageSize = 20});

  List<SpaceflightArticle> get articles => List.unmodifiable(_cache);
  bool get exhausted => _exhausted;

  String? get search => _search;
  DateTime? get since => _since;
  String? get newsSite => _newsSite;

  Future<List<SpaceflightArticle>> refresh({
    String? search,
    DateTime? since,
    String? newsSite,
  }) async {
    _cache.clear();
    _offset = 0;
    _exhausted = false;
    _search = search;
    _since = since;
    _newsSite = newsSite;
    return loadMore(reset: true);
  }

  Future<List<SpaceflightArticle>> loadMore({bool reset = false}) async {
    if (_exhausted && !reset) return articles;

    final items = await _api.fetchArticles(
      limit: pageSize,
      offset: _offset,
      search: _search,
      newsSite: _newsSite,
      publishedAfter: _since,
    );

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
