import 'package:flutter/material.dart';
import 'package:neows_app/search/asteroid_filters.dart';
import 'package:neows_app/utils/num_utils.dart';


class AsteroidFilterSheet extends StatefulWidget {
  final AsteroidFilters initial;
  final bool supportsCloseApproach; // false for MPCORB-only views
  final bool supportsDateWindow;
  final bool supportsHazardFlag;

  const AsteroidFilterSheet({
    super.key,
    required this.initial,
     this.supportsCloseApproach = false,
     this.supportsDateWindow = false,
     this.supportsHazardFlag = false,

  });

  @override
  State<AsteroidFilterSheet> createState() => _AsteroidFilterSheetState();
}

class _AsteroidFilterSheetState extends State<AsteroidFilterSheet> {
  late AsteroidFilters f;
  final TextEditingController _queryCtl = TextEditingController();
  final TextEditingController _missCtl = TextEditingController();
  final TextEditingController _moidCtl = TextEditingController();
  final TextEditingController _minArcCtl = TextEditingController();
  final TextEditingController _maxUctl = TextEditingController();

  // Range state for a few sliders we expose
  RangeValues _relVel = const RangeValues(0, 50);
  RangeValues _diamKm = const RangeValues(0, 3000);
  RangeValues _h = const RangeValues(10, 30);
  RangeValues _e = const RangeValues(0, 1);
  RangeValues _a = const RangeValues(0, 6);
  RangeValues _i = const RangeValues(0, 180);

  static const _orbitClassOptions = <String>[
    'Apollo', 'Aten', 'Amor', 'Atira', 'MCA', 'MBA', 'Hilda', 'JFC'
  ];
  static const _targetBodies = <String>['Earth','Moon','Mars','Venus'];

  @override
  void initState() {
    super.initState();
    f = widget.initial;
    _queryCtl.text = f.query;
    if (f.maxMoidAu != null) _moidCtl.text = f.maxMoidAu!.toStringAsFixed(3);
    if (f.minArcDays != null) _minArcCtl.text = '${f.minArcDays}';
    if (f.maxUncertaintyU != null) _maxUctl.text = '${f.maxUncertaintyU}';
    // Prime ranges from existing values if set
    if (f.relVelKms?.isSet == true) {
      _relVel = RangeValues(
        (f.relVelKms!.min ?? 0).clamp(0, FilterBounds.relVelMax),
        (f.relVelKms!.max ?? FilterBounds.relVelMax)
            .clamp(0, FilterBounds.relVelMax),
      );
    }
    if (f.diameterKm?.isSet == true) {
      _diamKm= RangeValues(
        (f.diameterKm!.min ?? 0).clamp(0, FilterBounds.diamMaxKm),
        (f.diameterKm!.max ?? FilterBounds.diamMaxKm).clamp(0, FilterBounds.diamMaxKm),
      );
    }
    if (f.hMag?.isSet == true) {
      _h = RangeValues(
        (f.hMag!.min ?? FilterBounds.hMin).clamp(FilterBounds.hMin, FilterBounds.hMax),
        (f.hMag!.max ?? FilterBounds.hMax).clamp(FilterBounds.hMin, FilterBounds.hMax),
      );
    }
    if (f.e?.isSet == true) {
      _e = RangeValues(
          (f.e!.min ?? 0).clamp(0, 1), (f.e!.max ?? 1).clamp(0, 1));
    }
    if (f.aAu?.isSet == true) {
      _a = RangeValues(
        (f.aAu!.min ?? 0).clamp(0, FilterBounds.aMax),
        (f.aAu!.max ?? FilterBounds.aMax).clamp(0, FilterBounds.aMax),
      );
    }
    if (f.iDeg?.isSet == true) {
      _i = RangeValues(
        (f.iDeg!.min ?? 0).clamp(0, FilterBounds.iMax),
        (f.iDeg!.max ?? FilterBounds.iMax).clamp(0, FilterBounds.iMax),
      );
    }
  }

  @override
  void dispose() {
    _queryCtl.dispose();
    _missCtl.dispose();
    _moidCtl.dispose();
    _minArcCtl.dispose();
    _maxUctl.dispose();
    super.dispose();
  }

  void _applyAndClose() {
    Navigator.of(context).pop<AsteroidFilters>(f.copyWith(
      query: _queryCtl.text.trim(),                    // non-nullable
      maxMoidAu: _parseDouble(_moidCtl.text),
      minArcDays: _parseInt(_minArcCtl.text),
      maxUncertaintyU: _boundInt(_parseInt(_maxUctl.text), 0, 9),

      // orbital/size
      diameterKm: DoubleRange(min: _diamKm.start, max: _diamKm.end),
      hMag: DoubleRange(min: _h.start, max: _h.end),
      e: DoubleRange(min: _e.start, max: _e.end),
      aAu: DoubleRange(min: _a.start, max: _a.end),
      iDeg: DoubleRange(min: _i.start, max: _i.end),

      // close-approach only if supported
      relVelKms: widget.supportsCloseApproach
          ? DoubleRange(min: _relVel.start, max: _relVel.end)
          : null,
      missDistanceKm: widget.supportsCloseApproach
          ? DoubleRange(min: null, max: _parseDouble(_missCtl.text))
          : null,

      // date window only if supported
      window: widget.supportsDateWindow ? f.window : null,
    ));
  }


