import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum SourceTab { spaceRef, jpl, mpc }

class SpaceRefWebSheet extends StatefulWidget {
  const SpaceRefWebSheet({
    super.key,
    required this.title,
    required this.initialSource,         // which tab to show first
    this.spaceRefUrl,
    this.jplUrl,
    this.mpcUrl,
    this.siteSearchFallbackQuery,        // used if SpaceRef 404s
  });

  final String title;
  final SourceTab initialSource;
  final Uri? spaceRefUrl;
  final Uri? jplUrl;
  final Uri? mpcUrl;
  final String? siteSearchFallbackQuery;

  @override
  State<SpaceRefWebSheet> createState() => _SpaceRefWebSheetState();
}

class _SpaceRefWebSheetState extends State<SpaceRefWebSheet> {
  late final WebViewController _ctrl;
  double _progress = 0;
  late SourceTab _active;

  Set<SourceTab> get _selection => {_active};

  static const _allowedHosts = <String>{
    'spacereference.org',
    'www.spacereference.org',
    'ssd.jpl.nasa.gov',
    'www.ssd.jpl.nasa.gov',
    'minorplanetcenter.net',
    'www.minorplanetcenter.net',
  };

  @override
  void initState() {
    super.initState();
    _active = widget.initialSource;


    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (err) async {
            // SSL errors included here on Android
            final isSsl = err.errorType.toString().contains(
                'ssl'); // WebResourceErrorType.sslError
            if (isSsl) {
              await _ctrl.loadHtmlString('''
            <html lang="en"><body style="background:#0e0e0e;color:#eee;font:14px system-ui; padding:16px">
              <h3 style="margin:0 0 8px">Secure connection failed</h3>
              <p>The website’s certificate isn’t trusted by this device’s WebView.</p>
              <ul>
                <li>Update Chrome / Android System WebView</li>
                <li>Check device date/time</li>
                <li>Try without VPN/proxy</li>
              </ul>
              <p><button onclick="window.location.href='${Uri.encodeComponent(
                  toString())}'">Open in external browser</button></p>
            </body></html>
          ''');
            }
          },
          onNavigationRequest: (r) {
            final uri = Uri.parse(r.url);
            // Allow in-app for non-http(s) (about:, data:, blob:, file:)
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              return NavigationDecision.navigate;
            }
            final host = uri.host.toLowerCase();
            if (_allowedHosts.contains(host)) {
              return NavigationDecision.navigate;
            }
            // Anything else goes to external browser
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );

    // Load initial tab
    _loadTab(_active);
  }

  void _loadTab(SourceTab tab) {
    _active = tab;
    Uri? target;
    switch (tab) {
      case SourceTab.spaceRef:
        target = widget.spaceRefUrl;
        break;
      case SourceTab.jpl:
        target = widget.jplUrl;
        break;
      case SourceTab.mpc:
        target = widget.mpcUrl;
        break;
    }
    if (target != null) {
      _ctrl.loadRequest(target);
      setState(() {}); // to refresh active button highlighting
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery
        .of(context)
        .size
        .height * 0.92;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          const SizedBox(height: 8),
          // grab handle
          Container(width: 44, height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          // Title centered on its own row (optional)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Center(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // WebView expands to fill space above the bottom bar
          Expanded(child: WebViewWidget(controller: _ctrl)),

          if (_progress < 1.0)
            const LinearProgressIndicator(minHeight: 2),

          // ---- Sticky bottom controls ----
          SafeArea(
            top: false,
            child: Material(
              // distinct bar color; adjust or remove elevation as you like
              color: Theme
                  .of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.6),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 18),
                    const SizedBox(width: 6),

                    // Segmented control (compact + horizontally scrollable if tight)
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            segmentedButtonTheme: SegmentedButtonThemeData(
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                    horizontal: -3, vertical: -3),
                                padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                                minimumSize: const WidgetStatePropertyAll(
                                    Size(0, 28)),
                                textStyle: const WidgetStatePropertyAll(
                                    TextStyle(fontSize: 12)),
                                side: const WidgetStatePropertyAll(
                                  BorderSide(color: Colors.white24, width: 1),
                                ),
                              ),
                            ),
                          ),
                          child: SegmentedButton<SourceTab>(
                            segments: [
                              if (widget.spaceRefUrl != null)
                                const ButtonSegment(
                                  value: SourceTab.spaceRef,
                                  label: Text('SpaceRef'),
                                  icon: Icon(Icons.auto_stories_outlined, size: 16),
                                ),
                              if (widget.jplUrl != null)
                                const ButtonSegment(
                                  value: SourceTab.jpl,
                                  label: Text('JPL'),
                                  icon: Icon(Icons.science_outlined, size: 16),
                                ),
                              if (widget.mpcUrl != null)
                                const ButtonSegment(
                                  value: SourceTab.mpc,
                                  label: Text('MPC'),
                                  icon: Icon(Icons.public, size: 16),
                                ),
                            ],
                            selected: _selection, // {_active}
                            onSelectionChanged: (sel) {
                              if (sel.isNotEmpty) _loadTab(sel.first);
                            },
                            showSelectedIcon: false,
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      tooltip: 'Open in browser',
                      onPressed: () async {
                        final curr = await _ctrl.currentUrl();
                        if (curr != null) {
                          launchUrl(Uri.parse(curr), mode: LaunchMode
                              .externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


