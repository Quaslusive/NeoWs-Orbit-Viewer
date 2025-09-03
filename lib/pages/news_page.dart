import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neows_app/widget/app_bottom_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import 'package:neows_app/controllers/news_controller.dart';
import 'package:neows_app/model/spaceflight_article.dart';
import 'package:neows_app/service/news_repository.dart';
import 'package:neows_app/service/filter_prefs.dart';

import 'package:neows_app/controllers/bookmarks_controller.dart';
import 'package:neows_app/service/bookmarks_service.dart';
import 'package:neows_app/pages/reader_screen.dart';

import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class NewsPage extends StatefulWidget {
  final NewsRepository repo;

  const NewsPage({super.key, required this.repo});

  @override
  NewsPageState createState() => NewsPageState();
}

class NewsPageState extends State<NewsPage> {
  late final NewsController ctrl = NewsController(widget.repo);
  final prefs = FilterPrefs();

  // UI state
  final _sc = ScrollController();
  bool _showFab = false;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  // Bookmarks
  late final BookmarksController bookmarks =
      BookmarksController(BookmarksService());

  // Filters
  int _days = 0;
  final List<String> _topics = const [
    'All',
    'Asteroid',
    'NEO',
    'Comet',
    'Planetary defense'
  ];
  int _topicIndex = 0;
  final List<String> _sources = const [
    'All sources',
    'NASA',
    'ESA',
    'SpaceNews',
    'Space.com',
    'Ars Technica',
    'Teslarati',
    'Phys.org'
  ];
  int _sourceIndex = 0;

  // Preferences
  NewsViewMode _view = NewsViewMode.list;
  NewsDensity _density = NewsDensity.comfortable;
  NewsSort _sort = NewsSort.newest;
  bool _openInApp = false;
  bool _lowData = false;

