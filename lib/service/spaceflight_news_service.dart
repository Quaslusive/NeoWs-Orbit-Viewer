// lib/service/spaceflight_news_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:neows_app/model/spaceflight_article.dart';

class SpaceflightNewsService {
  static const String _base = 'https://api.spaceflightnewsapi.net/v4';

  /// Fetch a page of articles with pagination and optional filters.
  Future<List<SpaceflightArticle>> fetchArticles({
    int limit = 20,
    int offset = 0,
    String? search,
    String? newsSite,
    DateTime? publishedAfter,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final qp = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (newsSite != null && newsSite.trim().isNotEmpty) 'news_site': newsSite.trim(),
      if (publishedAfter != null) 'published_at_gt': publishedAfter.toUtc().toIso8601String(),
    };
    final uri = Uri.parse('$_base/articles/').replace(queryParameters: qp);

    try {
      final resp = await c.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        return SpaceflightArticle.listFromResponse(resp.body);
      }
      throw HttpException('SpaceflightNews error: ${resp.statusCode}');
    } finally {
      if (client == null) c.close();
    }
  }
}
