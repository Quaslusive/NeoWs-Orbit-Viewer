import 'package:flutter/material.dart';
import 'package:neows_app/model/asteroid_csv.dart';
// ✅ MPC service + DTO
import 'package:neows_app/service/asterank_api_service.dart';
import 'package:neows_app/widget/orbitDiagram2D.dart';

class AsteroidDetailsPage extends StatefulWidget {
  final Asteroid asteroid;
  const AsteroidDetailsPage({super.key, required this.asteroid});

  @override
  State<AsteroidDetailsPage> createState() => _AsteroidDetailsPageState();
}

class _AsteroidDetailsPageState extends State<AsteroidDetailsPage> {
  final AsterankApiService _asterank = AsterankApiService(enableLogs: true);

  bool _loading = false;
  AsterankObject? _asterankObj; // ✅ store fetched MPC data here
  double? _bestA() => _asterankObj?.a ?? widget.asteroid.a;
  double? _bestE() => _asterankObj?.e ?? widget.asteroid.e;
  double? _bestI() => _asterankObj?.i; // CSV model didn’t have i; only MPC may provide it
/// Handy derived values for the UI if your widget wants them
  double? _perihelionQ() {
    final a = _bestA(),
        e = _bestE();
    if (a == null || e == null) return null;
    return a * (1 - e);
  }

  double? _aphelionQ() {
    final a = _bestA(),
        e = _bestE();
    if (a == null || e == null) return null;
    return a * (1 + e);
  }

  @override
  void initState() {
    super.initState();
    _fetchMpc();
  }

  Future<void> _fetchMpc() async {
    setState(() => _loading = true);
    try {
      // Use the most reliable key you have
      final key = widget.asteroid.fullName
          .trim()
          .isNotEmpty
          ? widget.asteroid.fullName.trim()
          : widget.asteroid.name.trim();

      final row = await _asterank.fetchByFullName(key)
          ?? await _asterank.search(key, limit: 1).then((l) => l.isNotEmpty ? l.first : null);
      if (!mounted) return;
      setState(() => _asterankObj = row);
    } catch (e) {
      debugPrint('MPC details fetch error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asteroid;
    final bestA = _bestA();
    final bestE = _bestE();
    final bestI = _bestI(); // may be null

    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ORBIT DIAGRAM
          if (bestA != null && bestE != null)
            SizedBox(
              height: 200,
              child: OrbitDiagram2D( // <-- replace with your widget name
                a: bestA,
                e: bestE,
              ),
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text('No orbit data available'),
            ),

          const SizedBox(height: 16),

          // --- TEXT DETAILS ---
          Text(a.fullName, style: Theme
              .of(context)
              .textTheme
              .headlineSmall),
          const SizedBox(height: 8),
          Text('a (AU): ${bestA?.toStringAsFixed(6) ?? "-"}'),
          Text('e: ${bestE?.toStringAsFixed(6) ?? "-"}'),
          if (bestI != null) Text('i (°): ${bestI!.toStringAsFixed(4)}'),
          if (_perihelionQ() != null) Text(
              'q (AU): ${_perihelionQ()!.toStringAsFixed(6)}'),
          if (_aphelionQ() != null) Text(
              'Q (AU): ${_aphelionQ()!.toStringAsFixed(6)}'),

          // … your MPC/CSV fields section below (as you already had) …
        ],
      ),
    );
  }
}