  DateTime? _lastOpenedAt;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      final show = _sc.offset > 600;
      if (show != _showFab) setState(() => _showFab = show);
    });
    _searchCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load prefs
      final loaded = await prefs.loadFilters();
      setState(() {
        _days = loaded.days;
        _topicIndex = loaded.topic;
        _sourceIndex = loaded.source;
        _searchCtrl.text = loaded.query;
      });
      _view = await prefs.loadViewMode();
      _density = await prefs.loadDensity();
      _sort = await prefs.loadSort();
      _openInApp = await prefs.loadOpenInApp();
      _lowData = await prefs.loadLowData();
      _lastOpenedAt = await prefs.loadLastOpenedAt();

      await bookmarks.init();
      await _applyAll(savePrefs: false); // first load using saved prefs
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Helpers
  void scrollToTop() {
    if (!_sc.hasClients) return;
    _sc.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  DateTime? _sinceFromDays(int days) =>
      days <= 0 ? null : DateTime.now().toUtc().subtract(Duration(days: days));

  String _currentQuery() {
    final typed = _searchCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return _topicIndex == 0 ? '' : _topics[_topicIndex];
  }

  Future<void> _applyAll({bool savePrefs = true, String? newSearch}) async {
    HapticFeedback.lightImpact();
    await ctrl.refresh(
      newSearch: (newSearch ?? _currentQuery()).isEmpty
          ? null
          : (newSearch ?? _currentQuery()),
      newSince: _sinceFromDays(_days),
      newNewsSite: _sourceIndex == 0 ? null : _sources[_sourceIndex],
    );
    if (savePrefs) {
      await prefs.saveFilters(
          days: _days,
          topic: _topicIndex,
          source: _sourceIndex,
          query: _searchCtrl.text.trim());
    }
    scrollToTop();
  }

  // Sorting
  List<SpaceflightArticle> _sorted(List<SpaceflightArticle> xs) {
    final list = [...xs];
    switch (_sort) {
      case NewsSort.newest:
        list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case NewsSort.oldest:
        list.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
        break;
      case NewsSort.sourceAZ:
        list.sort((a, b) => a.newsSite.compareTo(b.newsSite));
        break;
    }
    return list;
  }

  // New since divider index
  int? _firstNewIndex(List<SpaceflightArticle> items) {
    final since = _lastOpenedAt;
    if (since == null) return null;
    for (int i = 0; i < items.length; i++) {
      if (items[i].publishedAt.isAfter(since)) return i;
    }
    return null;
  }

  Future<void> _openFiltersSheet() async {
    final result = await showCupertinoModalBottomSheet<_FiltersResult>(
      context: context,
      expand: false, // vi använder egen scroll i innehållet
      duration: const Duration(milliseconds: 420), // mjukare, lite längre
      enableDrag: true,
      backgroundColor: Colors.transparent,        // för rundade hörn + skugga
      builder: (context) {
        int tmpDays = _days;
        int tmpTopic = _topicIndex;
        int tmpSource = _sourceIndex;

        void _clearAll(StateSetter setSheet) {
          setSheet(() {
            tmpDays = 0;
            tmpTopic = 0;
            tmpSource = 0;
          });
        }

        return SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.66, // lite högre direkt
                minChildSize: 0.2,
                maxChildSize: 0.8,
                builder: (ctx, scrollController) {
                  return StatefulBuilder(
                    builder: (ctx, setSheet) => Padding(
                      padding: EdgeInsets.fromLTRB(
                        16, 8, 16,
                        16 + MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      child: ListView(
                        controller: ModalScrollController.of(context), // integrerad drag/scroll
                        children: [
                          // Header + Clear all
                          Row(
                            children: [
                              Expanded(
                                child: Text('Filters',
                                    style: Theme.of(ctx).textTheme.titleLarge),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Clear all'),
                                onPressed: () => _clearAll(setSheet),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text('Time', style: Theme.of(ctx).textTheme.labelLarge),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              for (final c in const [
                                (0, 'All'), (1, 'Today'), (7, '7 days'), (30, '30 days')
                              ])
                                ChoiceChip(
                                  label: Text(c.$2),
                                  selected: tmpDays == c.$1,
                                  onSelected: (_) => setSheet(() => tmpDays = c.$1),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Text('Topic', style: Theme.of(ctx).textTheme.labelLarge),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: List.generate(_topics.length, (i) => ChoiceChip(
                              label: Text(_topics[i]),
                              selected: tmpTopic == i,
                              onSelected: (_) => setSheet(() => tmpTopic = i),
                            )),
                          ),

                          const SizedBox(height: 16),
                          Text('Source', style: Theme.of(ctx).textTheme.labelLarge),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8, runSpacing: 8,
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
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.restart_alt),
                                  label: const Text('Clear All'),
                                  onPressed: () {
                                    Navigator.pop(context, const _FiltersResult(days: 0, topicIndex: 0, sourceIndex: 0));                                  }
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.check),
                                  label: const Text('Apply'),
                                  onPressed: () => Navigator.pop(
                                    context,
                                    _FiltersResult(
                                      days: tmpDays,
                                      topicIndex: tmpTopic,
                                      sourceIndex: tmpSource,
                                    ),
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
              ),
            ),
          ),
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

  void _onOpenArticle(SpaceflightArticle a) async {
    final uri = Uri.parse(a.url);
    if (_openInApp) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ReaderScreen(url: uri)));
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final merged = Listenable.merge([ctrl, bookmarks]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaceflight News'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Options',
            onSelected: (v) async {
              switch (v) {
                case 1: // view
                  setState(() => _view = (_view == NewsViewMode.list)
                      ? NewsViewMode.grid
                      : NewsViewMode.list);
                  await prefs.saveViewMode(_view);
                  break;
                case 2: // density
                  setState(() => _density =
                      (_density == NewsDensity.comfortable)
                          ? NewsDensity.compact
                          : NewsDensity.comfortable);
                  await prefs.saveDensity(_density);
                  break;
                case 3: // sort
                  final ns = await showMenu<NewsSort>(
                    context: context,
                    position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                    items: const [
                      PopupMenuItem(
                          value: NewsSort.newest, child: Text('Newest')),
                      PopupMenuItem(
                          value: NewsSort.oldest, child: Text('Oldest')),
                      PopupMenuItem(
                          value: NewsSort.sourceAZ, child: Text('Source A–Z')),
                    ],
                  );
                  if (ns != null) {
                    setState(() => _sort = ns);
                    await prefs.saveSort(_sort);
                  }
                  break;
                case 4: // open in
                  setState(() => _openInApp = !_openInApp);
                  await prefs.saveOpenInApp(_openInApp);
                  break;
                case 5: // low data
                  setState(() => _lowData = !_lowData);
                  await prefs.saveLowData(_lowData);
                  break;
              }
            },
            itemBuilder: (c) => [
              PopupMenuItem(
                  value: 1,
                  child: Text('View: ${_view == NewsViewMode.list ? 'List' : 'Grid'}')),
              PopupMenuItem(
                  value: 2,
                  child: Text('Density: ${_density == NewsDensity.comfortable
                          ? 'Comfortable'
                          : 'Compact'}')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 3, child: Text('Sort…')),
              PopupMenuItem(
                  value: 4,
                  child: Text('Open in ${_openInApp ? 'App' : 'Browser'}')),
              PopupMenuItem(
                  value: 5,
                  child: Text('Low data: ${_lowData ? 'On' : 'Off'}')),
            ],
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton.extended(
              onPressed: scrollToTop,
              icon: const Icon(Icons.keyboard_arrow_up),
              label: const Text('Top'),
            )
          : null,
      bottomNavigationBar: AppBottomBar(
        searchController: _searchCtrl,
        searchFocusNode: _searchFocus,
        onSearchSubmitted: (q) => _applyAll(newSearch: q.trim()),
        onClearSearch: () {
          _searchCtrl.clear();
          _applyAll(newSearch: '');
        },
        onOpenFilters: _openFiltersSheet,
        onRefresh: () => _applyAll(),
      ),
      body: AnimatedBuilder(
        animation: merged,
        builder: (context, _) {
          if (ctrl.loading && ctrl.items.isEmpty) {
            return ListView.builder(
              controller: _sc,
              itemCount: 6,
              itemBuilder: (_, __) => const _SkeletonTile(),
            );
          }

          var items = _sorted(ctrl.items);

          // New-since divider index
          final firstNew = _firstNewIndex(items);

          if (items.isEmpty) {
            return Center(
              child: TextButton.icon(
                onPressed: _applyAll,
                icon: const Icon(Icons.refresh),
                label: const Text('No articles. Tap to retry'),
              ),
            );
          }

          // LIST or GRID
          if (_view == NewsViewMode.list) {
            // LIST
            return RefreshIndicator(
              onRefresh: _applyAll,
              child: ExcludeSemantics(
                // keep this to avoid any remaining semantics churn
                child: ListView.separated(
                  controller: _sc,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length + (ctrl.exhausted ? 0 : 1),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // loader row
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final article = items[index];
                    final isBm = bookmarks.isBookmarked(article.id);

                    final tile = _ArticleTileSimple(
                      key: ValueKey('article_${article.id}'),
                      // now accepted
                      article: article,
                      density: _density,
                      lowData: _lowData,
                      isBookmarked: isBm,
                      onToggleBookmark: () {
                        final prev = bookmarks.snapshot();
                        bookmarks.toggle(article.id);
                        final nowBm = bookmarks.isBookmarked(article.id);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(nowBm ? 'Bookmarked' : 'Removed'),
                              action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () => bookmarks.restore(prev)),
                            ),
                          );
                      },
                      onOpen: () => _onOpenArticle(article),
                    );

                    // Insert "New since last visit" header + the tile
                    if (firstNew != null && index == firstNew) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.fiber_new, size: 18),
                                SizedBox(width: 6),
                                Text('New since last visit')
                              ],
                            ),
                          ),
                          tile,
                        ],
                      );
                    }
                    return tile;
                  },
                ),
              ),
            );
          } else {
            // GRID view
            // GRID
            return RefreshIndicator(
              onRefresh: _applyAll,
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final w = cons.maxWidth;
                    final cross = w > 900
                        ? 4
                        : w > 600
                            ? 3
                            : 2;
                    final pad = _density == NewsDensity.compact ? 6.0 : 10.0;
                    final childAspect =
                        _density == NewsDensity.compact ? 0.85 : 0.75;

                    return GridView.builder(
                      controller: _sc,
                      padding: EdgeInsets.all(pad),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: pad,
                        crossAxisSpacing: pad,
                        childAspectRatio: childAspect,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final a = items[i];
                        return _CardTile(
                          key: ValueKey('card_${a.id}'),
                          // now accepted
                          article: a,
                          lowData: _lowData,
                          density: _density,
                          isBookmarked: bookmarks.isBookmarked(a.id),
                          onBookmarkToggle: () {
                            final prev = bookmarks.snapshot();
                            bookmarks.toggle(a.id);
                            final nowBm = bookmarks.isBookmarked(a.id);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content:
                                      Text(nowBm ? 'Bookmarked' : 'Removed'),
                                  action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () => bookmarks.restore(prev)),
                                ),
                              );
                          },
                          onOpen: () => _onOpenArticle(a),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void deactivate() {
    // Save last opened time when leaving page
    prefs.saveLastOpenedAt(DateTime.now());
    super.deactivate();
  }
}

class _FiltersResult {
  final int days;
  final int topicIndex;
  final int sourceIndex;

  const _FiltersResult(
      {required this.days,
      required this.topicIndex,
      required this.sourceIndex});
}

class _ArticleTileSimple extends StatelessWidget {
  final SpaceflightArticle article;
  final NewsDensity density;
  final bool lowData;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpen;

  const _ArticleTileSimple({
    super.key,
    required this.article,
    required this.density,
    required this.lowData,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final padding = density == NewsDensity.compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return ListTile(
      contentPadding: padding,
      leading: _Thumb(
        url: article.imageUrl,
        lowData: lowData,
        size: density == NewsDensity.compact ? 60 : 72,
      ),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            article.summary,
            maxLines: density == NewsDensity.compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${article.newsSite} • ${timeago.format(article.publishedAt, allowFromNow: true)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
        tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
        onPressed: onToggleBookmark,
      ),
      onTap: onOpen,
    );
  }
}

class _CardTile extends StatelessWidget {
  final SpaceflightArticle article;
  final bool lowData;
  final NewsDensity density;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onOpen;

  const _CardTile({
    super.key,
    required this.article,
    required this.lowData,
    required this.density,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final pad = density == NewsDensity.compact ? 8.0 : 12.0;
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final subtitleStyle = Theme.of(context).textTheme.bodySmall;

    return InkWell(
      onTap: onOpen,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _Thumb(url: article.imageUrl, lowData: lowData, size: 200),
            ),
            Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle),
                  const SizedBox(height: 6),
                  Text(
                    article.summary,
                    maxLines: density == NewsDensity.compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${article.newsSite} • ${timeago.format(article.publishedAt, allowFromNow: true)}',
                          style: subtitleStyle,
                        ),
                      ),
                      IconButton(
                        icon: Icon(isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border),
                        onPressed: onBookmarkToggle,
                        tooltip:
                            isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  final bool lowData;
  final double? size; // <-- optional now
  const _Thumb({required this.url, required this.lowData, this.size});

  @override
  Widget build(BuildContext context) {
    final image = url.isEmpty
        ? const DecoratedBox(
            decoration: BoxDecoration(color: Colors.black12),
            child: Center(child: Icon(Icons.image_not_supported_outlined)),
          )
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            // keep this modest; don't over-optimize
            memCacheWidth: lowData ? 300 : null,
            placeholder: (c, u) => const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (c, u, e) => const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black12),
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );

    // If size provided -> fixed box (ListTile leading). Else, expand (Grid/AspectRatio).
    return (size != null)
        ? SizedBox(width: size, height: size, child: clipped)
        : clipped;
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(width: 72, height: 72, color: Colors.black12),
      title: Container(
          height: 14,
          color: Colors.black12,
          margin: const EdgeInsets.only(right: 50, bottom: 8)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 12,
              color: Colors.black12,
              margin: const EdgeInsets.only(bottom: 6)),
          Container(height: 12, width: 120, color: Colors.black12),
        ],
      ),
    );
  }
}
