import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:neows_app/space_reference_web/space_ref_web_controller.dart';
import 'package:neows_app/neows/asteroid_model.dart';
import 'package:neows_app/space_reference_web/space_ref.dart';
import 'package:neows_app/widget/orbit_diagram2d.dart';

class SpaceRefSheet extends StatefulWidget {
  const SpaceRefSheet({
    super.key,
    required this.asteroidName,
    required this.asteroid,
    this.orbitA,
    this.orbitE,
  });

  final String asteroidName;
  final Asteroid asteroid;
  final double? orbitA;
  final double? orbitE;

  @override
  State<SpaceRefSheet> createState() => _SpaceRefSheetState();
}

class _SpaceRefSheetState extends State<SpaceRefSheet> {
  late final Uri _spaceRefUri;
  late final WebViewController _ctrl;

  double _progress = 0.0;
  int _lastPct = 0;
  bool _fallback = false;

  @override
  void initState() {
    super.initState();
    _spaceRefUri = spaceRefAsteroidUrl(name: widget.asteroidName);
    if (kIsWeb) {
      launchUrl(_spaceRefUri, mode: LaunchMode.externalApplication);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    _ctrl = SpaceRefWebController.instance.controller()
      ..addJavaScriptChannel('SR', onMessageReceived: (m) {
        if (m.message == 'SR_404' || m.message == 'SR_NOT_FOUND') {
          _showFallback();
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            // throttle UI updates to ~10% steps
            if (p - _lastPct >= 10) {
              _lastPct = p;
              if (mounted) setState(() => _progress = p / 100.0);
            }
          },
          onHttpError: (err) {
            if ((err.response?.statusCode ?? 0) >= 400) _showFallback();
          },
          onWebResourceError: (_) => _showFallback(),
          onPageFinished: (_) async {
            const js = r"""
              (function() {
                try {
                  const t = (document.title||'').toLowerCase();
                  const b = (document.body && document.body.innerText || '').toLowerCase();
                  const hits = ['not found','no results','doesn\'t exist','404','sorry'];
                  const found = hits.some(h => t.includes(h) || b.includes(h));
                  if (found) SR.postMessage('SR_404');
                  return 'ok';
                } catch (e) { return 'err'; }
              })();
            """;
            try {
              await _ctrl.runJavaScriptReturningResult(js);
            } catch (_) {}
          },
        ),
      )
      ..loadRequest(_spaceRefUri);
  }

  void _showFallback() {
    if (!mounted) return;
    setState(() => _fallback = true);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.92;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          const SizedBox(height: 8),
          // grab handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Center(
              child: Text(
                widget.asteroidName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          Expanded(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  if (!_fallback)
                    Positioned.fill(
                      child: WebViewWidget(
                        key: const ValueKey('webview'),
                        controller: _ctrl,
                      ),
                    ),
                  if (_fallback)
                    Positioned.fill(
                      child: _FallbackAsteroidView(
                        key: const ValueKey('fallback'),
                        asteroid: widget.asteroid,
                        orbitA: widget.orbitA,
                        orbitE: widget.orbitE,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (!_fallback && _progress < 1 && !kIsWeb)
            const LinearProgressIndicator(minHeight: 2),

          SafeArea(
            top: false,
            child: Material(
              color: cs.surface,
              elevation: 0,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_stories_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(_fallback ? 'Page does not exist' : 'SpaceReference'),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Open in browser',
                    onPressed: () => launchUrl(_spaceRefUri,
                        mode: LaunchMode.externalApplication),
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
        ],
      ),
    );
  }
}

@override
class _FallbackAsteroidView extends StatelessWidget {
  const _FallbackAsteroidView({
    super.key,
    required this.asteroid,
    this.orbitA,
    this.orbitE,
  });

  final Asteroid asteroid;
  final double? orbitA;
  final double? orbitE;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final double a = (orbitA ?? asteroid.aAu) ?? 0.0;
    final double e = (orbitE ?? asteroid.e) ?? 0.0;
    debugPrint('SpaceRef fallback for ${asteroid.id}: a=${asteroid.aAu}, e=${asteroid.e}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Center(
            child: OrbitDiagram2D(
              a: a,
              e: e,
              size: 160,
              strokeWidth: 2.5,
              backgroundColor: cs.surfaceContainerHighest,
              placeholderAsset:
                  'lib/assets/images/PNG_orbit_placeholder_White.png',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: _KeyFactsList(asteroid: asteroid),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyFactsList extends StatelessWidget {
  const _KeyFactsList({
    required this.asteroid});

  final Asteroid asteroid;

  @override
  Widget build(BuildContext context) {
    String numStr(num? v, {int frac = 3}) =>
        v == null ? '—' : (v is int ? '$v' : v.toStringAsFixed(frac));


    final rows = <MapEntry<String, String>>[
      MapEntry('ID', asteroid.id),
      if ((asteroid.name ?? '').isNotEmpty) MapEntry('Name', asteroid.name!),
      if (asteroid.H != null) MapEntry('H (mag)', numStr(asteroid.H, frac: 2)),
      if (asteroid.diameterKm != null)
        MapEntry('Est. diameter (km)', numStr(asteroid.diameterKm, frac: 3)),
      MapEntry(
          'Potentially Hazardous', (asteroid.isPha == true) ? 'Yes' : 'No'),
      if (asteroid.aAu != null)
        MapEntry('a (AU)', numStr(asteroid.aAu, frac: 4)),
      if (asteroid.e != null) MapEntry('e', numStr(asteroid.e, frac: 4)),
      if (asteroid.iDeg != null)
        MapEntry('i (°)', numStr(asteroid.iDeg, frac: 3)),
      if (asteroid.moidAu != null)
        MapEntry('MOID (AU)', numStr(asteroid.moidAu, frac: 4)),
    ];

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (c, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 170,
              child: Text(
                rows[i].key,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Text(
                rows[i].value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