  static double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  static int? _boundInt(int? v, int min, int max) {
    if (v == null) return null;
    return v.clamp(min, max);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = f.window?.start ?? now;
    final initialEnd = f.window?.end ?? now.add(const Duration(days: 7));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 50),
      lastDate: DateTime(now.year + 50),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked != null) {
      setState(() => f = f.copyWith(window: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final caEnabled = widget.supportsCloseApproach;
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Filters'),
              actions: [
                TextButton(
                  onPressed: () => setState(() => f = const AsteroidFilters()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            body: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // SEARCH
                TextField(
                  controller: _queryCtl,
                  decoration: const InputDecoration(
                    labelText: 'Name / designation contains',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),

                if (widget.supportsDateWindow)
                  ListTile(
                    title: const Text('Close-approach window'),
                    subtitle: Text(
                      f.window == null
                          ? 'Optional'
                          : '${f.window!.start.toIso8601String().split("T").first}  →  ${f.window!.end.toIso8601String().split("T").first}',
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Pick'),
                    ),
                  )
                else
                  const ListTile(
                    title: Text('Close-approach window'),
                    subtitle: Text('Not available for this source'),
                    enabled: false,
                  ),

                const Divider(height: 24),

                // CA FILTERS
                _sectionTitle('Close-Approach', enabled: caEnabled),
                Opacity(
                  opacity: caEnabled ? 1.0 : 0.4,
                  child: IgnorePointer(
                    ignoring: !caEnabled,
                    child: Column(
                      children: [
                        TextField(
                          controller: _missCtl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max miss distance (km)',
                            helperText: 'Tip: 384,400 km ≈ 1 LD',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _range(
                          title: 'Relative velocity (km/s)',
                          values: _relVel,
                          max: FilterBounds.relVelMax,
                          divisions: 50,
                          onChanged: (v) => setState(() => _relVel = v),
                          labelBuilder: (v) => v.toStringAsFixed(1),
                        ),
                        // target body dropdown stays here if you use it
                        const SizedBox(height: 12),
                        _range(
                          title: 'Relative velocity (km/s)',
                          values: _relVel,
                          max: FilterBounds.relVelMax,
                          divisions: 50,
                          onChanged: (v) => setState(() => _relVel = v),
                          labelBuilder: (v) => v.toStringAsFixed(1),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: -6,
                          children: [
                            const Text('Target body:'),
                            DropdownButton<String>(
                              value: f.targetBody,
                              hint: const Text('Any'),
                              items: _targetBodies.map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => f = f.copyWith(targetBody: v)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),

                // SIZE / BRIGHTNESS
                _sectionTitle('Size / Brightness'),
                _range(
                  title: 'Estimated diameter (Km)',
                  values: _diamKm,
                  max: FilterBounds.diamMaxKm,
                  divisions: 60,
                  onChanged: (v) => setState(() => _diamKm = v),
                  labelBuilder: (v) => v.round().toString(),
                ),
                const SizedBox(height: 8),
                _range(
                  title: 'Absolute magnitude H',
                  values: _h,
                  min: FilterBounds.hMin,
                  max: FilterBounds.hMax,
                  divisions: 40,
                  onChanged: (v) => setState(() => _h = v),
                  labelBuilder: (v) => v.toStringAsFixed(1),
                ),
                if (widget.supportsHazardFlag)
                  SwitchListTile(
                    value: f.phaOnly,
                    onChanged: (b) => setState(() => f = f.copyWith(phaOnly: b)),
                    title: const Text('Only potentially hazardous (PHA)'),
                  ),

                const Divider(height: 24),

                // ORBIT CLASS
                _sectionTitle('Orbit class'),
                Wrap(
                  spacing: 8,
                  children: _orbitClassOptions.map((c) {
                    final selected = f.orbitClasses.contains(c);
                    return FilterChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (sel) {
                        final next = Set<String>.from(f.orbitClasses);
                        sel ? next.add(c) : next.remove(c);
                        setState(() => f = f.copyWith(orbitClasses: next));
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 24),

                // ORBITAL ELEMENTS
                _sectionTitle('Orbital elements'),
                _range(
                  title: 'Eccentricity (e)',
                  values: _e,
                  max: FilterBounds.eMax,
                  divisions: 100,
                  onChanged: (v) => setState(() => _e = v),
                  labelBuilder: (v) => v.toStringAsFixed(2),
                ),
                _range(
                  title: 'Semi-major axis a (au)',
                  values: _a,
                  max: FilterBounds.aMax,
                  divisions: 60,
                  onChanged: (v) => setState(() => _a = v),
                  labelBuilder: (v) => v.toStringAsFixed(2),
                ),
                _range(
                  title: 'Inclination i (°)',
                  values: _i,
                  max: FilterBounds.iMax,
                  divisions: 90,
                  onChanged: (v) => setState(() => _i = v),
                  labelBuilder: (v) => v.toStringAsFixed(1),
                ),
                TextField(
                  controller: _moidCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max MOID (au)',
                  ),
                ),
                const Divider(height: 24),

                // QUALITY
                _sectionTitle('Quality'),
                TextField(
                  controller: _maxUctl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max orbit uncertainty U (0–9)',
                  ),
                ),
                TextField(
                  controller: _minArcCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min observation arc (days)',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _applyAndClose,
                  icon: const Icon(Icons.check),
                  label: const Text('Apply filters'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text, {bool enabled = true}) {
    return Row(
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: enabled ? null : Theme.of(context).disabledColor,
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(width: 8),
        if (!enabled)
          const Tooltip(
           message: 'Not available for current data source',
            child: Icon(Icons.info_outline, size: 16),
          ),
      ],
    );
  }

  Widget _range({
    required String title,
    required RangeValues values,
    double min = 0,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
    required String Function(double) labelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title  (${labelBuilder(values.start)} – ${labelBuilder(values.end)})'),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          labels: RangeLabels(
            labelBuilder(values.start),
            labelBuilder(values.end),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
