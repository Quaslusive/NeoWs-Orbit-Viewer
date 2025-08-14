// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:neows_app/settings/settings_controller.dart';
import 'package:neows_app/settings/settings_model.dart';

class SettingsPage extends StatelessWidget {
  final SettingsController controller;
  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(title: const Text('Theme')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<AppTheme>(
              value: s.theme,
              items: AppTheme.values.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (v) => controller.update(s.copyWith(theme: v)),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Hazardous only'),
            value: s.hazardousOnly,
            onChanged: (v) => controller.update(s.copyWith(hazardousOnly: v)),
          ),
          SwitchListTile(
            title: const Text('Show ecliptic grid'),
            value: s.showEclipticGrid,
            onChanged: (v) => controller.update(s.copyWith(showEclipticGrid: v)),
          ),
          ListTile(
            title: const Text('Distance unit'),
            trailing: DropdownButton<DistanceUnit>(
              value: s.unit,
              onChanged: (v) => controller.update(s.copyWith(unit: v)),
              items: DistanceUnit.values.map((u) =>
                  DropdownMenuItem(value: u, child: Text(u.name))).toList(),
            ),
          ),
          ListTile(
            title: const Text('Default days for /feed'),
            subtitle: Text('${s.defaultDays} day(s)'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: s.defaultDays.toDouble(),
                min: 1, max: 7, divisions: 6,
                label: '${s.defaultDays}',
                onChanged: (v) => controller.update(s.copyWith(defaultDays: v.round())),
              ),
            ),
          ),
          ListTile(
            title: const Text('Orbit line width'),
            subtitle: Text(s.orbitLineWidth.toStringAsFixed(1)),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: s.orbitLineWidth,
                min: 1.0, max: 4.0,
                divisions: 6,
                onChanged: (v) => controller.update(s.copyWith(orbitLineWidth: v)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
