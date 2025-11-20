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
        'REST API with daily-updated near-Earth asteroid data. Provided by NASA JPL.',
      ),
      const _AckItem(
        title:
        'Space Reference — Compiled data & simulations for 1,302,506 celestial objects',
        url: 'https://www.spacereference.org/',
        blurb:
        'The purpose of this site is to catalog and showcase every known object in space. '
            'SpaceDB compiles data from the NASA/JPL Small Body Database, the IAU Minor Planet Center, and the NASA/JPL CNEOS. '
            'Try the full-screen interactive solar system view.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Credits'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _GlowHeader(
            title: 'Data & API Providers',
            subtitle: 'Huge thanks to NASA and SpaceReference for making data and information freely available.',
          ),
          const SizedBox(height: 12),
          for (final item in items) _AckCard(item: item),
          const SizedBox(height: 20),
          const _SectionDivider(label: 'Clarification'),
          const SizedBox(height: 12),
          const _DisclaimerText(
            text:
            'Data from NASA is provided “as is,” without warranty of any kind. '
                'This app is an independent project and is not affiliated with NASA, or Space Reference.',
          ),
          const SizedBox(height: 12),
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
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withValues(alpha: 0.08);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF151A2B).withValues(alpha: 0.85),
            const Color(0xFF0F1323).withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
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
                        color: Colors.white.withValues(alpha: 0.82),
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
        Stack(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6B7CFF).withValues(alpha: 0.20),
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
            color: Colors.white.withValues(alpha: 0.75),
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
    final line = Colors.white.withValues(alpha: 0.12);
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
              color: Colors.white.withValues(alpha: 0.85),
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
        color: Colors.white.withValues(alpha: 0.70),
        fontSize: 13.5,
        height: 1.35,
      ),
    );
  }
}
