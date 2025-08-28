// lib/model/spaceflight_article.dart
import 'dart:convert';

class SpaceflightArticle {
  final int id;
  final String title;
  final String url;
  final String imageUrl;
  final String newsSite;
  final DateTime publishedAt;
  final String summary;

  const SpaceflightArticle({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.publishedAt,
    required this.summary,
  });

  factory SpaceflightArticle.fromJson(Map<String, dynamic> json) {
    return SpaceflightArticle(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      newsSite: (json['news_site'] ?? '').toString(),
      publishedAt: DateTime.tryParse((json['published_at'] ?? '').toString())
          ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      summary: (json['summary'] ?? '').toString(),
    );
  }

  static List<SpaceflightArticle> listFromResponse(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final results = (map['results'] as List<dynamic>? ?? const []);
    return results
        .map((e) => SpaceflightArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
