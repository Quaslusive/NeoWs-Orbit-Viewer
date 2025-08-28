// lib/pages/news_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:neows_app/controllers/news_controller.dart';
import 'package:neows_app/model/spaceflight_article.dart';
import 'package:neows_app/service/news_repository.dart';

class NewsPage extends StatefulWidget {
  final NewsRepository repo;
  const NewsPage({super.key, required this.repo});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late final NewsController ctrl = NewsController(widget.repo);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.init());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaceflight News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ctrl.refresh(),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          if (ctrl.loading && ctrl.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.items.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: () => ctrl.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('No articles. Tap to retry'),
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                ctrl.loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () => ctrl.refresh(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: ctrl.items.length + (ctrl.exhausted ? 0 : 1),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= ctrl.items.length) {
                    // loader row
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final article = ctrl.items[index];
                  return _ArticleTile(article: article);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final SpaceflightArticle article;
  const _ArticleTile({required this.article});

  @override
  Widget build(BuildContext context) {
    final published = timeago.format(article.publishedAt, allowFromNow: true);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: _Thumb(url: article.imageUrl),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(article.summary, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('${article.newsSite} • $published', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      onTap: () async {
        final uri = Uri.parse(article.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    if (url.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black12),
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        width: size,
        height: size,
        fit: BoxFit.cover,
        imageUrl: url,
        placeholder: (c, u) => const SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        errorWidget: (c, u, e) => const SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.black12),
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}
