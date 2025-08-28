import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neows_app/widget/app_bottom_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import 'package:neows_app/controllers/news_controller.dart';
import 'package:neows_app/model/spaceflight_article.dart';
import 'package:neows_app/service/news_repository.dart';

class NewsPage extends StatefulWidget {
  final NewsRepository repo;
  const NewsPage({super.key, required this.repo});

  @override
  State<NewsPage> createState() => NewsPageState();
}

class NewsPageState extends State<NewsPage> {
  late final NewsController ctrl = NewsController(widget.repo);

  final _sc = ScrollController();
  final _searchCtrl = TextEditingController();

  // Filters state
  int _days = 0; // 0=All, 1=Today, 7=7d, 30=30d
  final List<String> _topics = const ['All', 'Asteroid', 'NEO', 'Comet', 'Planetary defense'];
  int _topicIndex = 0;
  final List<String> _sources = const [
    'All sources', 'NASA', 'ESA', 'SpaceNews', 'Space.com', 'Ars Technica', 'Teslarati', 'Phys.org'
  ];
  int _sourceIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.init());
    _searchCtrl.addListener(() => setState(() {})); // update clear icon visibility
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (!_sc.hasClients) return;
    _sc.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  DateTime? _sinceFromDays(int days) => days <= 0 ? null : DateTime.now().toUtc().subtract(Duration(days: days));

  Future<void> _applyAll({String? newSearch}) async {
    await ctrl.refresh(
      newSearch: (newSearch ?? _currentQuery()).isEmpty ? null : (newSearch ?? _currentQuery()),
      newSince: _sinceFromDays(_days),
      newNewsSite: _sourceIndex == 0 ? null : _sources[_sourceIndex],
    );
    scrollToTop();
  }

  String _currentQuery() {
    // Combine topic + typed search (simple AND). Keep it simple: typed search overrides topic when non-empty.
    final typed = _searchCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return _topicIndex == 0 ? '' : _topics[_topicIndex];
  }

  Future<void> _openFiltersSheet() async {
    final result = await showModalBottomSheet<_FiltersResult>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        int tmpDays = _days;
        int tmpTopic = _topicIndex;
        int tmpSource = _sourceIndex;

        return StatefulBuilder(
          builder: (context, setSheet) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),

                    Text('Time', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: const [(0,'All'),(1,'Today'),(7,'7 days'),(30,'30 days')]
                          .map((c) => ChoiceChip(
                        label: Text(c.$2),
                        selected: tmpDays == c.$1,
                        onSelected: (_) => setSheet(() => tmpDays = c.$1),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    Text('Topic', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: List.generate(_topics.length, (i) => ChoiceChip(
                        label: Text(_topics[i]),
                        selected: tmpTopic == i,
                        onSelected: (_) => setSheet(() => tmpTopic = i),
                      )),
                    ),
                    const SizedBox(height: 16),

                    Text('Source', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: List.generate(_sources.length, (i) => ChoiceChip(
                        label: Text(_sources[i]),
                        selected: tmpSource == i,
                        onSelected: (_) => setSheet(() => tmpSource = i),
                      )),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Apply'),
                            onPressed: () => Navigator.pop(
                              context,
                              _FiltersResult(days: tmpDays, topicIndex: tmpTopic, sourceIndex: tmpSource),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _days = result.days;
        _topicIndex = result.topicIndex;
        _sourceIndex = result.sourceIndex;
      });
      await _applyAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // optional tiny title up top — or remove appBar entirely
      appBar: AppBar(title: const Text('Spaceflight News')),

      bottomNavigationBar: AppBottomBar(
        searchController: _searchCtrl,
        onSearchSubmitted: (q) => _applyAll(newSearch: q.trim()),
        onClearSearch: () {
          _searchCtrl.clear();
          _applyAll(newSearch: '');
        },
        onOpenFilters: _openFiltersSheet,
        onRefresh: () => _applyAll(),
      ),

      body: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          if (ctrl.loading && ctrl.items.isEmpty) {
            return ListView.builder(
              controller: _sc,
              itemCount: 6,
              itemBuilder: (_, __) => const _SkeletonTile(),
            );
          }
          if (ctrl.items.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: _applyAll,
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
              onRefresh: _applyAll,
              child: ListView.separated(
                controller: _sc,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: ctrl.items.length + (ctrl.exhausted ? 0 : 1),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= ctrl.items.length) {
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

// ---------- Bottom-sheet result type ----------
class _FiltersResult {
  final int days;
  final int topicIndex;
  final int sourceIndex;
  const _FiltersResult({required this.days, required this.topicIndex, required this.sourceIndex});
}

// ---------- Tile / skeleton ----------

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
        width: size, height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black12),
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        width: size, height: size, fit: BoxFit.cover, imageUrl: url,
        placeholder: (c, u) => const SizedBox(
          width: size, height: size,
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        errorWidget: (c, u, e) => const SizedBox(
          width: size, height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.black12),
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(width: 72, height: 72, color: Colors.black12),
      title: Container(height: 14, color: Colors.black12, margin: const EdgeInsets.only(right: 50, bottom: 8)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 12, color: Colors.black12, margin: const EdgeInsets.only(bottom: 6)),
          Container(height: 12, width: 120, color: Colors.black12),
        ],
      ),
    );
  }
}
