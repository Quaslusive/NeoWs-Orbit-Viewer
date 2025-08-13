import 'package:flutter/material.dart';
import 'package:neows_app/model/asteroid_csv.dart';
import 'package:neows_app/widget/orbitDiagram2D.dart';
import 'package:neows_app/service/asterank_api_service.dart';

class AsteroidDetailsPage extends StatefulWidget {
  final Asteroid asteroid;
  const AsteroidDetailsPage({super.key, required this.asteroid});

  @override
  State<AsteroidDetailsPage> createState() => _AsteroidDetailsPageState();
}

class _AsteroidDetailsPageState extends State<AsteroidDetailsPage> {
  final _asterank = AsterankApiService();
  bool _triedFetch = false;

  Asteroid get a => widget.asteroid;

  @override
  void initState() {
    super.initState();

    // Optional: fetch Asterank on open if not already present.
    // Remove this block if you ONLY want enrichment from the list page.
    if (!_hasAnyAsterank(a)) {
      _triedFetch = true;
      _fetchAsterankFor(a);
    }
  }

  Future<void> _fetchAsterankFor(Asteroid ast) async {
    final key = (ast.name?.trim().isNotEmpty == true)
        ? ast.name!.trim()
        : (ast.fullName ?? '').trim();
    if (key.isEmpty) return;

    final info = await _asterank.fetchByDesignation(key);
    if (!mounted || info == null) return;
    setState(() => ast.applyAsterank(info));
  }

  // --- Danger heuristics (clear + small) ---
  String _dangerLevel() {
    final isPha = a.pha.toUpperCase() == 'Y';
    final moidRisk = a.moid < 0.05;      // au
    final bigEnough = a.diameter >= 0.14; // km (≈140 m)
    if ((isPha || moidRisk) && bigEnough) return 'Extreme Danger 🔥';
    if (isPha || moidRisk) return 'Moderate Risk ⚠️';
    return 'Safe ✅';
  }

  Color _dangerColor() {
    final d = _dangerLevel();
    if (d.contains('Extreme')) return Colors.red[300]!;
    if (d.contains('Moderate')) return Colors.orange[300]!;
    return Colors.green[300]!;
  }

  bool _hasAnyAsterank(Asteroid a) =>
      a.asterankPriceUsd != null ||
          a.asterankAlbedo != null ||
          a.asterankDiameterKm != null ||
          a.asterankDensity != null ||
          (a.asterankSpec?.isNotEmpty == true) ||
          (a.asterankFullName?.isNotEmpty == true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(a.name ?? a.fullName ?? 'Asteroid')),
      body: Center(
        child: Hero(
          tag: a.id,
          child: Material(
            color: Colors.transparent,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              elevation: 6,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Orbit header (2D viewer stays) ----
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (a.a > 0 && a.e >= 0 && a.e < 1)
                            ? SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: OrbitDiagram2D(
                            a: a.a,
                            e: a.e,
                            stroke: Colors.white,
                            strokeWidth: 2,
                            showPlanets: true,
                          ),
                        )
                            : Image.asset(
                          'lib/assets/images/orbit_placeholder.png',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- Title row + risk badge ----
                      Text(
                        a.fullName?.isNotEmpty == true ? a.fullName! : (a.name ?? 'Asteroid'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _dangerColor(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _dangerLevel(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('ID: ${a.id}', style: const TextStyle(color: Colors.black54)),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Copy ID',
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Asteroid ID copied')),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Share',
                            icon: const Icon(Icons.ios_share),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Share coming soon')),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      // ---- Section 1: NeoWs / CSV ----
                      _sectionTitle(context, 'NeoWs / CSV'),
                      const SizedBox(height: 6),
                      _kv('Class', a.classType),
                      _kv('Diameter', '${a.diameter.toStringAsFixed(2)} km'),
                      _kv('Albedo', a.albedo.toStringAsFixed(2)),
                      if (a.rotationPeriod != null && a.rotationPeriod! > 0)
                        _kv('Rotation period', '${a.rotationPeriod!.toStringAsFixed(2)} h'),
                      _kv('MOID', '${a.moid.toStringAsFixed(6)} au'),
                      _kv('PHA', a.pha),
                      _kv('Orbit ID', '${a.orbitId}'),
                      _kv('a (semi-major axis)', a.a.toStringAsFixed(6)),
                      _kv('e (eccentricity)', a.e.toStringAsFixed(6)),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      // ---- Section 2: Asterank (enrichment) ----
                      _sectionTitle(context, 'Asterank'),
                      const SizedBox(height: 6),
                      if (_hasAnyAsterank(a)) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (a.asterankPriceUsd != null)
                              _pill(context, 'Value', _money(a.asterankPriceUsd!) ),
                            if (a.asterankAlbedo != null)
                              _pill(context, 'Albedo (pV)', a.asterankAlbedo!.toStringAsFixed(3)),
                            if (a.asterankDiameterKm != null)
                              _pill(context, 'Diameter (Asterank)', '${a.asterankDiameterKm!.toStringAsFixed(3)} km'),
                            if (a.asterankDensity != null)
                              _pill(context, 'Density', '${a.asterankDensity!.toStringAsFixed(2)} g/cm³'),
                            if (a.asterankSpec != null && a.asterankSpec!.isNotEmpty)
                              _pill(context, 'Spectral/Type', a.asterankSpec!),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _kv('Full name (Asterank)', a.asterankFullName ?? '—'),
                        const SizedBox(height: 8),
                        Text(
                          'Note: Asterank values are estimates for education/visualization.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _triedFetch
                                    ? 'No Asterank data found for this asteroid.'
                                    : 'No Asterank data loaded.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: _triedFetch ? null : () {
                            setState(() => _triedFetch = true);
                            _fetchAsterankFor(a);
                          },
                          child: const Text('Load Asterank'),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----- UI helpers -----

  Widget _sectionTitle(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
  );

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 170,
          child: Text(k, style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(v)),
      ],
    ),
  );

  Widget _pill(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Text('$label: $value', style: Theme.of(context).textTheme.labelMedium),
    );
  }

  String _money(double n) {
    if (n >= 1e12) return '\$${(n / 1e12).toStringAsFixed(1)}T';
    if (n >= 1e9)  return '\$${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6)  return '\$${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3)  return '\$${(n / 1e3).toStringAsFixed(1)}K';
    return '\$${n.toStringAsFixed(0)}';
  }
}
