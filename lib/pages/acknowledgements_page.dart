import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AcknowledgementsPage extends StatelessWidget {
  const AcknowledgementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_AckItem>[
      const _AckItem(
        title: 'NASA Near Earth Object Web Service (NeoWs)',
        url: 'https://api.nasa.gov',
        blurb:
        'REST API with daily-updated near‑Earth asteroid data. Provided by NASA JPL.',
      ),
      const _AckItem(
        title: 'Asterank',
        url: 'https://www.asterank.com',
        blurb:
        'Open asteroid database with orbital elements, physical estimates, and visuals.',
      ),
     const _AckItem(
        title: 'Spaceflight News API v4',
        url: 'Website: https://spaceflightnewsapi.net',
        blurb:
        'Free, no‑key REST API for spaceflight articles',
      ),
    ];

    return Scaffold(
      backgroundColor:Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor:Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text('Acknowledgements'),
      ),
      body: Stack(
        children: [
          const _StarField(),
          // Soft top nebula glow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      const Color(0xFF6B7CFF).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const _GlowHeader(
                title: 'Data & API Providers',
                subtitle:
                'Huge thanks to the teams making space data openly available.',
              ),
              const SizedBox(height: 12),
              for (final item in items) _AckCard(item: item),
              const SizedBox(height: 20),
              const _SectionDivider(label: 'Legal & Attribution'),
              const SizedBox(height: 12),
              const _DisclaimerText(
                text:
                'Data from NASA is provided “as is,” without warranty of any kind. '
                    'This app is an independent project and is not affiliated with NASA, JPL, or Asterank.',
              ),
              const SizedBox(height: 12),
              const _DisclaimerText(
                text:
                'If you operate one of the services credited here and prefer a different attribution, '
                    'please contact the developer.',
              ),
              const SizedBox(height: 28),
              const _DisclaimerText(
                text:
                'Use of Spaceflight News API - While this API is free to use, we do encourage developers to support us through Patreon to keep the API up and running.',
              ),
              const SizedBox(height: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _AckItem {
  final String title;
  final String url;
  final String blurb;
  const _AckItem({required this.title, required this.url, required this.blurb});
}

class _AckCard extends StatelessWidget {
  final _AckItem item;
  const _AckCard({required this.item});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback: try in-app web view
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withOpacity(0.08);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF151A2B).withOpacity(0.85),
            const Color(0xFF0F1323).withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B7CFF).withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(item.url),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                ),
                child: const Icon(Icons.public, color: Colors.white),
              ),
              const SizedBox(width: 12),
              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.blurb,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.url,
                          style: TextStyle(
                            color: Colors.blue[300],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.open_in_new,
                            size: 16, color: Colors.blue[300]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _GlowHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glow title
        Stack(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6B7CFF).withOpacity(0.20),
                    shadows: const [
                      Shadow(blurRadius: 24, color: Color(0xFF6B7CFF)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final line = Colors.white.withOpacity(0.12);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: line)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121726),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: line)),
      ],
    );
  }
}

class _DisclaimerText extends StatelessWidget {
  final String text;
  const _DisclaimerText({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.70),
        fontSize: 13.5,
        height: 1.35,
      ),
    );
  }
}

/// Subtle procedural star background
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarsPainter(
        seed: 42,
        starCount: 260,
        minSize: 0.6,
        maxSize: 1.8,
        twinkle: true,
      ),
      isComplex: true,
      willChange: false,
      child: const SizedBox.expand(),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final int seed;
  final int starCount;
  final double minSize;
  final double maxSize;
  final bool twinkle;

  _StarsPainter({
    required this.seed,
    this.starCount = 200,
    this.minSize = 0.5,
    this.maxSize = 2.0,
    this.twinkle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final paint = Paint()..color = Colors.white.withOpacity(0.6);

    // Deep gradient sky
    final rect = Offset.zero & size;
    const sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0B0E17),
        Color(0xFF0A0D16),
        Color(0xFF090C14),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = sky.createShader(rect));

    for (var i = 0; i < starCount; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = minSize + rnd.nextDouble() * (maxSize - minSize);

      double opacity = 0.35 + rnd.nextDouble() * 0.55;
      if (twinkle) {
        // slight variation by position
        final phase = (dx + dy) * 0.002;
        opacity = 0.25 + 0.55 * (0.5 + 0.5 * sin(phase));
      }

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}
